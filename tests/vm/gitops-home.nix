{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs = if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  # ft.gitops (Home Manager): the daemon clones the configured remote and
  # reaches its poll loop under the user's systemd instance.
  #
  # Actual deployment is out of scope, mirroring the NixOS-side comin test: a
  # real `home-manager switch` would need the framework + nixpkgs sources
  # evaluable offline inside the sandbox. The seeded remote is an empty bare
  # repo (no commit on remote.branch), so the daemon clones it and polls but
  # never attempts a switch — this asserts the user unit runs and completes a
  # real git clone against the remote.
  vm-gitops-home-load = mkTest {
    name = "ft-gitops-home-load";
    nodes.machine =
      { pkgs, ... }:
      {
        imports = [
          baseConfig
          mergedInputs.home-manager.nixosModules.home-manager
        ];

        # git is needed by the test script to create the local remote.
        environment.systemPackages = [ pkgs.git ];

        home-manager = {
          extraSpecialArgs = { inputs = mergedInputs; };
          users.admin = {
            imports = [ fw.homeManagerModules.default ];
            ft.core = {
              enable = true;
              stateVersion = "25.05";
            };
            ft.gitops = {
              enable = true;
              pollPeriod = 5;
              remote.url = "file:///srv/gitops-remote-home";
              repoPath = "/home/admin/ft-gitops-repo";
              flakeAttr = "admin@x86_64-linux";
              # No signingKeys: load test only (module warns about the empty
              # list, which does not fail evaluation).
            };
            home = {
              username = "admin";
              homeDirectory = "/home/admin";
            };
          };
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-admin.service")

      # Provide the local remote the daemon is configured to poll. An empty
      # bare repo has no commit on the branch, so the daemon clones it but
      # never attempts a switch.
      machine.succeed("git init --bare /srv/gitops-remote-home")
      machine.succeed("chmod -R a+rwX /srv/gitops-remote-home")

      # Home Manager's user services only run once the user's systemd
      # instance is up; enable-linger brings it up without a real login.
      machine.succeed("loginctl enable-linger admin")
      uid = machine.succeed("id -u admin").strip()
      machine.wait_for_unit(f"user@{uid}.service")
      machine.wait_until_succeeds(
          f"su admin -c 'XDG_RUNTIME_DIR=/run/user/{uid} systemctl --user is-active ft-gitops.service'",
          timeout=60,
      )

      # The daemon completed a real git clone of the configured remote.
      machine.wait_until_succeeds("test -d /home/admin/ft-gitops-repo/.git", timeout=60)
    '';
  };
}

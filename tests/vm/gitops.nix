{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.gitops: the comin daemon reaches active and polls the configured remote.
  #
  # Actual deployment is out of scope: a real deploy would have comin rebuild
  # this machine's nixosConfiguration *inside* the VM, which needs the framework
  # + nixpkgs sources evaluable offline in the sandbox (the same wall the
  # bootstrap deploy-local test hit). So comin is pointed at a local *empty* bare
  # repo — the poll succeeds but there is no commit on deployBranch, so comin
  # never triggers a rebuild. This asserts the wrapper wires services.comin and
  # the daemon runs with our config.
  vm-gitops-load = mkTest {
    name = "ft-gitops-load";
    nodes.machine =
      { pkgs, ... }:
      {
        imports = [ baseConfig ];

        # git is needed by the test script to create the local remote.
        environment.systemPackages = [ pkgs.git ];

        ft.gitops = {
          enable = true;
          pollPeriod = 5;
          remotes = [
            {
              name = "test-remote";
              url = "file:///srv/gitops-remote";
            }
          ];
          # No signingKeys / tokenSecret: load test only (module warns about the
          # empty signingKeys, which does not fail evaluation).
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")

      # comin is installed by the module.
      machine.succeed("command -v comin")

      # Provide the local remote comin is configured to poll. An empty bare repo
      # has no deployBranch commit, so comin polls but never rebuilds the system.
      machine.succeed("git init --bare /srv/gitops-remote")

      # The daemon starts with our generated config and stays active.
      machine.systemctl("restart comin.service")
      machine.wait_for_unit("comin.service")

      # comin picked up our remote and is actively polling it.
      machine.wait_until_succeeds(
          "journalctl -u comin.service | grep -Eq 'test-remote|gitops-remote'",
          timeout=60,
      )
    '';
  };
}

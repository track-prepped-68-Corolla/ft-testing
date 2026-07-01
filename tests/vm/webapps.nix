{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs = if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  # ft.webapps (Home Manager): generates a desktop-launcher entry plus an
  # isolated profile dir for each configured site. The favicon fetch (curl to
  # a public favicon service) needs real internet access the sandboxed VM
  # doesn't have, so this only asserts the static config-level effects: the
  # desktop entry references the built chromium derivation with the expected
  # --app=/--user-data-dir exec line, and the icon directory was created by
  # the activation script regardless of whether the fetch itself succeeded.
  vm-webapps-load = mkTest {
    name = "ft-webapps-load";
    nodes.machine =
      { ... }:
      {
        imports = [
          baseConfig
          mergedInputs.home-manager.nixosModules.home-manager
        ];
        home-manager = {
          extraSpecialArgs = { inputs = mergedInputs; };
          users.admin = {
            imports = [ fw.homeManagerModules.default ];
            ft.core = {
              enable = true;
              stateVersion = "25.05";
            };
            ft.webapps = {
              enable = true;
              apps.example = {
                name = "Example";
                url = "https://example.com/";
              };
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
      # Diagnose the HM generation to check whether example.desktop is in the
      # managed-files set (store issue) or just not linked (link-generation issue).
      for cmd in [
          "find /home/admin -maxdepth 5 \\( -type f -o -type l \\) 2>&1 | sort",
          "readlink /home/admin/.local/state/home-manager/gcroots/current-home 2>&1",
          "find $(readlink /home/admin/.local/state/home-manager/gcroots/current-home 2>/dev/null || echo /nonexistent)/home-files -name '*.desktop' 2>&1",
          "systemctl status home-manager-admin.service --no-pager -l 2>&1",
      ]:
          rc, out = machine.execute(cmd)
          print(f"[diag] $ {cmd}  (rc={rc})")
          print(out)
      desktop_file = "/home/admin/.local/share/applications/example.desktop"
      machine.succeed(f"test -f {desktop_file}")
      machine.succeed(f"grep -Eq '^Exec=.*/bin/chromium ' {desktop_file}")
      machine.succeed(f"grep -q -- \"--app='https://example.com/'\" {desktop_file}")
      machine.succeed(
          f"grep -q -- \"--user-data-dir='/home/admin/.local/share/ft-webapps/example'\" {desktop_file}"
      )
      machine.succeed("test -d /home/admin/.local/share/ft-webapps/icons")
    '';
  };
}

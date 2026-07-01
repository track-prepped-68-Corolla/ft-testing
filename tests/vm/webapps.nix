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
      desktop_file = "/home/admin/.local/share/applications/example.desktop"
      machine.succeed(f"test -f {desktop_file}")
      machine.succeed(f"grep -Eq '^Exec=.*/bin/chromium ' {desktop_file}")
      machine.succeed(f"grep -q -- '--app=https://example.com/' {desktop_file}")
      machine.succeed(
          f"grep -q -- '--user-data-dir=/home/admin/.local/share/ft-webapps/example' {desktop_file}"
      )
      machine.succeed("test -d /home/admin/.local/share/ft-webapps/icons")
    '';
  };
}

{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs = if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  # ft.cad3d (Home Manager): OrcaSlicer and the rest of the 3D printing/CAD
  # toolset land in the user's profile.
  vm-cad3d-load = mkTest {
    name = "ft-cad3d-load";
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
            ft.cad3d.enable = true;
            home = {
              username = "admin";
              homeDirectory = "/home/admin";
            };
          };
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      print(machine.succeed("find /home/admin -maxdepth 5 2>&1; find /nix/var/nix/profiles/per-user/admin 2>&1 || true"))
      machine.succeed("test -x /home/admin/.nix-profile/bin/orca-slicer")
      machine.succeed("test -x /home/admin/.nix-profile/bin/blender")
      machine.succeed("test -x /home/admin/.nix-profile/bin/freecad")
      machine.succeed("test -x /home/admin/.nix-profile/bin/openscad")
      machine.succeed("test -x /home/admin/.nix-profile/bin/inkscape")
      machine.succeed("test -x /home/admin/.nix-profile/bin/meshlab")
      machine.succeed("test -x /home/admin/.nix-profile/bin/f3d")
    '';
  };
}

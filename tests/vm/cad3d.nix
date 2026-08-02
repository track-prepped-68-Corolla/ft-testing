{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.cad3d: OrcaSlicer and the rest of the 3D printing/CAD toolset are on PATH.
  vm-cad3d-load = mkTest {
    name = "ft-cad3d-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.cad3d.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which orca-slicer")
      machine.succeed("which blender")
      machine.succeed("which freecad")
      machine.succeed("which openscad")
      machine.succeed("which inkscape")
      machine.succeed("which meshlab")
      machine.succeed("which admesh")
      machine.succeed("which f3d")
    '';
  };
}

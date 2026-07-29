{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.niri: niri is on PATH and registers itself as a selectable Wayland
  # session (the .desktop file a display manager reads from sessionPackages).
  # defaultSession isn't exercised here: it only has an observable effect once
  # a real display manager (e.g. ft.cosmicGreeter, out of scope for this VM)
  # consumes services.displayManager.defaultSession when generating its own
  # config, so there's no DM-agnostic runtime effect to assert on here.
  vm-niri-session = mkTest {
    name = "ft-niri-session";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.niri.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which niri")
      machine.succeed("test -f /run/current-system/sw/share/wayland-sessions/niri.desktop")
    '';
  };
}

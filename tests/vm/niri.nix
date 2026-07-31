{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.niri: niri is on PATH. Session-registration (services.displayManager.
  # sessionPackages) is deliberately not asserted here: per nixpkgs'
  # nixos/modules/services/display-managers/default.nix, that data is only
  # materialized into services.displayManager.sessionData.desktops (exposed
  # via XDG_DATA_DIRS, not symlinked into /run/current-system/sw) once
  # services.displayManager.enable is true — which only an actual display
  # manager module (e.g. ft.cosmicGreeter) sets, and pairing one in here is
  # out of scope for a niri-only smoke test. Same reasoning covers
  # defaultSession: it only has an observable effect once a real display
  # manager consumes it when generating its own config.
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
    '';
  };
}

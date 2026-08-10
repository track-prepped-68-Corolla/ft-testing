{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs = if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
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

  # ft.niri (Home Manager): generates ~/.config/niri/config.kdl. Sets
  # launcherCommand explicitly rather than via ft.vicinae.enable's default so
  # this stays a lightweight config-generation smoke test — actually enabling
  # ft.vicinae would pull in its Qt6/C++ package build, the same binary-cache
  # dependency that exempts ft.vicinae/ft.noctalia themselves from this suite.
  # The "launcherCommand defaults to vicinae toggle when ft.vicinae.enable is
  # on" wiring is covered separately as an eval-only check in fast-track-nix's
  # flake-parts/checks.nix (niriLauncherDefault), which needs no VM/build.
  vm-niri-config = mkTest {
    name = "ft-niri-config";
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
            ft.niri = {
              enable = true;
              launcherCommand = [
                "vicinae"
                "toggle"
              ];
              extraConfig = ''
                environment {
                    QT_QPA_PLATFORM "wayland"
                }
              '';
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
      config_file = "/home/admin/.config/niri/config.kdl"
      machine.succeed(f"test -f {config_file}")
      machine.succeed(f"grep -q 'Mod+Space' {config_file}")
      machine.succeed(f'grep -q \'spawn "vicinae" "toggle";\' {config_file}')
      machine.succeed(f'grep -q \'QT_QPA_PLATFORM "wayland"\' {config_file}')
    '';
  };
}

{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs =
    if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  # ft.flatpak: system service + Discover frontend (NixOS) + per-user HM config.
  # nix-flatpak's flatpak-managed-install.service fetches remotes from Flathub
  # at boot, which requires network unavailable in the sandboxed VM build.
  # Assertions are limited to static config-level effects: flatpak binary
  # present, frontend on PATH, and the managed-install service unit is
  # configured (proving remotes are declared even though they cannot be applied).
  vm-flatpak-load = mkTest {
    name = "ft-flatpak-load";
    nodes.machine =
      { ... }:
      {
        imports = [
          baseConfig
          mergedInputs.home-manager.nixosModules.home-manager
        ];
        ft.flatpak = {
          enable = true;
          frontend.enable = true;
        };
        home-manager = {
          extraSpecialArgs = { inputs = mergedInputs; };
          users.admin = {
            imports = [ fw.homeManagerModules.default ];
            ft.core = {
              enable = true;
              stateVersion = "25.05";
            };
            ft.flatpak.enable = true;
            home = {
              username = "admin";
              homeDirectory = "/home/admin";
            };
          };
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which flatpak")
      machine.succeed("which plasma-discover")
      machine.succeed("systemctl cat flatpak-managed-install.service")
    '';
  };
}

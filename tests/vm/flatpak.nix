{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs =
    if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  # ft.flatpak: system service + Flathub remote + Discover frontend (NixOS),
  # plus the per-user Flathub remote (Home Manager). Actual `flatpak install`
  # runs need network access to Flathub, which the sandboxed VM build doesn't
  # have, so this only asserts the static config-level effects: the service is
  # active, the remote is registered (system and user scope), and the
  # frontend binary is on PATH.
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
      machine.succeed("flatpak remote-list | grep -q flathub")
      machine.succeed("which plasma-discover")
      machine.succeed("grep -q flathub /home/admin/.local/share/flatpak/repo/config")
    '';
  };
}

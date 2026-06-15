{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
  fw = inputs.ft-framework;
  mergedInputs =
    if fw.lib ? mergeInputs then fw.lib.mergeInputs inputs else fw.inputs // inputs;
in
{
  vm-git-workflow-load = mkTest {
    name = "ft-git-workflow-load";
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
            ft.gitWorkflow.enable = true;
            home = {
              username = "admin";
              homeDirectory = "/home/admin";
            };
          };
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("test -x /home/admin/.config/git/hooks/pre-commit")
      machine.succeed("test -x /home/admin/.config/git/hooks/commit-msg")
      machine.succeed("test -x /home/admin/.config/git/hooks/prepare-commit-msg")
      machine.succeed("test -e /home/admin/.nix-profile/bin/conform")
      machine.succeed("test -e /home/admin/.nix-profile/bin/convco")
      machine.succeed("test -e /home/admin/.nix-profile/bin/lefthook")
    '';
  };
}

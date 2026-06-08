{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.rclone (framework): rclone is on PATH and FUSE user_allow_other is set.
  vm-rclone-load = mkTest {
    name = "ft-rclone-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.rclone.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which rclone")
      machine.succeed("grep -Eq '^[[:space:]]*user_allow_other([[:space:]]|$)' /etc/fuse.conf")
    '';
  };
}

{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.hardware.facter (framework): hardware report is loaded and system boots.
  #
  # ft.hardware.facter now imports nixos-facter-modules.nixosModules.facter
  # itself (via the framework module hub pulled in by baseConfig), so the test
  # no longer needs to import the upstream module explicitly.
  vm-facter-load = mkTest {
    name = "ft-facter-load";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.hardware.facter = {
          enable = true;
          reportPath = ./fixtures/facter.json;
        };
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      # hardware.enableRedistributableFirmware = true is set by ft.hardware.facter;
      # verify its effect: linux-firmware is linked into the system profile.
      machine.succeed("test -d /run/current-system/firmware")
    '';
  };
}

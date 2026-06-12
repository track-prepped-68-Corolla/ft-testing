{ inputs, nixpkgs }:
let
  inherit (import ./lib.nix { inherit inputs nixpkgs; }) baseConfig mkTest;
in
{
  # ft.vendorHw (ASUS): smbios.system.manufacturer is read correctly and
  # asusctl is installed when an ASUS machine is detected.
  #
  # This test exercises the SMBIOS detection path introduced when the old
  # facter.dmi / facter.hardware.dmi paths were replaced with facter.smbios.
  vm-vendor-hw-asus = mkTest {
    name = "ft-vendor-hw-asus";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-asus.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      # ASUS detected from smbios.system.manufacturer — asusctl must be on PATH.
      machine.succeed("which asusctl")
    '';
  };
}

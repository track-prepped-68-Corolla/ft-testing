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

  # ft.vendorHw (Lenovo Legion): smbios.system.manufacturer == "lenovo" plus a
  # "legion" substring in product/version triggers the Lenovo Legion branch —
  # boot.extraModulePackages + the lenovo-legion userspace package.
  vm-vendor-hw-lenovo = mkTest {
    name = "ft-vendor-hw-lenovo";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-lenovo.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("ls /run/current-system/sw/bin | grep -qi legion")
    '';
  };

  # ft.vendorHw (MSI): smbios.system.manufacturer containing "micro-star"
  # triggers the msi-ec kernel module + MControlCenter GUI.
  vm-vendor-hw-msi = mkTest {
    name = "ft-vendor-hw-msi";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-msi.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("ls /run/current-system/sw/bin | grep -qi mcontrolcenter")
    '';
  };

  # ft.vendorHw (Razer): USB vendor ID 1532 triggers OpenRazer + Polychromatic.
  vm-vendor-hw-razer = mkTest {
    name = "ft-vendor-hw-razer";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-razer.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("ls /run/current-system/sw/bin | grep -qi polychromatic")
    '';
  };

  # ft.vendorHw (Logitech): USB vendor ID 046d triggers Solaar + Piper/ratbagd.
  vm-vendor-hw-logitech = mkTest {
    name = "ft-vendor-hw-logitech";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-logitech.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which solaar")
      machine.succeed("which piper")
      machine.succeed("systemctl is-active ratbagd.service || systemctl cat ratbagd.service")
    '';
  };

  # ft.vendorHw (Corsair): USB vendor ID 1b1c triggers ckb-next.
  vm-vendor-hw-corsair = mkTest {
    name = "ft-vendor-hw-corsair";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-corsair.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which ckb-next")
    '';
  };

  # ft.vendorHw (OpenRGB): no autodetect exists for OpenRGB — it's universal,
  # brand-agnostic hardware, so it's only ever enabled via the explicit
  # override. Exercises that override path plus the i2c-dev kernel module.
  vm-vendor-hw-openrgb = mkTest {
    name = "ft-vendor-hw-openrgb";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.vendorHw.enable = true;
        ft.vendorHw.openrgb = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("which openrgb")
      machine.succeed("lsmod | grep -q i2c_dev")
    '';
  };

  # ft.vendorHw (handheld): SMBIOS chassis type 11 ("Hand Held" per DMTF spec)
  # triggers InputPlumber + PowerStation, independent of any vendor string —
  # this exercises the chassis-type branch of detectHandheld, not the named
  # product-string fallback (Legion Go / GPD / Ayaneo / AYN).
  vm-vendor-hw-handheld = mkTest {
    name = "ft-vendor-hw-handheld";
    nodes.machine =
      { ... }:
      {
        imports = [ baseConfig ];
        ft.facter.reportPath = ./fixtures/vendor-hw-handheld.json;
        ft.vendorHw.enable = true;
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("systemctl cat inputplumber.service")
      machine.succeed("systemctl cat powerstation.service")
    '';
  };
}

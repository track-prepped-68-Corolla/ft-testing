# =============================================================================
# vendorHw-corsair-usb — eval-only ft.vendorHw detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/vendorHw/corsair-usb.json and expects ft.vendorHw autodetection to
# enable ckb-next (USB vendor ID 1b1c).
# Assertions live in scripts/check-vendorHw.sh — this machine is never built
# or booted, only evaluated.
# =============================================================================
{ ... }:

{
  # Minimal eval-able system: tmpfs root + systemd-boot.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  ft.core.stateVersion = "25.05";

  ft.facter.reportPath = ../../fixtures/vendorHw/corsair-usb.json;
  ft.vendorHw.enable = true;

  # ft.cli now defaults to true (ergonomics on real consumer machines);
  # this eval-only fixture doesn't need it and has no real ft.repoPath.
  ft.cli.enable = false;
}

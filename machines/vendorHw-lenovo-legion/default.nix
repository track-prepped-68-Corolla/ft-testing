# =============================================================================
# vendorHw-lenovo-legion — eval-only ft.vendorHw detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/vendorHw/lenovo-legion.json and expects ft.vendorHw autodetection to
# enable the Lenovo Legion kernel module and tooling (DMI manufacturer + family).
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

  ft.facter.reportPath = ../../fixtures/vendorHw/lenovo-legion.json;
  ft.vendorHw.enable = true;

  # ft.cli now defaults to true (ergonomics on real consumer machines);
  # this eval-only fixture doesn't need it and has no real ft.repoPath.
  ft.cli.enable = false;
}

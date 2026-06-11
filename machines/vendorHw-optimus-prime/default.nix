# =============================================================================
# vendorHw-optimus-prime — eval-only ft.gpu Optimus/PRIME detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/vendorHw/optimus-prime.json (NVIDIA dGPU + Intel iGPU) and expects
# ft.gpu autodetection to configure PRIME offloading with bus IDs derived from
# the fixture's sysfs_bus_id values, and to enable ft.cardwire as a result.
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

  ft.facter.reportPath = ../../fixtures/vendorHw/optimus-prime.json;
  ft.gpu.enable = true;
}

# =============================================================================
# gpu-optimus-intel — eval-only ft.gpu Optimus/PRIME detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/gpu/optimus-intel.json (NVIDIA dGPU + Intel iGPU — the most common
# Optimus pairing) and expects ft.gpu autodetection to configure PRIME
# offloading via intelBusId with bus IDs derived from the fixture's
# sysfs_bus_id values, and to enable ft.cardwire as a result.
# Assertions live in scripts/check-gpu.sh — this machine is never built or
# booted, only evaluated.
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

  ft.facter.reportPath = ../../fixtures/gpu/optimus-intel.json;
  ft.gpu.enable = true;

  # ft.cli now defaults to true (ergonomics on real consumer machines);
  # this eval-only fixture doesn't need it and has no real ft.repoPath.
  ft.cli.enable = false;
}

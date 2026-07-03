# =============================================================================
# gpu-optimus-amd — eval-only ft.gpu detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/gpu/optimus-amd.json and expects ft.gpu autodetection to
# configure PRIME offloading with an AMD iGPU (amdgpuBusId, not intelBusId) and enable ft.cardwire.
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

  ft.facter.reportPath = ../../fixtures/gpu/optimus-amd.json;
  ft.gpu.enable = true;

  # ft.cli now defaults to true (ergonomics on real consumer machines);
  # this eval-only fixture doesn't need it and has no real ft.repoPath.
  ft.cli.enable = false;
}

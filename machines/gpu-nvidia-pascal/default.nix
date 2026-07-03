# =============================================================================
# gpu-nvidia-pascal — eval-only ft.gpu detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/gpu/nvidia-pascal.json and expects ft.gpu autodetection to
# honour ft.gpu.nvidia.openKernelModules = false for a pre-Turing device ID.
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

  ft.facter.reportPath = ../../fixtures/gpu/nvidia-pascal.json;
  ft.gpu.enable = true;
  ft.gpu.nvidia.openKernelModules = false;

  # ft.cli now defaults to true (ergonomics on real consumer machines);
  # this eval-only fixture doesn't need it and has no real ft.repoPath.
  ft.cli.enable = false;
}

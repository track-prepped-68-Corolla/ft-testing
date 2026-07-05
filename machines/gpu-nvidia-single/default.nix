# =============================================================================
# gpu-nvidia-single — eval-only ft.gpu detection test machine
# =============================================================================
#
# Points ft.facter.reportPath at the hand-crafted hardware report
# fixtures/gpu/nvidia-single.json and expects ft.gpu autodetection to
# select the NVIDIA driver with no PRIME/cardwire, and force open kernel modules on (Turing+ device ID) despite the explicit false below.
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

  # Eval-only test fixture: no real consumer repo checkout on this host.
  ft.cli.enable = false;

  ft.facter.reportPath = ../../fixtures/gpu/nvidia-single.json;
  ft.gpu.enable = true;
  ft.gpu.nvidia.openKernelModules = false;
}

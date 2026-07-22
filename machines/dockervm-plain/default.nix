# =============================================================================
# dockervm-plain — eval-only ft.dockervm regression guard (secrets OFF)
# =============================================================================
#
# Reproduces the exact configuration that regressed in fast-track-nix #199:
# ft.dockervm.enable = true with Komodo secrets OFF. Evaluating this host to
# its toplevel forces the microVM *guest* config to evaluate, so
# `nix flake check` (CI evaluates every nixosConfigurations.* toplevel) catches
# a recurrence of the guest sops-option error — which no CI machine covered
# before. Never built or booted, only evaluated.
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

  # Eval-only fixture: no real consumer repo checkout on this host.
  ft.cli.enable = false;

  # The unit under guard: the microVM appliance with Komodo on its plaintext
  # defaults (peripherySecrets / coreSecrets / autoApply all off).
  ft.dockervm.enable = true;
  ft.dockervm.hostInterface = "eth0";
}

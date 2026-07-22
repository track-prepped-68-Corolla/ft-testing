# =============================================================================
# dockervm-full — eval-only ft.dockervm guard with all Komodo options ON
# =============================================================================
#
# Complements dockervm-plain by exercising the *new* wiring at eval time — the
# first CI coverage of it: guest-side sops [secrets] injection (periphery +
# core) and the host-side autoApply oneshot. Evaluating this host toplevel
# forces both the guest sops config and the host auto-apply service/secret to
# evaluate. Never built or booted, only evaluated.
#
# autoApply + the guest secrets need a consumer repo path and host sops, so
# unlike dockervm-plain this fixture sets ft.repoPath, ft.cli and ft.sops. No
# real secrets are decrypted — validateSopsFiles is off in the framework, so
# eval never reads the (absent) sops files.
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

  # autoApply drives `ft komodo-apply` from the host, and the guest secrets
  # share <repoPath>/var/secrets — both need a repo path + host sops.
  ft.cli.enable = true;
  ft.repoPath = "/home/example/ft-testing";
  ft.sops.enable = true;

  ft.dockervm = {
    enable = true;
    hostInterface = "eth0";
    komodo = {
      peripherySecrets.enable = true;
      coreSecrets.enable = true;
      autoApply.enable = true;
    };
  };
}

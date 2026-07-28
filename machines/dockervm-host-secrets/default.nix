# =============================================================================
# dockervm-host-secrets — eval-only guard for the secrets-on microVM path
# =============================================================================
#
# The standalone-model replacement for the old dockervm-full guard. Runs the
# secrets-on guest (vms/docker-vm-secrets) by reference and exercises the
# host-side secrets wiring: ft.microvms.instances.<name>.shareSecrets (the
# read-only bind-mount of the consumer sops tree into the VM) and ft.komodoApply
# (the host-side GitOps auto-apply oneshot + its komodo/api_env sops secret).
# Evaluating this host toplevel forces both to evaluate. Never built or booted.
#
# autoApply + the guest secrets share need a repo path + host sops + cli, so
# unlike dockervm-host this fixture sets ft.repoPath, ft.cli and ft.sops. No real
# secrets are decrypted — validateSopsFiles is off, so eval never reads the
# (absent) sops files.
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

  # shareSecrets + ft.komodoApply drive `ft komodo-apply` and share
  # <repoPath>/var/secrets — both need a repo path + host sops.
  ft.cli.enable = true;
  ft.repoPath = "/home/example/ft-testing";
  ft.sops.enable = true;

  # Attach the secrets-on guest by reference and share the sops tree into it.
  ft.microvms.instances.docker-vm-secrets = {
    enable = true;
    vmAddressSuffix = 2;
    hostInterface = "eth0";
    shareSecrets = true;
  };

  # Host-side Komodo GitOps auto-apply for that instance.
  ft.komodoApply.docker-vm-secrets.enable = true;
}

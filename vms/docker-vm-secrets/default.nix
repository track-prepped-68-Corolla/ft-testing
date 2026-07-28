# =============================================================================
# docker-vm-secrets — standalone microVM guest: Docker + Komodo WITH sops secrets
# =============================================================================
#
# The secrets-on counterpart to vms/docker-vm, and the standalone-model
# replacement for the old dockervm-full eval guard. Adds ft.vmSecrets (sops-nix
# in the guest, keyed on its own persistent host key, with the consumer's sops
# tree shared read-only at /var/secrets) and the Komodo [secrets] tiers that
# consume it. Its host is machines/dockervm-host-secrets, which sets shareSecrets
# + ft.komodoApply.
#
# Eval-only coverage: CI evaluates nixosConfigurations.docker-vm-secrets to
# toplevel, forcing the guest-side sops config to evaluate. No real secrets are
# decrypted — validateSopsFiles is off, so eval never reads the (absent) files.
# The long name also exercises #219's tap-name auto-truncation
# (tap-docker-vm-secrets would exceed Linux's 15-char limit un-truncated).
# =============================================================================
{ ... }:
{
  # The tap interface (name + MAC) is auto-derived from the VM name by the guest
  # baseline (and length-safe via vmLib.tapName) — nothing to declare here.

  microvm.volumes = [
    {
      image = "/var/lib/microvm/docker-vm-secrets/docker.img";
      mountPoint = "/var/lib/docker";
      size = 20480;
    }
  ];

  ft.containers = {
    enable = true;
    runtime = "docker";
    rootless = false;
    compose.enable = true;
  };

  ft.komodo = {
    enable = true;
    backupsPath = "/srv/host-share/backups";
    peripheryRootDirectory = "/srv/host-share/periphery";
    repoCachePath = "/srv/host-share/repo-cache";
    syncPath = "/srv/host-share/syncs";
    includeDiskMounts = [
      "/"
      "/var/lib/docker"
      "/srv/host-share"
    ];
    # Consume the sops-decrypted [secrets] tiers that ft.vmSecrets makes
    # available under /var/secrets/komodo.yaml.
    secrets.periphery.enable = true;
    secrets.core.enable = true;
  };

  # Guest-side sops plumbing: persistent ed25519 host key as the age recipient,
  # sshd to serve it for the recipient bootstrap, and the read-only /var/secrets
  # mount (the host provides its backing dir via shareSecrets).
  ft.vmSecrets.enable = true;
}

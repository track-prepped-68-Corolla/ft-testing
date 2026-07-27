# =============================================================================
# docker-vm — standalone microVM guest: rootful Docker + Komodo (plaintext)
# =============================================================================
#
# The Phase 2 replacement for the retired ft.dockervm appliance module: the
# docker + Komodo GUEST as a standalone nixosConfigurations.docker-vm (built by
# the framework's flake-parts/vms.nix from this directory), run on a host by
# reference via ft.microvms.instances.docker-vm. Komodo runs on its plaintext
# defaults (secrets off) — the reusable shape a consumer copies. CI evaluates
# this to toplevel, giving the same guest-eval coverage the old dockervm-plain
# machine did for the inline model.
#
# Persistent/browsable Komodo state lives on the auto host share the guest
# baseline mounts at /srv/host-share (host /var/lib/microvm/docker-vm/share);
# Docker's own data is on a persistent volume image. The tap MAC here MUST match
# the host's ft.microvms.instances.docker-vm.vmMac.
# =============================================================================
{ ... }:
{
  microvm.interfaces = [
    {
      type = "tap";
      id = "tap-docker-vm";
      mac = "02:00:00:00:00:01";
    }
  ];

  # Docker's data directory on a persistent disk image under the host state dir
  # (microvm.nix creates the image inside /var/lib/microvm/docker-vm, which
  # ft.microvms provisions on the host).
  microvm.volumes = [
    {
      image = "/var/lib/microvm/docker-vm/docker.img";
      mountPoint = "/var/lib/docker";
      size = 20480;
    }
  ];

  # Rootful Docker + the real docker-compose v2 binary; ft.komodo reaches the
  # daemon through ft.containers.socket.
  ft.containers = {
    enable = true;
    runtime = "docker";
    rootless = false;
    compose.enable = true;
  };

  # Komodo Core + Periphery + FerretDB on plaintext defaults. Its persistent data
  # dirs live on the auto host share (ft.komodo creates them as root, matching
  # the share's default root:root ownership) so they survive guest rebuilds and
  # are browsable on the host under /var/lib/microvm/docker-vm/share.
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
  };
}

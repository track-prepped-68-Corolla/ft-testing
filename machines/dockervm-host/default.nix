# =============================================================================
# dockervm-host — eval-only guard for ft.microvms attach-by-reference
# =============================================================================
#
# Replaces the retired dockervm-plain / dockervm-full inline-guest guards. Runs
# the standalone docker-vm guest (vms/docker-vm) by reference. Evaluating this
# host to its toplevel exercises the host-side wiring introduced by the Phase 2
# slim: bridge (microvm0) + DHCP server + NAT + TAP + the
# microvm.vms.docker-vm.flake = self attach, plus the auto host-share
# provisioning. Never built or booted, only evaluated.
#
# (The old dockervm-full also guarded the guest sops [secrets] tiers + host
# auto-apply; those are deferred until the guest-side secrets-share decoupling
# is designed — a standalone guest cannot read the host's repoPath-relative sops
# tree the way the inline guest did.)
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

  # The unit under guard: attach the standalone docker-vm guest by reference.
  # The tap MAC + interface name are derived from the instance name on both
  # sides (ft.microvms + the guest baseline), so nothing is set here.
  ft.microvms.instances.docker-vm = {
    enable = true;
    vmAddressSuffix = 2;
    hostInterface = "eth0";
  };
}

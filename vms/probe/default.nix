# =============================================================================
# probe — Phase 2 microVM generator exercise
# =============================================================================
#
# Discovered by flake-parts/vms.nix (framework) and emitted as
# nixosConfigurations.probe + packages.x86_64-linux.microvm-probe.
#
# Deliberately minimal: it exercises the generator wiring end-to-end — discovery
# → standalone guest built with the microvm guest module + the injected hub +
# the guest baseline + disabledModules — WITHOUT pulling a real appliance
# (ft.containers/ft.komodo image pulls). If nixosConfigurations.probe evaluates
# to toplevel, the generator, the hub-in-guest, and the disabledModules set are
# all sound.
#
# Everything else (Cloud Hypervisor, DHCP-on-bridge, stateVersion) comes from
# the framework's vm-guest-base. A real VM would add ft.* here.
# =============================================================================
{ ... }:
{
  # Per-VM tap interface + MAC. Address is DHCP from the host bridge (baseline).
  microvm.interfaces = [
    {
      type = "tap";
      id = "tap-probe";
      mac = "02:00:00:00:bb:01";
    }
  ];

  # A runtime effect to assert against if this is ever booted.
  services.openssh.enable = true;
}

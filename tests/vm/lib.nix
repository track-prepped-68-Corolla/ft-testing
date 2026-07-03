# =============================================================================
# VM Test Shared Library
# =============================================================================
#
# Provides mkTest and baseConfig for all VM smoke tests.
#
# When the framework exposes lib.mkVmTest / lib.vmTestBase (fast-track-nix >=
# the lib-vm-helpers commit), those are used directly so the wiring stays in
# one place.  Until that commit reaches the `testing` branch the equivalent
# logic is inlined here — semantically identical, no behaviour difference.
#
# baseConfig — NixOS module added to every test node.  Imports the framework
#              module hub and applies the three disabledModules entries that
#              make unconditionally-imported framework modules safe in the NixOS
#              test sandbox (disko-btrfs, gaming, nixos-facter-modules/system).
#              Also sets the baseline every VM needs: stateVersion, admin
#              password, Bluetooth off.
#
# mkTest     — wraps runNixOSTest with the merged input set (framework inputs
#              // consumer inputs) in node.specialArgs so every test node gets
#              the same `inputs` that real machines receive from the generator.
# =============================================================================
{ inputs, ... }:
let
  fw = inputs.ft-framework;

  # Use the framework's canonical merge when available; fall back to the
  # equivalent expression so CI stays green while the framework PR is pending.
  mergedInputs =
    if fw.lib ? mergeInputs
    then fw.lib.mergeInputs inputs
    else fw.inputs // inputs;

  pkgs = mergedInputs.nixpkgs.legacyPackages.x86_64-linux;

  mkTest =
    if fw.lib ? mkVmTest
    then fw.lib.mkVmTest inputs
    else
      spec:
      pkgs.testers.runNixOSTest (
        mergedInputs.nixpkgs.lib.recursiveUpdate spec {
          node.specialArgs.inputs = mergedInputs;
        }
      );

  vmTestBase =
    if fw.lib ? vmTestBase
    then fw.lib.vmTestBase inputs
    else
      { ... }: {
        imports = [ fw.nixosModules.default ];
        disabledModules = [
          "${fw}/modules/nixos/hardware/disko-btrfs.nix"
          "${fw}/modules/nixos/profiles/gaming.nix"
          "${mergedInputs.nixos-facter-modules}/modules/nixos/system.nix"
        ];
      };

  baseConfig =
    { lib, ... }:
    {
      imports = [ vmTestBase ];
      ft.core.stateVersion = "25.05";
      ft.users.initialPasswords.admin = "test";
      hardware.bluetooth.enable = false;
      # ft.cli defaults to true in the framework now, so every VM test node
      # gets it whether the individual test cares or not - give it a non-
      # default repoPath here so the framework's ft.cli assertion passes
      # everywhere by default. lib.mkDefault so individual test files
      # (e.g. cli.nix) can still set their own real value.
      ft.repoPath = lib.mkDefault "/tmp/fake-repo";
    };
in
{
  inherit mkTest baseConfig;
}

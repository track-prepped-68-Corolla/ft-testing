# =============================================================================
# VM Test Shared Library
# =============================================================================
#
# Provides one base NixOS module config and a test runner for all VM smoke
# tests:
#
#   baseConfig — framework modules only (this consumer has no modules of its
#                own; every module under test lives in fast-track-nix)
#   mkTest     — wraps pkgs.testers.runNixOSTest with node.specialArgs so every
#                node receives `inputs` via specialArgs rather than _module.args,
#                making it safe to reference inputs inside `imports`.
#
# mergedInputs replicates what lib.mkFlake does (framework inputs merged with
# this consumer's inputs) so framework modules that reference inputs.* at import
# time (sops-nix, nix-index-database, nixos-facter-modules, etc.) evaluate
# correctly inside the test's NixOS module system.
#
# disko-btrfs and gaming.nix are excluded via disabledModules — see inline
# comments for the reason each is disabled.
# =============================================================================
{ inputs, nixpkgs }:

let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;

  # The framework's own inputs merged with this consumer's inputs — mirrors the
  # merge that lib.mkFlake performs so all framework modules receive the inputs
  # they were authored against.
  mergedInputs = inputs.ft-framework.inputs // inputs;
in
{
  # Wraps runNixOSTest with node.specialArgs so every node's NixOS module system
  # receives `inputs` at specialArgs scope — available when `imports` lists are
  # evaluated, unlike _module.args which is part of the config fixed-point and
  # causes infinite recursion when referenced in `imports`.
  mkTest =
    spec:
    pkgs.testers.runNixOSTest (
      nixpkgs.lib.recursiveUpdate spec {
        node.specialArgs.inputs = mergedInputs;
      }
    );

  # ---------------------------------------------------------------------------
  # baseConfig: framework modules only.
  # ---------------------------------------------------------------------------
  baseConfig =
    { ... }:
    {
      imports = [ inputs.ft-framework.nixosModules.default ];
      # disko-btrfs: hardware-dependent disk layout, no VM test.
      # gaming: Steam and its closure are too heavyweight for CI VM tests.
      disabledModules = [
        "${inputs.ft-framework}/modules/nixos/hardware/disko-btrfs.nix"
        "${inputs.ft-framework}/modules/nixos/profiles/gaming.nix"
      ];
      ft.core.stateVersion = "25.05";
      ft.users.initialPasswords.admin = "test";
      hardware.bluetooth.enable = false;
    };
}

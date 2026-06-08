# =============================================================================
# ft-testing — Framework Consumer + VM Smoke Test Suite
# =============================================================================
#
# A full, generic consumer of the fast-track-nix framework. It exists to
# exercise the framework end-to-end:
#
#   1. Template configs (machines/example, users/example, users/guest) that any
#      consumer could start from — CI evaluates nixosConfigurations.example to
#      prove the framework builds a real machine.
#   2. machines/strix-vm — a standalone, interactive QEMU test VM.
#   3. tests/vm/ — nixosTest VM smoke tests for framework modules, merged into
#      packages.x86_64-linux so they stay out of `nix flake check`.
#
# It has ZERO dependency on any personal config repo — every module under test
# lives in the framework. All output generation is delegated to
# ft-framework.lib.mkFlake, which discovers this repo's machines/ and users/.
#
# Do NOT run `nix flake update nixpkgs` — nixpkgs follows the framework's pin.
# To update the framework (and nixpkgs with it): nix flake update ft-framework.
# =============================================================================
{
  description = "ft-testing — fast-track-nix consumer with template configs and VM smoke tests";

  inputs = {
    # The framework. Phase 0 (mullet, facter, gpu, rclone upstreaming) is live on testing.
    ft-framework.url = "github:track-prepped-68-corolla/fast-track-nix/testing";

    # Follow the framework's pins to avoid duplicate fetches and version drift.
    nixpkgs.follows = "ft-framework/nixpkgs";
    home-manager.follows = "ft-framework/home-manager";
    nixos-facter.follows = "ft-framework/nixos-facter";
  };

  outputs =
    inputs@{ ft-framework, nixpkgs, ... }:
    nixpkgs.lib.recursiveUpdate (ft-framework.lib.mkFlake inputs) {
      # VM smoke tests — exposed as packages so they stay out of nix flake check.
      # Run manually via the vm-tests workflow or:
      #   nix build -L --option system-features "nixos-test kvm benchmark big-parallel" \
      #     .#vm-core-boot
      packages.x86_64-linux = import ./tests/vm { inherit inputs nixpkgs; };
    };
}

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
    let
      base = ft-framework.lib.mkFlake inputs;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # colmena hive eval check: machines/example opts into ft.deploy, so the
      # example node must appear in the colmenaHive output and the framework's
      # bridge module must map ft.deploy.tags -> deployment.tags. Forcing the
      # node's deployment config exercises membership filtering + the bridge +
      # makeHive at eval time, without building the system closure (already
      # covered by the nixosConfigurations.example toplevel eval). The colmena
      # layer is otherwise VM-test exempt (needs real inter-host SSH).
      exampleTags = base.colmenaHive.deploymentConfig.example.config.deployment.tags;
    in
    nixpkgs.lib.recursiveUpdate base {
      # Test suites — exposed as packages so they stay out of nix flake check.
      # VM smoke tests (vm-*), run via the vm-tests workflow or:
      #   nix build -L --option system-features "nixos-test kvm benchmark big-parallel" \
      #     .#vm-core-boot
      # Shell-recipe suite (shell-tests), run via the shell-tests workflow or:
      #   nix run .#shell-tests   (runs on the host, not the sandbox — see tests/shell)
      packages.x86_64-linux =
        (import ./tests/vm { inherit inputs nixpkgs; })
        // (import ./tests/shell/package.nix { inherit inputs nixpkgs; });

      checks.x86_64-linux.colmena-hive =
        assert nixpkgs.lib.assertMsg (exampleTags == [ "example" ])
          "colmenaHive bridge did not map ft.deploy.tags onto deployment.tags for the example node (got ${builtins.toJSON exampleTags})";
        pkgs.runCommand "colmena-hive-eval" { } "touch $out";
    };
}

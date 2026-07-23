# =============================================================================
# VM Smoke Tests — Entry Point
# =============================================================================
#
# Merges all per-module test files into a single attrset of
# packages.x86_64-linux.vm-* derivations.
#
# Run a single test locally:
#   nix build -L --no-link \
#     --option system-features "nixos-test kvm benchmark big-parallel" \
#     .#vm-core-boot
#
# Requirements: x86_64-linux host with /dev/kvm available.
# =============================================================================
{ inputs, nixpkgs }:

let
  inherit (nixpkgs) lib;
  args = { inherit inputs nixpkgs; };
in
lib.foldl lib.recursiveUpdate { } (
  map (f: import f args) [
    ./core-boot.nix
    ./tailscale-load.nix
    ./containers.nix
    ./printing.nix
    ./keepass.nix
    ./nix-index.nix
    ./virt.nix
    ./nfs-framework.nix
    ./cli.nix
    ./mullet.nix
    ./facter.nix
    ./vendor-hw.nix
    ./rclone.nix
    ./wine.nix
    ./git-workflow.nix
    ./gitops.nix
    ./gitops-home.nix
    ./bootstrap-workflow.nix
    ./flatpak.nix
    ./webapps.nix
    ./steam-config.nix
    ./moonlight.nix
  ]
)

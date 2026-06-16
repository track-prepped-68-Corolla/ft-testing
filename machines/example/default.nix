# =============================================================================
# example — Template Machine Configuration
# =============================================================================
#
# Discovered by the framework generator at machines/example/default.nix and
# becomes nixosConfigurations.example. This is the reference a new consumer
# copies when bootstrapping their own machine: it enables a representative set
# of framework features and reads its hardware report from var/facter.json.
#
# WHAT GOES HERE
#   var/facter.json         hardware report — source of truth for system arch
#   ft.diskBtrfs.device     block device for the system disk (default: /dev/nvme0n1)
#   Identity                hostName, ft.users.mainUser, ft.users.superUsers
#   ft.* feature toggles    enable framework modules
#
# Do not import framework modules directly — the generator injects them.
# =============================================================================
{ ... }:

{
  imports = [ ./modules ];

  # --- IDENTITY ---
  networking.hostName = "example";
  users.mutableUsers = true;

  ft.users = {
    mainUser = "example";
    superUsers = [ "example" ];
    initialPasswords.example = "nixos";
  };

  # --- DISK (btrfs: @ @home @nix @snapshots; /dev/vda suits QEMU VMs) ---
  ft.diskBtrfs = {
    enable = true;
    device = "/dev/vda";
  };

  # --- BOOT (systemd-boot keeps the template QEMU/UEFI-friendly) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # --- FEATURE TOGGLES ---
  # Hardware detection: replaces hardware-configuration.nix with facter.json.
  ft.facter = {
    enable = true;
    reportPath = ./var/facter.json;
  };

  # Universal GPU module — autodetects the vendor from facter.json.
  ft.gpu.enable = true;

  # The `ft` CLI helper. Requires ft.repoPath to locate scripts/ at runtime.
  ft.cli.enable = true;
  ft.repoPath = "/home/example/ft-testing";

  ft.core.stateVersion = "25.05";
}

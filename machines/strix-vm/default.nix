# =============================================================================
# strix-vm — Standalone Interactive Test VM
# =============================================================================
#
# A self-contained NixOS machine for interactive QEMU testing of framework
# features. It does NOT inherit from any other machine. Build and run with:
#
#   nix build .#nixosConfigurations.strix-vm.config.system.build.vm
#   ./result/bin/run-strix-vm-vm
#
# SSH into the running VM from the host:
#   ssh -p 2222 example@localhost      # password: nixos
# =============================================================================
{ lib, ... }:

{
  # --- IDENTITY ---
  networking.hostName = "strix-vm";
  users.mutableUsers = true;

  ft.users = {
    mainUser = "example";
    superUsers = [ "example" ];
    initialPasswords.example = "nixos";
  };

  # --- FILESYSTEM / BOOT ---
  # Placeholder root so the toplevel evaluates; the vmVariant below overrides
  # the disk with a QEMU image at build time.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # --- FEATURE TOGGLES ---
  ft.core.stateVersion = "25.05";
  ft.cli.enable = true;
  ft.repoPath = "/home/example/nixos-config";

  nixpkgs.hostPlatform = "x86_64-linux";

  # --- QEMU VM TUNING (applies to system.build.vm) ---
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = false;
    qemu.options = [
      "-net nic,model=virtio"
      # Forward host port 2222 to guest port 22 for SSH.
      "-net user,hostfwd=tcp::2222-:22"
    ];
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}

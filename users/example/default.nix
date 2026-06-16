# =============================================================================
# example — Template Home Manager Configuration
# =============================================================================
#
# Discovered by the framework generator at users/example/default.nix and
# becomes homeConfigurations.example@<arch> (one per machine arch).
#
# WHAT GOES HERE
#   home.username   required by the framework's home-core module
#   ft.repoPath     used by terminal/lazyvim/dotfiles modules to build live
#                   out-of-store symlink paths into the consumer repo
#   ft.* toggles    enable framework Home Manager features for this user
#   home.packages   user-specific packages
#
# Do not import framework home modules directly — the generator injects them.
# The dotfiles/ tree here is the generic template set (shared with users/guest);
# wire it up by enabling ft.dotfiles / ft.lazyvim once ft.repoPath is real.
# =============================================================================
{ pkgs, lib, ... }:

{
  imports = [ ../../modules/home ];

  # --- IDENTITY ---
  home.username = "example";
  ft.core.stateVersion = "25.05";

  # Point this at the absolute path of the cloned repo on the target to enable
  # the out-of-store dotfile symlinks (terminal, lazyvim, dotfiles modules).
  ft.repoPath = lib.mkDefault "/home/example/ft-testing";

  # --- ENVIRONMENT ---
  home.sessionVariables.EDITOR = "nvim";

  programs.git = {
    enable = true;
    userName = "example";
    userEmail = "example@fasttrack.os";
    delta.enable = true;
  };

  # --- PACKAGES ---
  home.packages = with pkgs; [
    fastfetch
    htop
    micro
  ];
}

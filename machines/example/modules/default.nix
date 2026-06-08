# =============================================================================
# Machine-local Module Hub — example
# =============================================================================
#
# Discovers every .nix file in this directory (e.g. disko.nix) and feeds it to
# the NixOS module system. Use for machine-specific config (disk layout, etc.)
# that is not generic enough to live in the framework.
# =============================================================================
{ lib, ... }:
let
  allFiles = lib.filesystem.listFilesRecursive ./.;
  # Exclude non-.nix files and this file itself to prevent an import cycle.
  validModules = builtins.filter (
    path: lib.hasSuffix ".nix" (builtins.toString path) && path != ./default.nix
  ) allFiles;
in
{
  imports = validModules;
}

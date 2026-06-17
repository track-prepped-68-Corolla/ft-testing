# =============================================================================
# example+development — Example Home Manager Profile
# =============================================================================
#
# Discovered by the framework generator at users/example/profiles/development/
# and layered on top of users/example/default.nix wherever "development"
# appears in a homeConfigurations combo name (e.g. example+development@<arch>,
# example+development+gaming@<arch>). See flake-parts/generator.nix in
# fast-track-nix for the combinator. Demonstrates the profiles/ convention —
# rename or remove freely.
# =============================================================================
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    direnv
    nixfmt
  ];
}

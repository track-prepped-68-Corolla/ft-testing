# =============================================================================
# example+gaming — Example Home Manager Profile
# =============================================================================
#
# Discovered by the framework generator at users/example/profiles/gaming/ and
# layered on top of users/example/default.nix wherever "gaming" appears in a
# homeConfigurations combo name (e.g. example+gaming@<arch>,
# example+development+gaming@<arch>). See flake-parts/generator.nix in
# fast-track-nix for the combinator. Demonstrates the profiles/ convention —
# rename or remove freely.
# =============================================================================
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mangohud
    heroic
  ];
}

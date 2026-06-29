# =============================================================================
# Rust Test Suite — Runnable
# =============================================================================
#
# Exposes packages.x86_64-linux.rust-tests as a runnable wrapper (not a
# build-time check) that exercises the experimental scripts/mullet-rs crate
# from fast-track-nix: `cargo test` against the vendored crate source, plus a
# bats integration suite driving the framework's already-built `mullet`
# binary (packages.mullet) — both reached through the ft-framework input.
#
# It must run OUTSIDE the Nix build sandbox: `cargo test` needs real network
# access to fetch crate dependencies declared in Cargo.lock. Running it as a
# `nix run` program (on the CI runner / a dev machine) avoids the sandboxed
# builder, while the toolchain still comes hermetically from this derivation.
#
#   nix run .#rust-tests             # all
#   nix run .#rust-tests -- unit     # cargo test only
#   nix run .#rust-tests -- integration
# =============================================================================
{ inputs, nixpkgs }:

let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  fw = inputs.ft-framework;
in
{
  rust-tests = pkgs.writeShellApplication {
    name = "rust-tests";
    runtimeInputs = [
      pkgs.cargo
      pkgs.rustc
      pkgs.gcc
      pkgs.bats
    ];
    text = ''
      # The crate under test lives in the framework input's scripts/mullet-rs.
      export FT_MULLET_RS_DIR="${fw}/scripts/mullet-rs"
      # The framework's already-built binary, for the integration suite.
      export FT_MULLET_BIN="${fw.packages.x86_64-linux.mullet}/bin/mullet"
      exec bash "${./.}/run.sh" "$@"
    '';
  };
}

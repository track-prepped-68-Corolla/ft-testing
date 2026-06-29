# Shared bats helpers for the mullet-rs integration suite.
#
# The binary under test is the experimental scripts/mullet-rs crate, built by
# fast-track-nix's flake-parts/rust.nix and consumed here via the
# ft-framework flake input. FT_MULLET_BIN must point at the built binary —
# the rust-tests Nix package sets it to
# "${ft-framework.packages.x86_64-linux.mullet}/bin/mullet"; for a local run,
# point it at a `cargo build` output, e.g.
#   FT_MULLET_BIN=../../../fast-track-nix/scripts/mullet-rs/target/debug/mullet \
#     tests/rust/run.sh integration

MULLET_BIN="${FT_MULLET_BIN:?set FT_MULLET_BIN to the built mullet binary}"
export MULLET_BIN

# Create a private directory for mock executables and prepend it to PATH.
# Call from a test's setup() before defining mocks.
setup_mockbin() {
  MOCKBIN="${BATS_TEST_TMPDIR}/mockbin"
  mkdir -p "$MOCKBIN"
  PATH="${MOCKBIN}:${PATH}"
  export MOCKBIN PATH
}

# Define a mock executable on PATH.
# Usage: mock <name> <line-of-body>...
# The body runs under bash; "$@" is the mock's args.
mock() {
  local name="$1"
  shift
  {
    printf '#!/usr/bin/env bash\n'
    printf '%s\n' "$@"
  } > "${MOCKBIN}/${name}"
  chmod +x "${MOCKBIN}/${name}"
}

# Create the users/$USER/var/mullet.txt path mullet-rs derives from $USER,
# relative to the current directory, and export it for tests to read/write.
setup_mullet_file() {
  export USER="testuser"
  MULLET_FILE="users/${USER}/var/mullet.txt"
  mkdir -p "$(dirname "$MULLET_FILE")"
  export MULLET_FILE
}

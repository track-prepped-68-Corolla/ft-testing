# Shared bats helpers for the ft shell test suite.
#
# The scripts under test live in the framework (fast-track-nix), consumed here
# via the ft-framework flake input. FT_SCRIPTS_DIR must point at that scripts/
# directory — the shell-tests Nix package sets it to "${ft-framework}/scripts";
# for a local run, set it to the input's store path or a local checkout, e.g.
#   FT_SCRIPTS_DIR=../fast-track-nix/scripts tests/shell/run.sh

SCRIPTS_DIR="${FT_SCRIPTS_DIR:?set FT_SCRIPTS_DIR to the framework scripts/ directory}"
LIB_DIR="${SCRIPTS_DIR}/lib"
export SCRIPTS_DIR LIB_DIR

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

# Initialise a throwaway git repo at $1 with a deterministic identity, so
# recipes that commit work inside the test sandbox.
init_git_repo() {
  git init -q "$1"
  git -C "$1" config user.email "test@example.com"
  git -C "$1" config user.name "Test"
  git -C "$1" config commit.gpgsign false
}

# Run an ft recipe against a consumer repo, faithfully mirroring the ft wrapper
# (bash shell, real scripts/ justfile, --working-directory = the repo, FT_REPO set).
# Usage: ft_run <repo> <recipe> [args...]
ft_run() {
  local repo="$1"
  shift
  FT_REPO="$repo" just \
    --shell bash \
    --justfile "${SCRIPTS_DIR}/ft.just" \
    --working-directory "$repo" \
    "$@"
}

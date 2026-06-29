#!/usr/bin/env bash
# Entry point for the mullet-rs test suite: cargo unit tests + bats
# integration against the built binary. Run via `nix run .#rust-tests` (CI /
# dev), or directly with cargo/bats on PATH, FT_MULLET_RS_DIR set to the
# framework's scripts/mullet-rs directory, and FT_MULLET_BIN set to a built
# mullet binary.
#
# Usage: tests/rust/run.sh [unit|integration]   (default: all)
#
# `all` runs every stage to completion and aggregates the result, so one run
# surfaces every failure rather than stopping at the first.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
what="${1:-all}"

run_unit() {
  echo ":: cargo test ::"
  local dir="${FT_MULLET_RS_DIR:?set FT_MULLET_RS_DIR to the framework scripts/mullet-rs directory}"
  local cargo_home target_dir
  cargo_home="$(mktemp -d)"
  target_dir="$(mktemp -d)"
  CARGO_HOME="$cargo_home" CARGO_TARGET_DIR="$target_dir" \
    cargo test --manifest-path "${dir}/Cargo.toml"
}

run_integration() { echo ":: bats integration ::"; bats --print-output-on-failure "${HERE}/integration"; }

run_all() {
  local rc=0
  run_unit        || rc=1
  run_integration || rc=1
  return "$rc"
}

case "$what" in
  unit)        run_unit ;;
  integration) run_integration ;;
  all)         run_all ;;
  *) echo "usage: run.sh [unit|integration]" >&2; exit 2 ;;
esac
rc=$?

if [ "$rc" -eq 0 ]; then
  echo ":: rust test suite passed ::"
else
  echo ":: rust test suite FAILED (see failures above) ::" >&2
fi
exit "$rc"

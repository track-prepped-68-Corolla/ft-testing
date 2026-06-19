#!/usr/bin/env bash
# Entry point for the ft shell test suite: shellcheck + bats unit + bats
# integration. Run via `nix run .#shell-tests` (CI / dev), or directly with
# bats/shellcheck/just/jq on PATH and FT_SCRIPTS_DIR set to the framework
# scripts/ directory.
#
# Usage: tests/shell/run.sh [unit|integration|lint]   (default: all)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
what="${1:-all}"

# Invoke sub-scripts via `bash` rather than relying on their shebang, so the
# suite also works where /usr/bin/env is absent.
run_lint() { bash "${HERE}/lint/shellcheck-scripts.sh"; }
run_unit() { echo ":: bats unit ::"; bats --print-output-on-failure "${HERE}/unit"; }
run_integration() { echo ":: bats integration ::"; bats --print-output-on-failure "${HERE}/integration"; }

case "$what" in
  lint)        run_lint ;;
  unit)        run_unit ;;
  integration) run_integration ;;
  all)         run_lint; run_unit; run_integration ;;
  *) echo "usage: run.sh [unit|integration|lint]" >&2; exit 2 ;;
esac

echo ":: shell test suite passed ::"

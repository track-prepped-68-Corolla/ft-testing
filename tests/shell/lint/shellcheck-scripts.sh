#!/usr/bin/env bash
# Static analysis for the ft shell scripts.
#
# Two passes:
#   1. The standalone bash — scripts/lib/*.sh and scripts/select-disk.sh — at
#      --severity=warning. These are plain files we fully control.
#   2. Every extracted bash recipe body at --severity=error, which catches real
#      defects (unset vars under `set -u`, bad redirects, broken tests) without
#      flagging the deliberate word-splitting some recipes rely on.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The scripts under test live in the framework, reached via FT_SCRIPTS_DIR
# (set by the shell-tests package to "${ft-framework}/scripts").
SCRIPTS="${FT_SCRIPTS_DIR:?set FT_SCRIPTS_DIR to the framework scripts/ directory}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo ":: Pass 1: lib/ + select-disk.sh (severity=warning) ::"
shellcheck --shell=bash --severity=warning --exclude=SC1091 \
  "${SCRIPTS}"/lib/*.sh "${SCRIPTS}/select-disk.sh"

echo ":: Pass 2: extracted recipe bodies (severity=error) ::"
for jf in "${SCRIPTS}"/*.just; do
  bash "${HERE}/extract-recipes.sh" "$jf" "$tmp"
done
mapfile -t bodies < <(find "$tmp" -name '*.sh' | sort)
shellcheck --shell=bash --severity=error --exclude=SC1091 "${bodies[@]}"

echo ":: shellcheck clean ::"

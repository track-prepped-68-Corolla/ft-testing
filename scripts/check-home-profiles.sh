#!/usr/bin/env bash
# =============================================================================
# check-home-profiles.sh — eval-only assertions for the profile combinator
# =============================================================================
#
# users/example/profiles/{gaming,development}/ exercises the generator's
# profile discovery (flake-parts/generator.nix in fast-track-nix): every
# non-empty combination of a user's profiles must produce its own
# homeConfigurations entry, additive on top of the base user config. No
# configuration is built — pure nix eval.
#
# Usage: scripts/check-home-profiles.sh [flake-ref]
#        flake-ref defaults to the repo root.
# =============================================================================
set -uo pipefail

flake="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
pass=0
fail=0

check() {
  # check <homeConfiguration name> <nix expression over the config> <expected JSON>
  local name=$1 expr=$2 expected=$3 actual
  if ! actual=$(
    nix eval --json "$flake#homeConfigurations.$name.config" \
      --apply "config: $expr" 2>/dev/null
  ); then
    echo "FAIL $name: $expr — evaluation error"
    nix eval --json "$flake#homeConfigurations.$name.config" \
      --apply "config: $expr" 2>&1 >/dev/null | tail -n 5 | sed 's/^/      /'
    fail=$((fail + 1))
    return
  fi
  if [ "$actual" = "$expected" ]; then
    echo "PASS $name: $expr == $expected"
    pass=$((pass + 1))
  else
    echo "FAIL $name: $expr — expected $expected, got $actual"
    fail=$((fail + 1))
  fi
}

pkgNames='map (p: p.pname or p.name) config.home.packages'
arch=x86_64-linux

# --- Base user: no profile packages leak in without opting in -----------------
check "example@$arch" "builtins.elem \"mangohud\" ($pkgNames)" false
check "example@$arch" "builtins.elem \"direnv\" ($pkgNames)" false

# --- Single profile: gaming -----------------------------------------------------
check "example+gaming@$arch" "builtins.elem \"mangohud\" ($pkgNames)" true
check "example+gaming@$arch" "builtins.elem \"direnv\" ($pkgNames)" false

# --- Single profile: development -------------------------------------------------
check "example+development@$arch" "builtins.elem \"direnv\" ($pkgNames)" true
check "example+development@$arch" "builtins.elem \"mangohud\" ($pkgNames)" false

# --- Stacked combination: both profiles merge together ---------------------------
check "example+development+gaming@$arch" "builtins.elem \"mangohud\" ($pkgNames)" true
check "example+development+gaming@$arch" "builtins.elem \"direnv\" ($pkgNames)" true

echo
echo "home profile eval checks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

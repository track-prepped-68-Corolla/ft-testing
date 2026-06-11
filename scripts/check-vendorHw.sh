#!/usr/bin/env bash
# =============================================================================
# check-vendorHw.sh — eval-only assertions for ft.vendorHw / ft.gpu detection
# =============================================================================
#
# Each machines/vendorHw-* configuration points ft.facter.reportPath at a
# hand-crafted hardware report in fixtures/vendorHw/. This script evaluates
# the downstream NixOS options that the framework's vendor-hw.nix (and gpu.nix
# for the Optimus fixture) must derive from each fixture and compares them to
# the expected values. No machine is built or booted — pure nix eval.
#
# Usage: scripts/check-vendorHw.sh [flake-ref]
#        flake-ref defaults to the repo root.
# =============================================================================
set -uo pipefail

flake="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
pass=0
fail=0

check() {
  # check <machine> <nix expression over the machine's config> <expected JSON>
  local machine=$1 expr=$2 expected=$3 actual
  if ! actual=$(
    nix eval --json "$flake#nixosConfigurations.$machine.config" \
      --apply "config: $expr" 2>/dev/null
  ); then
    echo "FAIL $machine: $expr — evaluation error"
    nix eval --json "$flake#nixosConfigurations.$machine.config" \
      --apply "config: $expr" 2>&1 >/dev/null | tail -n 5 | sed 's/^/      /'
    fail=$((fail + 1))
    return
  fi
  if [ "$actual" = "$expected" ]; then
    echo "PASS $machine: $expr == $expected"
    pass=$((pass + 1))
  else
    echo "FAIL $machine: $expr — expected $expected, got $actual"
    fail=$((fail + 1))
  fi
}

# --- Lenovo Legion: DMI manufacturer=LENOVO + family=Legion ------------------
# lenovoLegionLinux is injected via boot.extraModulePackages; package-list
# introspection is fragile, so assert the list is non-empty instead.
check vendorHw-lenovo-legion 'builtins.length config.boot.extraModulePackages > 0' true

# --- Razer: USB vendor ID 1532 -----------------------------------------------
check vendorHw-razer-usb 'config.hardware.openrazer.enable' true

# --- MSI: DMI manufacturer=Micro-Star International Co., Ltd. ----------------
check vendorHw-msi-laptop 'builtins.elem "msi-ec" config.boot.kernelModules' true

# --- Logitech: USB vendor ID 046d ---------------------------------------------
check vendorHw-logitech-usb 'config.services.ratbagd.enable' true

# --- Corsair: USB vendor ID 1b1c -----------------------------------------------
check vendorHw-corsair-usb 'config.hardware.ckb-next.enable' true

# --- ASUS ROG: DMI manufacturer=ASUSTeK COMPUTER INC. -------------------------
check vendorHw-asus-rog 'config.services.asusd.enable' true

# --- GPD handheld: DMI manufacturer=GPD ----------------------------------------
check vendorHw-gpd-handheld 'config.services.inputplumber.enable' true
check vendorHw-gpd-handheld 'config.services.powerstation.enable' true

# --- Generic handheld: SMBIOS chassis type 11 ----------------------------------
check vendorHw-chassis-11 'config.services.inputplumber.enable' true

# --- No match: Dell strings, no USB vendors → nothing may switch on -----------
check vendorHw-no-match 'config.hardware.openrazer.enable' false
check vendorHw-no-match 'config.services.ratbagd.enable' false
check vendorHw-no-match 'config.hardware.ckb-next.enable' false
check vendorHw-no-match 'config.services.asusd.enable' false
check vendorHw-no-match 'config.services.inputplumber.enable' false
check vendorHw-no-match 'builtins.elem "msi-ec" config.boot.kernelModules' false
check vendorHw-no-match 'builtins.length config.boot.extraModulePackages' 0

# --- Multi: Razer USB + ASUS DMI in one report → both brands enabled ----------
check vendorHw-multi 'config.hardware.openrazer.enable' true
check vendorHw-multi 'config.services.asusd.enable' true

echo
echo "vendorHw eval checks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

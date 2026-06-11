#!/usr/bin/env bash
# =============================================================================
# check-gpu.sh — eval-only assertions for ft.gpu vendor/PRIME detection
# =============================================================================
#
# Each machines/gpu-* configuration points ft.facter.reportPath at a
# hand-crafted hardware report in fixtures/gpu/. This script evaluates the
# downstream NixOS options that the framework's gpu.nix must derive from each
# fixture and compares them to the expected values. No machine is built or
# booted — pure nix eval.
#
# Usage: scripts/check-gpu.sh [flake-ref]
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

# --- Single NVIDIA dGPU (Turing+): nvidia driver, no PRIME/cardwire ----------
# The machine pins ft.gpu.nvidia.openKernelModules = false; a Turing-or-newer
# device ID must force the open kernel modules on regardless.
check gpu-nvidia-single 'builtins.elem "nvidia" config.services.xserver.videoDrivers' true
check gpu-nvidia-single 'config.hardware.nvidia.open' true
check gpu-nvidia-single 'config.hardware.nvidia.modesetting.enable' true
check gpu-nvidia-single 'config.ft.cardwire.enable' false
check gpu-nvidia-single 'config.hardware.nvidia.powerManagement.finegrained' false

# --- Single NVIDIA dGPU (pre-Turing): openKernelModules override honoured ----
check gpu-nvidia-pascal 'config.hardware.nvidia.open' false

# --- Single AMD GPU: amdgpu driver + OpenCL -----------------------------------
check gpu-amd-single 'builtins.elem "amdgpu" config.services.xserver.videoDrivers' true
check gpu-amd-single 'builtins.elem "nvidia" config.services.xserver.videoDrivers' false
check gpu-amd-single 'config.hardware.amdgpu.opencl.enable' true
check gpu-amd-single 'config.hardware.graphics.enable' true

# --- Single Intel GPU ----------------------------------------------------------
check gpu-intel-single 'builtins.elem "intel" config.services.xserver.videoDrivers' true

# --- AMD reported via bound driver only (no vendor ID) -------------------------
check gpu-amd-driver-only 'builtins.elem "amdgpu" config.services.xserver.videoDrivers' true

# --- Optimus with Intel iGPU (the common pairing): PRIME via intelBusId -------
check gpu-optimus-intel 'builtins.elem "nvidia" config.services.xserver.videoDrivers' true
check gpu-optimus-intel 'config.ft.cardwire.enable' true
check gpu-optimus-intel 'config.hardware.nvidia.prime.offload.enable' true
check gpu-optimus-intel 'config.hardware.nvidia.prime.intelBusId' '"PCI:0:2:0"'
check gpu-optimus-intel 'config.hardware.nvidia.prime.nvidiaBusId' '"PCI:1:0:0"'
check gpu-optimus-intel 'config.hardware.nvidia.powerManagement.finegrained' true

# --- Optimus with AMD iGPU: PRIME via amdgpuBusId + cardwire -------------------
check gpu-optimus-amd 'builtins.elem "nvidia" config.services.xserver.videoDrivers' true
check gpu-optimus-amd 'config.ft.cardwire.enable' true
check gpu-optimus-amd 'config.hardware.nvidia.prime.offload.enable' true
check gpu-optimus-amd 'config.hardware.nvidia.prime.amdgpuBusId' '"PCI:6:0:0"'
check gpu-optimus-amd 'config.hardware.nvidia.prime.nvidiaBusId' '"PCI:1:0:0"'
check gpu-optimus-amd 'config.hardware.nvidia.powerManagement.finegrained' true

# --- Optimus with a missing dGPU sysfs_bus_id: PRIME must stay off -------------
check gpu-optimus-no-busid 'builtins.elem "nvidia" config.services.xserver.videoDrivers' true
check gpu-optimus-no-busid 'config.ft.cardwire.enable' false
check gpu-optimus-no-busid 'config.hardware.nvidia.prime.offload.enable' false

# --- Unknown GPU vendor: fall back to the ft.gpu.vendor default (amd) ----------
check gpu-fallback-unknown 'builtins.elem "amdgpu" config.services.xserver.videoDrivers' true

echo
echo "gpu eval checks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

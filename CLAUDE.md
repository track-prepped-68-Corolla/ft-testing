# ft-testing — Developer Reference

## What this is

`ft-testing` is a **generic, full consumer** of the `fast-track-nix` framework
(aliased as `ft-framework` in flake inputs). It exists to exercise the framework
end-to-end and has **zero dependency on any personal config repo** — every
module it uses or tests lives in `fast-track-nix`.

It serves three roles:

1. **Template configs** — `machines/example`, `users/example`, `users/guest`
   are the reference a new consumer copies. CI evaluates
   `nixosConfigurations.example` to prove the framework builds a real machine.
2. **Interactive test VM** — `machines/strix-vm` is a standalone QEMU machine
   (no inheritance from any other machine).
3. **VM smoke test suite** — `tests/vm/` contains `nixosTest` integration tests
   for framework modules, merged into `packages.x86_64-linux` so they stay out
   of `nix flake check`.

`ft-testing` shares its template content (machines/users/scripts) with the
`ft-template` repo; `ft-template` is `ft-testing` minus `tests/` and
`machines/strix-vm`. Keep design changes to the shared content in sync by
convention.

`flake.nix` delegates to `ft-framework.lib.mkFlake inputs` and merges the VM
test packages in via `nixpkgs.lib.recursiveUpdate`.

---

## Structure

```
flake.nix                 # delegation to ft-framework.lib.mkFlake + test merge
machines/
  example/                # template machine — real facter.json, disko, ft.* toggles
    default.nix
    modules/{default.nix,disko.nix}
    var/facter.json        # hardware report — source of truth for system arch
  strix-vm/               # standalone interactive QEMU test VM
    default.nix
users/
  example/                # template user (generic dotfiles, shared with guest)
    profiles/             # example profiles (gaming, development) — exercises
                          # the generator's profile combinator; produces
                          # example+gaming@<arch>, example+development@<arch>,
                          # example+development+gaming@<arch>, etc.
  guest/                  # default guest user
modules/
  home/default.nix        # empty consumer HM hub (kept so users/*/imports resolve)
                          # NOTE: there is intentionally NO modules/nixos — every
                          # NixOS module lives in fast-track-nix.
tests/vm/                 # VM smoke test suite (see below)
scripts/                  # ft CLI just-recipes (sys, bootstrap, mullet, ...)
```

There is **no `modules/nixos/`**: the four consumer-suitable modules (mullet,
facter, gpu, rclone) were upstreamed into `fast-track-nix`, and the rest were
dropped in favour of framework equivalents. If you need a NixOS module, add it
to `fast-track-nix`, not here.

---

## Hard rules

- **Never `nix flake update nixpkgs`** — nixpkgs follows the framework's pin.
  To update the framework (and nixpkgs with it): `nix flake update ft-framework`.
- **No personal data.** This is a generic consumer; usernames, hostnames, and
  identifiers must stay generic (`example`, `guest`).
- **Logic belongs in `fast-track-nix`.** This repo is configuration values plus
  tests, never reusable module logic.
- All PRs target `testing`, never `main`.

---

## VM Smoke Tests

Tests live in `tests/vm/` and are exposed as `packages.x86_64-linux.vm-*`.

**Run one locally:**
```bash
nix build -L --no-link \
  --option system-features "nixos-test kvm benchmark big-parallel" \
  .#vm-core-boot
```

**Trigger all:** `VM Smoke Tests` workflow → `workflow_dispatch`.

`tests/vm/lib.nix` is a thin wrapper around the framework's VM test helpers:

- `mkTest` — calls `inputs.ft-framework.lib.mkVmTest inputs`, which wraps
  `runNixOSTest` with the merged input set (`lib.mergeInputs`) in
  `node.specialArgs` so every node gets the same `inputs` that real machines
  receive from the generator.
- `baseConfig` — imports `inputs.ft-framework.lib.vmTestBase inputs` (the
  framework module hub + sandbox-compatible `disabledModules`) and adds the
  test-specific baseline: `stateVersion`, admin password, no Bluetooth.

Every test must assert at least one **runtime effect** (service active, binary
on PATH, file present), not merely that the config evaluates. After adding a
test file, register it in `tests/vm/default.nix` and
`.github/workflows/vm-tests.yml`.

---

## Quality checks

All must pass before every commit:

```bash
treefmt          # nixfmt + deadnix --edit
statix check .   # Nix anti-pattern linter
trufflehog git . # credential/secret scanner
nix flake check  # validates all outputs evaluate cleanly
```

CI additionally evaluates every `nixosConfigurations.*` to its `toplevel`
derivation, so a template machine that fails to evaluate fails CI.

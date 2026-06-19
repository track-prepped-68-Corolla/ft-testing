# ft shell tests

Tests for the framework's bundled `ft` CLI just-recipes, which live in
**fast-track-nix** (`scripts/`), not in this repo. The recipes' pure logic lives
in sourceable helpers under that `scripts/lib/`; the recipes and these tests
both consume them, so units run without spinning up `just`, `nix` or `ssh`.

This suite reaches the framework scripts through the `ft-framework` flake input
(`FT_SCRIPTS_DIR`), mirroring how the VM smoke tests reach framework modules.

## Layout

```
tests/shell/
  package.nix              # the shell-tests Nix package (sets FT_SCRIPTS_DIR)
  helpers/load.bash        # FT_SCRIPTS_DIR wiring, mock + git helpers, ft_run
  unit/                    # bats unit tests for the framework's scripts/lib/*.sh
  integration/             # bats tests that drive real `just` recipes / select-disk.sh
                           #   with nix/ssh/sops/lsblk/findmnt mocked
  lint/                    # shellcheck over lib + select-disk.sh and every
                           #   extracted bash recipe body
  run.sh                   # orchestrator: lint + unit + integration
```

## Running

Everything runs in CI via the **Shell Tests** `workflow_dispatch` job
(`.github/workflows/shell-tests.yml`), which runs the `shell-tests` package
(it sets `FT_SCRIPTS_DIR` to the framework input's `scripts/`):

```bash
nix run .#shell-tests            # all
nix run .#shell-tests -- unit    # unit | integration | lint
```

> It runs via `nix run`, not `nix build`: the framework recipes, the mocks, and
> these helpers all execute through their `#!/usr/bin/env bash` shebangs, which
> the Nix build sandbox can't satisfy (no `/usr/bin/env`). `nix run` executes on
> the host, where it can, while the toolchain still comes from the derivation.

Locally without `nix run`, set `FT_SCRIPTS_DIR` to a fast-track-nix checkout (or
the input's store path); `bats`, `shellcheck`, `just`, and `jq` need to be on PATH:

```bash
FT_SCRIPTS_DIR=../fast-track-nix/scripts tests/shell/run.sh              # all
FT_SCRIPTS_DIR=../fast-track-nix/scripts tests/shell/run.sh unit
FT_SCRIPTS_DIR=../fast-track-nix/scripts tests/shell/run.sh integration
FT_SCRIPTS_DIR=../fast-track-nix/scripts tests/shell/run.sh lint
```

This suite is intentionally **not** part of `nix flake check` — like the VM
tests, it is manual-dispatch only.

## Conventions

- Every test asserts a concrete effect (a file written, a value parsed, an exit
  code), never just that something evaluated.
- Integration tests stub external/destructive commands (`nix`, `ssh`,
  `ssh-keygen`, `ssh-to-age`, `lsblk`, `findmnt`) via `setup_mockbin` + `mock`
  and operate on a throwaway git repo in `$BATS_TEST_TMPDIR`. No real host,
  network, or block device is touched.

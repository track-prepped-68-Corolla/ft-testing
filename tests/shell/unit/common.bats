#!/usr/bin/env bats
# Unit tests for scripts/lib/common.sh

load ../helpers/load

setup() {
  source "${LIB_DIR}/common.sh"
  cd "${BATS_TEST_TMPDIR}"
}

@test "gitignore_add appends the pattern" {
  gitignore_add .gitignore "/var/git/"
  run cat .gitignore
  [ "$status" -eq 0 ]
  [ "$output" = "/var/git/" ]
}

@test "gitignore_add is idempotent" {
  gitignore_add .gitignore "/var/git/"
  gitignore_add .gitignore "/var/git/"
  gitignore_add .gitignore "/var/git/"
  run wc -l < .gitignore
  [ "$output" -eq 1 ]
}

@test "gitignore_add preserves existing entries" {
  printf '/foo\n' > .gitignore
  gitignore_add .gitignore "/var/git/"
  run cat .gitignore
  [ "${lines[0]}" = "/foo" ]
  [ "${lines[1]}" = "/var/git/" ]
}

@test "is_json_object accepts an object" {
  printf '{}' > a.json
  run is_json_object a.json
  [ "$status" -eq 0 ]
}

@test "is_json_object accepts an object with leading content" {
  printf '{ "system": "x86_64-linux" }\n' > a.json
  run is_json_object a.json
  [ "$status" -eq 0 ]
}

@test "is_json_object rejects an empty file" {
  : > a.json
  run is_json_object a.json
  [ "$status" -ne 0 ]
}

@test "is_json_object rejects non-JSON" {
  printf 'error: boom\n' > a.json
  run is_json_object a.json
  [ "$status" -ne 0 ]
}

@test "nixos_anywhere uses an installed binary when present" {
  setup_mockbin
  mock nixos-anywhere 'printf "installed %s\n" "$*"'
  mock nix 'printf "nix %s\n" "$*"'
  run nixos_anywhere --flake .#x --extra-files /tmp/y root@host
  [ "$status" -eq 0 ]
  [[ "$output" == installed* ]]
  [[ "$output" == *"--flake .#x"* ]]
}

@test "nixos_anywhere falls back to nix run when not installed" {
  setup_mockbin
  command -v nixos-anywhere >/dev/null 2>&1 && skip "nixos-anywhere present in test env"
  mock nix 'printf "nix %s\n" "$*"'
  run nixos_anywhere --flake .#x root@host
  [ "$status" -eq 0 ]
  [[ "$output" == "nix run"* ]]
  [[ "$output" == *"github:nix-community/nixos-anywhere"* ]]
  [[ "$output" == *"--flake .#x"* ]]
}

@test "git_push_branch pushes the current branch" {
  setup_mockbin
  mock git 'case "$1" in rev-parse) echo work ;; push) printf "push %s\n" "$*"; exit 0 ;; esac'
  run git_push_branch
  [ "$status" -eq 0 ]
  [[ "$output" == *"push -u origin work"* ]]
}

@test "git_push_branch retries on failure then succeeds" {
  setup_mockbin
  mock sleep ':'
  mock git '
    case "$1" in
      rev-parse) echo work ;;
      push)
        n=$(cat "$BATS_TEST_TMPDIR/n" 2>/dev/null || echo 0); n=$((n + 1))
        echo "$n" > "$BATS_TEST_TMPDIR/n"
        [ "$n" -ge 3 ]
        ;;
    esac'
  run git_push_branch
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/n")" -eq 3 ]
  [[ "$output" == *"retrying"* ]]
}

@test "git_push_branch warns but does not fail when push never succeeds" {
  setup_mockbin
  mock sleep ':'
  mock git 'case "$1" in rev-parse) echo work ;; push) exit 1 ;; esac'
  run git_push_branch
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"* ]]
  [[ "$output" == *"ft capture"* ]]
}

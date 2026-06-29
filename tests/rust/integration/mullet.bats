#!/usr/bin/env bats
# Integration tests for the mullet-rs binary (experimental Rust replica of
# mullet.just), with nix/nix-locate mocked so package validation and search
# run without a real Nix store lookup.

load ../helpers/load

setup() {
  setup_mockbin
  cd "${BATS_TEST_TMPDIR}"
  setup_mullet_file
}

@test "lst reports empty when no mullet file exists" {
  run "$MULLET_BIN" lst
  [ "$status" -eq 0 ]
  [[ "$output" == *"(Empty)"* ]]
}

@test "add appends a validated package and lst then shows it" {
  mock nix 'exit 0'
  run "$MULLET_BIN" add ripgrep
  [ "$status" -eq 0 ]
  [[ "$output" == *"Added ripgrep"* ]]
  [ "$(cat "$MULLET_FILE")" = "ripgrep" ]
}

@test "add is idempotent for an already-present package" {
  printf 'ripgrep\n' > "$MULLET_FILE"
  mock nix 'exit 0'
  run "$MULLET_BIN" add ripgrep
  [ "$status" -eq 0 ]
  [[ "$output" == *"already in The Mullet"* ]]
  [ "$(wc -l < "$MULLET_FILE")" -eq 1 ]
}

@test "add fails and leaves the file untouched when the package doesn't validate" {
  mock nix 'exit 1'
  mock nix-locate 'true'
  run "$MULLET_BIN" add not-a-real-package
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not a valid package path"* ]]
  [ ! -s "$MULLET_FILE" ]
}

@test "rm removes only the named package" {
  printf 'ripgrep\nfd\n' > "$MULLET_FILE"
  run "$MULLET_BIN" rm ripgrep
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed ripgrep"* ]]
  [ "$(cat "$MULLET_FILE")" = "fd" ]
}

@test "rm errors when the package is not present" {
  printf 'fd\n' > "$MULLET_FILE"
  run "$MULLET_BIN" rm ripgrep
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found in The Mullet"* ]]
  [ "$(cat "$MULLET_FILE")" = "fd" ]
}

@test "haircut on confirmation empties the file" {
  printf 'ripgrep\nfd\n' > "$MULLET_FILE"
  run bash -c "echo y | \"$MULLET_BIN\" haircut"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Haircut complete"* ]]
  [ ! -s "$MULLET_FILE" ]
}

@test "haircut without confirmation leaves the file untouched" {
  printf 'ripgrep\nfd\n' > "$MULLET_FILE"
  run bash -c "echo n | \"$MULLET_BIN\" haircut"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cancelled"* ]]
  [ "$(cat "$MULLET_FILE")" = $'ripgrep\nfd' ]
}

@test "search prints nix-locate results when a binary match is found" {
  mock nix-locate 'printf "ripgrep.out /bin/rg\n"'
  run "$MULLET_BIN" search rg
  [ "$status" -eq 0 ]
  [[ "$output" == *"ripgrep.out /bin/rg"* ]]
}

@test "search falls back to nixpkgs descriptions when no binary match is found" {
  mock nix-locate 'true'
  mock nix 'printf "* legacyPackages.x86_64-linux.ripgrep\n  Fast line-oriented search\n"'
  run "$MULLET_BIN" search ripgrep
  [ "$status" -eq 0 ]
  [[ "$output" == *"No exact binary match"* ]]
  [[ "$output" == *"legacyPackages.x86_64-linux.ripgrep"* ]]
}

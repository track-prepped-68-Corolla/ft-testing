#!/usr/bin/env bats
# Integration tests for the _preflight recipe, with `nix` mocked so the eval
# gate and ft.* introspection are driven from canned facts (no real flake).

load ../helpers/load

REAL="age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqd2y7gl"

setup() {
  setup_mockbin
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "$REPO/var/secrets" "$REPO/machines/demo/var"
}

@test "blocks when the config does not evaluate" {
  mock nix 'echo "error: attribute missing" >&2; exit 1'
  run ft_run "$REPO" _preflight demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not evaluate"* ]]
}

@test "blocks when sops is enabled but the recipient is a placeholder" {
  mock nix 'printf "%s\n" "{\"sops\":true,\"facter\":false,\"ssh\":false,\"keys\":0}"'
  cat > "$REPO/var/secrets/.sops.yaml" <<EOF
keys:
  - &demo age1PLACEHOLDER_DEMO_AGE_PUBKEY
EOF
  run ft_run "$REPO" _preflight demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"BLOCK"* ]]
  [[ "$output" == *"placeholder/invalid"* ]]
}

@test "blocks when sops is enabled but .sops.yaml is missing" {
  mock nix 'printf "%s\n" "{\"sops\":true,\"facter\":false,\"ssh\":false,\"keys\":0}"'
  run ft_run "$REPO" _preflight demo
  [ "$status" -ne 0 ]
  [[ "$output" == *".sops.yaml is missing"* ]]
}

@test "passes when the config evaluates and the sops recipient is valid" {
  mock nix 'printf "%s\n" "{\"sops\":true,\"facter\":false,\"ssh\":false,\"keys\":0}"'
  cat > "$REPO/var/secrets/.sops.yaml" <<EOF
keys:
  - &demo ${REAL}
EOF
  run ft_run "$REPO" _preflight demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pre-flight OK"* ]]
}

@test "warns (does not block) when a facter report exists but ft.facter is off" {
  mock nix 'printf "%s\n" "{\"sops\":false,\"facter\":false,\"ssh\":false,\"keys\":0}"'
  printf '{}' > "$REPO/machines/demo/var/facter.json"
  run ft_run "$REPO" _preflight demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"* ]]
  [[ "$output" == *"facter.json"* ]]
}

@test "warns (does not block) when ssh is enabled with no authorized keys" {
  mock nix 'printf "%s\n" "{\"sops\":false,\"facter\":false,\"ssh\":true,\"keys\":0}"'
  run ft_run "$REPO" _preflight demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"authorizedKeys is empty"* ]]
}

#!/usr/bin/env bats
# Unit tests for scripts/lib/komodo.sh — the Komodo resource-sync generator.

load ../helpers/load

setup() {
  source "${LIB_DIR}/komodo.sh"
  cd "${BATS_TEST_TMPDIR}"
}

@test "komodo_git_slug parses ssh and https, stripping .git" {
  [ "$(komodo_git_slug 'git@github.com:owner/repo.git')" = "owner/repo" ]
  [ "$(komodo_git_slug 'https://github.com/owner/repo.git')" = "owner/repo" ]
  [ "$(komodo_git_slug 'https://github.com/owner/repo')" = "owner/repo" ]
}

@test "komodo_git_host parses ssh and https" {
  [ "$(komodo_git_host 'git@github.com:owner/repo.git')" = "github.com" ]
  [ "$(komodo_git_host 'https://gitlab.example.com/owner/repo')" = "gitlab.example.com" ]
}

@test "komodo_stack_name strips directory and extension" {
  [ "$(komodo_stack_name 'containers/media.yaml')" = "media" ]
  [ "$(komodo_stack_name '/abs/homeAutomation.yml')" = "homeAutomation" ]
}

@test "komodo_generate emits a resource_sync header and a stack per compose file" {
  mkdir -p containers/config
  printf 'services: {}\n' > containers/media.yaml
  printf 'services: {}\n' > containers/observability.yaml
  printf 'ignored\n' > containers/config/prometheus.yml

  run komodo_generate containers "ft-home-stacks" "containers/komodo-sync.toml" \
    "Local" "github.com" "acct" "owner/ft-home" "main"
  [ "$status" -eq 0 ]

  # Self-managing sync header.
  [[ "$output" == *'[[resource_sync]]'* ]]
  [[ "$output" == *'name = "ft-home-stacks"'* ]]
  [[ "$output" == *'resource_path = ["containers/komodo-sync.toml"]'* ]]

  # One stack per top-level compose file; the config/ subdirectory is ignored.
  [ "$(printf '%s\n' "$output" | grep -c '^\[\[stack\]\]')" -eq 2 ]
  [[ "$output" == *'name = "media"'* ]]
  [[ "$output" == *'name = "observability"'* ]]
  [[ "$output" != *"prometheus"* ]]

  # Git-backed stack fields.
  [[ "$output" == *'file_paths = ["containers/media.yaml"]'* ]]
  [[ "$output" == *'repo = "owner/ft-home"'* ]]
  [[ "$output" == *'server = "Local"'* ]]
  [[ "$output" == *'deploy = true'* ]]
}

@test "komodo_generate embeds a sibling .env as the stack environment" {
  mkdir -p containers
  printf 'services: {}\n' > containers/media.yaml
  printf 'PUID=1000\nTOKEN=[[TOKEN]]\n' > containers/media.env

  run komodo_generate containers "s" "p.toml" "Local" "github.com" "acct" "o/r" "main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'environment = """'* ]]
  [[ "$output" == *'PUID=1000'* ]]
  [[ "$output" == *'TOKEN=[[TOKEN]]'* ]]
}

@test "komodo_generate omits git_account when empty (public repo)" {
  mkdir -p containers
  printf 'services: {}\n' > containers/x.yaml

  run komodo_generate containers "s" "p.toml" "Local" "github.com" "" "o/r" "main"
  [ "$status" -eq 0 ]
  [[ "$output" != *"git_account"* ]]
}

@test "komodo_generate on an empty containers dir emits only the header" {
  mkdir -p containers

  run komodo_generate containers "s" "p.toml" "Local" "github.com" "acct" "o/r" "main"
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | grep -c '^\[\[stack\]\]')" -eq 0 ]
  [[ "$output" == *'[[resource_sync]]'* ]]
}

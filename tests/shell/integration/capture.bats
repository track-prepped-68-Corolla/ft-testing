#!/usr/bin/env bats
# Integration tests for the `capture` recipe (bootstrap.just), driven through
# real `just` exactly as the ft wrapper would, with ssh / ssh-to-age / sleep
# mocked so no host or network is touched. git is real: a bare `origin` lets
# git_push_branch actually push, so we can assert the snowflakes reach the remote.

load ../helpers/load

setup() {
  setup_mockbin
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "$REPO"
  init_git_repo "$REPO"
  # A bare origin so git_push_branch's push succeeds on the first try.
  git init -q --bare "${BATS_TEST_TMPDIR}/remote.git"
  git -C "$REPO" remote add origin "${BATS_TEST_TMPDIR}/remote.git"
  mock sleep ':'
  mock ssh-to-age 'cat >/dev/null; printf "age1capturefake\n"'
}

# One ssh mock serves every call capture makes; it branches on the remote
# command and records each invocation for assertions.
mock_ssh() {
  mock ssh '
    cmd="$*"
    printf "%s\n" "$cmd" >> "$BATS_TEST_TMPDIR/ssh.args"
    case "$cmd" in
      *nixos-facter*)             printf "{\"system\":\"x86_64-linux\"}\n" ;;
      *ssh_host_ed25519_key.pub*) printf "ssh-ed25519 AAAAFAKE host\n" ;;
      *findmnt*)                  printf "/dev/mapper/cryptroot\n" ;;
      *lsblk*)                    printf "nvme0n1\n" ;;
    esac'
}

@test "capture re-runs facter on the host, commits it, and pushes" {
  mock_ssh
  run ft_run "$REPO" capture strix 1.2.3.4 root
  [ "$status" -eq 0 ]
  # facter pulled off the host and committed
  head -c1 "$REPO/machines/strix/var/facter.json" | grep -q '{'
  git -C "$REPO" ls-files machines/strix/var/facter.json | grep -q .
  # same flakes-on-the-ISO guard as generate-facts
  grep -q -- '--extra-experimental-features' "$BATS_TEST_TMPDIR/ssh.args"
  grep -q 'nix-command flakes' "$BATS_TEST_TMPDIR/ssh.args"
  # the commit reached origin (not stranded locally — the lyra lesson)
  run git -C "${BATS_TEST_TMPDIR}/remote.git" log --oneline
  [[ "$output" == *"capture:"* ]]
}

@test "capture warns (without failing) when the host's sops recipient or disk drifts" {
  mkdir -p "$REPO/var/secrets" "$REPO/machines/strix"
  printf 'keys:\n  - &strix age1OLDPLACEHOLDER\n' > "$REPO/var/secrets/.sops.yaml"
  printf '{ ... ft.diskBtrfs.device = "/dev/sda"; ... }\n' > "$REPO/machines/strix/default.nix"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm seed
  mock_ssh
  run ft_run "$REPO" capture strix 1.2.3.4
  [ "$status" -eq 0 ]
  # host's real age recipient differs from .sops.yaml
  [[ "$output" == *"sops recipient"* ]]
  [[ "$output" == *"age1capturefake"* ]]
  # installed disk (nvme0n1) differs from the committed device (/dev/sda)
  [[ "$output" == *"/dev/nvme0n1"* ]]
}

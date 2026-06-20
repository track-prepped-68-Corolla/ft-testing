#!/usr/bin/env bats
# Unit tests for scripts/lib/preflight.sh

load ../helpers/load

setup() {
  source "${LIB_DIR}/preflight.sh"
  cd "${BATS_TEST_TMPDIR}"
  # A syntactically valid age recipient: age1 + 58 bech32 chars.
  REAL="age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqd2y7gl"
}

@test "is_age_recipient accepts a real recipient" {
  run is_age_recipient "$REAL"
  [ "$status" -eq 0 ]
}

@test "is_age_recipient rejects a placeholder (uppercase/underscores)" {
  run is_age_recipient "age1PLACEHOLDER_LYRA_AGE_PUBKEY"
  [ "$status" -ne 0 ]
}

@test "is_age_recipient rejects empty and non-age strings" {
  run is_age_recipient ""
  [ "$status" -ne 0 ]
  run is_age_recipient "ssh-ed25519 AAAAC3"
  [ "$status" -ne 0 ]
}

@test "sops_host_recipient extracts the key anchored to &<name>" {
  cat > .sops.yaml <<EOF
keys:
  - &strix ${REAL}
  - &lyra    age1PLACEHOLDER_LYRA_AGE_PUBKEY
EOF
  [ "$(sops_host_recipient .sops.yaml strix)" = "$REAL" ]
  [ "$(sops_host_recipient .sops.yaml lyra)" = "age1PLACEHOLDER_LYRA_AGE_PUBKEY" ]
  [ -z "$(sops_host_recipient .sops.yaml mimir)" ]
}

@test "sops_recipient_ok: valid passes, placeholder and missing fail" {
  cat > .sops.yaml <<EOF
keys:
  - &strix ${REAL}
  - &lyra age1PLACEHOLDER_LYRA_AGE_PUBKEY
EOF
  run sops_recipient_ok .sops.yaml strix
  [ "$status" -eq 0 ]
  run sops_recipient_ok .sops.yaml lyra
  [ "$status" -ne 0 ]
  run sops_recipient_ok .sops.yaml mimir
  [ "$status" -ne 0 ]
}

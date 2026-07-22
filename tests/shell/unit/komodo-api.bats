#!/usr/bin/env bats
# Unit tests for scripts/lib/komodo-api.sh — the curl+jq Komodo API driver.
# curl is mocked (via setup_mockbin); jq runs for real.

load ../helpers/load

setup() {
  source "${LIB_DIR}/komodo-api.sh"
  cd "${BATS_TEST_TMPDIR}"
  setup_mockbin
}

# A curl mock that logs the request (all args, incl. the -d body) to reqs and
# replies with RESP_BODY + RESP_CODE, mirroring komodo_api's `-w '\n%{http_code}'`
# (body then a trailing line with the status).
mock_curl_static() {
  mock curl \
    'printf "%s\n" "$*" >> "$BATS_TEST_TMPDIR/reqs"' \
    'printf "%s\n%s" "$RESP_BODY" "$RESP_CODE"'
}

@test "komodo_api returns the body on a 2xx response" {
  export RESP_BODY='{"ok":true}' RESP_CODE=200
  mock_curl_static
  run komodo_api http://c:9120 K S read '{"type":"X","params":{}}'
  [ "$status" -eq 0 ]
  [ "$output" = '{"ok":true}' ]
}

@test "komodo_api fails and reports the status on a non-2xx response" {
  export RESP_BODY='{"error":"nope"}' RESP_CODE=403
  mock_curl_static
  run komodo_api http://c:9120 K S read '{}'
  [ "$status" -ne 0 ]
  [[ "$output" == *"HTTP 403"* ]]
}

@test "komodo_find_sync_id returns the id of the matching sync" {
  export RESP_BODY='[{"name":"a","id":"1"},{"name":"target","id":"xyz"}]' RESP_CODE=200
  mock_curl_static
  run komodo_find_sync_id http://c:9120 K S target
  [ "$status" -eq 0 ]
  [ "$output" = "xyz" ]
}

@test "komodo_find_sync_id emits nothing when no sync matches" {
  export RESP_BODY='[{"name":"a","id":"1"}]' RESP_CODE=200
  mock_curl_static
  run komodo_find_sync_id http://c:9120 K S missing
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "komodo_ensure_sync updates in place when the sync already exists" {
  export RESP_BODY='[{"name":"s","id":"id1"}]' RESP_CODE=200
  mock_curl_static
  run komodo_ensure_sync http://c:9120 K S s '{"repo":"o/r"}'
  [ "$status" -eq 0 ]
  [ "$output" = "id1" ]
  grep -q 'UpdateResourceSync' "$BATS_TEST_TMPDIR/reqs"
  grep -q '"id":"id1"' "$BATS_TEST_TMPDIR/reqs"
}

@test "komodo_ensure_sync creates when the sync is absent" {
  # First call (ListResourceSyncs) returns empty; second (CreateResourceSync)
  # returns the created resource with its new id.
  mock curl '
    n=$(cat "$BATS_TEST_TMPDIR/n" 2>/dev/null || echo 0); n=$((n + 1))
    echo "$n" > "$BATS_TEST_TMPDIR/n"
    printf "%s\n" "$*" >> "$BATS_TEST_TMPDIR/reqs"
    if [ "$n" -eq 1 ]; then printf "%s\n%s" "[]" "200"; else printf "%s\n%s" "{\"id\":\"new9\"}" "200"; fi'
  run komodo_ensure_sync http://c:9120 K S s '{"repo":"o/r"}'
  [ "$status" -eq 0 ]
  [ "$output" = "new9" ]
  grep -q 'CreateResourceSync' "$BATS_TEST_TMPDIR/reqs"
  grep -q '"name":"s"' "$BATS_TEST_TMPDIR/reqs"
}

@test "komodo_run_sync posts RunSync with the sync id" {
  export RESP_BODY='{}' RESP_CODE=200
  mock_curl_static
  run komodo_run_sync http://c:9120 K S sync42
  [ "$status" -eq 0 ]
  grep -q '"type":"RunSync"' "$BATS_TEST_TMPDIR/reqs"
  grep -q '"sync":"sync42"' "$BATS_TEST_TMPDIR/reqs"
}

@test "komodo_deploy_stack posts DeployStack with the stack name" {
  export RESP_BODY='{}' RESP_CODE=200
  mock_curl_static
  run komodo_deploy_stack http://c:9120 K S media
  [ "$status" -eq 0 ]
  grep -q '"type":"DeployStack"' "$BATS_TEST_TMPDIR/reqs"
  grep -q '"stack":"media"' "$BATS_TEST_TMPDIR/reqs"
}

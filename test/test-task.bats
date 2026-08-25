#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  MOCK_DIR="$BATS_TEST_TMPDIR/test-runner-bin"
  BATS_LOG="$BATS_TEST_TMPDIR/bats.log"
  mkdir -p "$MOCK_DIR"
  export BATS_LOG

  cat > "$MOCK_DIR/bats" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'jobs=%s\n' "${BATS_NUMBER_OF_PARALLEL_JOBS:-}"
  printf 'runner=%s\n' "${BATS_PARALLEL_BINARY_NAME:-}"
  for argument in "$@"; do
    printf 'arg=%s\n' "$argument"
  done
} > "$BATS_LOG"
SH

  cat > "$MOCK_DIR/rush" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  chmod +x "$MOCK_DIR/bats" "$MOCK_DIR/rush"
  export BATS_COMMAND="$MOCK_DIR/bats"
  export RUSH_COMMAND="$MOCK_DIR/rush"
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME
}

log_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key { print substr($0, length(key) + 2); exit }' "$BATS_LOG"
}

arg_count() {
  local expected="$1"
  awk -F= -v expected="$expected" '$1 == "arg" && substr($0, 5) == expected { count++ } END { print count + 0 }' "$BATS_LOG"
}

@test "test task selects Rush and preserves complete arguments" {
  run wallpapers test --filter resolution common
  [ "$status" -eq 0 ]
  [[ "$output" == *"4 jobs via"* ]]
  [ "$(log_value jobs)" = "4" ]
  [ "$(log_value runner)" = "$MOCK_DIR/rush" ]
  [ "$(arg_count --no-parallelize-within-files)" -eq 0 ]
  [ "$(arg_count --print-output-on-failure)" -eq 1 ]
  [ "$(arg_count --filter)" -eq 1 ]
  [ "$(arg_count resolution)" -eq 1 ]
  [ "$(arg_count "$REPO_ROOT/test/common.bats")" -eq 1 ]
  if [[ "$REPO_ROOT" =~ [[:space:]] ]]; then
    [ "$(arg_count --no-parallelize-across-files)" -eq 1 ]
  else
    [ "$(arg_count --no-parallelize-across-files)" -eq 0 ]
  fi

  run wallpapers test --jobs 4 --filter "resolution output" common
  [ "$status" -eq 0 ]
  [ "$(arg_count --jobs)" -eq 1 ]
  [ "$(arg_count 4)" -eq 1 ]
  [ "$(arg_count "resolution output")" -eq 1 ]
  [ "$(arg_count --no-parallelize-across-files)" -eq 1 ]
}

@test "explicit serial execution does not require Rush" {
  export RUSH_COMMAND="$MOCK_DIR/missing-rush"

  run wallpapers test --jobs 1 common
  [ "$status" -eq 0 ]
  [[ "$output" == *"BATS parallelism: serial"* ]]
  [ "$(arg_count --no-parallelize-within-files)" -eq 0 ]
}

@test "serial test path preserves a target containing whitespace" {
  probe_dir="$BATS_TEST_TMPDIR/serial probe"
  mkdir -p "$probe_dir"
  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"serial probe passes\" {"
    printf '%s\n' '  true' '}'
  } > "$probe_dir/passing test.bats"

  unset BATS_COMMAND RUSH_COMMAND
  BATS_PARALLEL_BINARY_NAME=missing \
    run wallpapers test --jobs 1 "$probe_dir/passing test.bats"

  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
}

@test "parallel execution fails clearly without the selected runner" {
  export RUSH_COMMAND="$MOCK_DIR/missing-rush"

  run -127 wallpapers test common
  [ "$status" -eq 127 ]
  [[ "$output" == *"parallel runner '$MOCK_DIR/missing-rush' is unavailable for 4 jobs"* ]]
  [ ! -e "$BATS_LOG" ]
}

@test "invalid job count fails before BATS" {
  export BATS_NUMBER_OF_PARALLEL_JOBS=lots

  run -2 wallpapers test common
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be a positive integer"* ]]
  [ ! -e "$BATS_LOG" ]
}

@test "whitespace fallback retains within-file concurrency" {
  probe_dir="$BATS_TEST_TMPDIR/within file probe"
  export PROBE_DIR="$BATS_TEST_TMPDIR/within-file-barrier"
  mkdir -p "$probe_dir" "$PROBE_DIR"

  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"first test observes second test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/one"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/two" ] || return 0
    sleep 0.05
  done
  false
}
BATS
    printf '%s\n' "$test_keyword \"second test observes first test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/two"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/one" ] || return 0
    sleep 0.05
  done
  false
}
BATS
  } > "$probe_dir/within-file.bats"

  unset BATS_COMMAND RUSH_COMMAND
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME

  run wallpapers test --jobs 4 "$probe_dir/within-file.bats"

  [ "$status" -eq 0 ]
  [[ "$output" == *"4 jobs via rush"* ]]
}

@test "normal paths retain across-file concurrency" {
  probe_dir="$BATS_TEST_TMPDIR/across-file-probe"
  export PROBE_DIR="$BATS_TEST_TMPDIR/across-file-barrier"
  if [[ "$REPO_ROOT" =~ [[:space:]] || "$probe_dir" =~ [[:space:]] ]]; then
    skip "bounded whitespace fallback intentionally disables across-file scheduling"
  fi
  mkdir -p "$probe_dir" "$PROBE_DIR"

  test_keyword='@test'
  for side in one two; do
    other=one
    [ "$side" = one ] && other=two
    {
      printf '%s\n' '#!/usr/bin/env bats'
      printf '%s\n' "$test_keyword \"$side observes $other\" {"
      printf '  touch "$PROBE_DIR/%s"\n' "$side"
      printf '%s\n' '  for _ in {1..50}; do'
      printf '    [ ! -e "$PROBE_DIR/%s" ] || return 0\n' "$other"
      printf '%s\n' '    sleep 0.05' '  done' '  false' '}'
    } > "$probe_dir/$side.bats"
  done

  unset BATS_COMMAND RUSH_COMMAND
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_PARALLEL_BINARY_NAME

  run wallpapers test --jobs 4 "$probe_dir/one.bats" "$probe_dir/two.bats"

  [ "$status" -eq 0 ]
}

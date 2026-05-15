#!/usr/bin/env bats

setup() {
  load test_helper
  CALLER_PWD="$BATS_TEST_TMPDIR/workspace"
  export CALLER_PWD
  mkdir -p "$CALLER_PWD"
  setup_apply_mocks
}

setup_apply_mocks() {
  MOCK_SPACE_COUNT="$BATS_TEST_TMPDIR/space-count"
  MOCK_BUTTHAIR_LOG="$BATS_TEST_TMPDIR/butthair.log"
  MOCK_OSASCRIPT_LOG="$BATS_TEST_TMPDIR/osascript.log"
  MOCK_GENERATED_DIR="$BATS_TEST_TMPDIR/generated"
  export MOCK_SPACE_COUNT MOCK_BUTTHAIR_LOG MOCK_OSASCRIPT_LOG MOCK_GENERATED_DIR
  printf '1\n' > "$MOCK_SPACE_COUNT"
  : > "$MOCK_BUTTHAIR_LOG"
  : > "$MOCK_OSASCRIPT_LOG"
  mkdir -p "$MOCK_GENERATED_DIR"

  BUTTHAIR="$BATS_TEST_TMPDIR/butthair"
  GUM="$BATS_TEST_TMPDIR/gum"
  SWIFT="$BATS_TEST_TMPDIR/swift"
  OSASCRIPT="$BATS_TEST_TMPDIR/osascript"
  SYSTEM_PROFILER="$BATS_TEST_TMPDIR/system_profiler"
  PGREP="$BATS_TEST_TMPDIR/pgrep"
  HS_CLI="$BATS_TEST_TMPDIR/hs"
  export BUTTHAIR GUM SWIFT OSASCRIPT SYSTEM_PROFILER PGREP HS_CLI

  cat > "$BUTTHAIR" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${MOCK_BUTHAIR_LOG:-${MOCK_BUTTHAIR_LOG:?}}"
count=$(cat "${MOCK_SPACE_COUNT:?}")
spaces_json() {
  local n="$1"
  printf '['
  local i=1
  while [ "$i" -le "$n" ]; do
    [ "$i" -gt 1 ] && printf ','
    printf '{"id":%s,"active":%s,"type":"user","index":%s}' "$((1000 + i))" "$([ "$i" -eq 1 ] && echo true || echo false)" "$i"
    i=$((i + 1))
  done
  printf ']\n'
}
case "${1:-}" in
  "spaces:list")
    spaces_json "$count"
    ;;
  "spaces:add")
    if [ -n "${MOCK_ADD_ERROR_ONCE:-}" ] && [ ! -f "${MOCK_ADD_ERROR_ONCE}.used" ]; then
      : > "${MOCK_ADD_ERROR_ONCE}.used"
      echo "error: unable to get Mission Control data from the Dock"
      exit 0
    fi
    count=$((count + 1))
    printf '%s\n' "$count" > "${MOCK_SPACE_COUNT:?}"
    echo "added space #$count (id=$((1000 + count)))"
    ;;
  "spaces:current")
    echo "1"
    ;;
  "spaces:goto")
    target=""
    for arg in "$@"; do target="$arg"; done
    echo "switched to space #$target"
    ;;
  "screen:info")
    echo '{"usable":{"w":1200,"h":800,"y":24}}'
    ;;
  "windows:close")
    target=""
    for arg in "$@"; do target="$arg"; done
    echo "closed $target"
    ;;
  *)
    echo "unexpected butthair call: $*" >&2
    exit 99
    ;;
esac
BASH

  cat > "$GUM" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  style)
    shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --foreground|--border|--padding|--margin|--align|--width)
          shift 2
          ;;
        --bold|--print|--)
          shift
          ;;
        *)
          printf '%s ' "$1"
          shift
          ;;
      esac
    done
    printf '\n'
    ;;
  confirm)
    echo "unexpected interactive confirmation: ${*:2}" >&2
    exit 99
    ;;
  *)
    echo "unexpected gum call: $*" >&2
    exit 99
    ;;
esac
BASH

  cat > "$SWIFT" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
config=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--config" ]; then
    shift
    config="$1"
  fi
  shift || true
done
count=$(jq 'if .spaces then .spaces | length elif .workspaces then .workspaces | length else 0 end' "$config")
mkdir -p "${MOCK_GENERATED_DIR:?}"
i=1
while [ "$i" -le "$count" ]; do
  file="$MOCK_GENERATED_DIR/wallpaper-$i.png"
  printf 'png-%s\n' "$i" > "$file"
  echo "[$i/$count] Generating: test-$i"
  echo "FILE:$file"
  i=$((i + 1))
done
echo "MODE:apply"
BASH

  cat > "$OSASCRIPT" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${MOCK_OSASCRIPT_LOG:?}"
BASH

  cat > "$SYSTEM_PROFILER" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
echo '    Resolution: 1920 x 1080 Retina'
BASH

  cat > "$PGREP" <<'BASH'
#!/usr/bin/env bash
exit 0
BASH

  cat > "$HS_CLI" <<'BASH'
#!/usr/bin/env bash
exit 0
BASH

  chmod +x "$BUTTHAIR" "$GUM" "$SWIFT" "$OSASCRIPT" "$SYSTEM_PROFILER" "$PGREP" "$HS_CLI"
}

write_spaces_config() {
  local path="$1"
  local count="$2"
  {
    printf '{"schemaVersion":1,"spaces":['
    local i=1
    while [ "$i" -le "$count" ]; do
      [ "$i" -gt 1 ] && printf ','
      printf '{"name":"space-%s","zones":[{"name":"zone-%s"}]}' "$i" "$i"
      i=$((i + 1))
    done
    printf '],"defaults":{"bgColor":"#000000","textColor":"#ffffff"}}\n'
  } > "$path"
}

@test "apply refuses to add Spaces non-interactively without --yes" {
  config="$CALLER_PWD/two-spaces.json"
  write_spaces_config "$config" 2
  printf '1\n' > "$MOCK_SPACE_COUNT"

  run wallpapers apply --config "$config" --wallpapers

  [ "$status" -eq 2 ]
  [[ "$output" == *"Confirmation required"* ]]
  [[ "$output" == *"Re-run with --yes (or -y)"* ]]
  [ "$(cat "$MOCK_SPACE_COUNT")" = "1" ]
  if grep -q "spaces:add" "$MOCK_BUTTHAIR_LOG"; then
    echo "unexpected spaces:add call" >&2
    return 1
  fi
}

@test "apply --yes adds missing Spaces before applying wallpapers" {
  config="$CALLER_PWD/three-spaces.json"
  write_spaces_config "$config" 3
  printf '1\n' > "$MOCK_SPACE_COUNT"

  run wallpapers apply --config "$config" --wallpapers --yes

  [ "$status" -eq 0 ]
  [[ "$output" == *"added space 1/2"* ]]
  [[ "$output" == *"added space 2/2"* ]]
  [[ "$output" == *"Wallpapers applied"* ]]
  [ "$(cat "$MOCK_SPACE_COUNT")" = "3" ]
  [ "$(grep -c '^spaces:add$' "$MOCK_BUTTHAIR_LOG")" = "2" ]
  grep -q "spaces:goto -- 1" "$MOCK_BUTTHAIR_LOG"
  grep -q "spaces:goto -- 2" "$MOCK_BUTTHAIR_LOG"
  grep -q "spaces:goto -- 3" "$MOCK_BUTTHAIR_LOG"
  [ "$(wc -l < "$MOCK_OSASCRIPT_LOG" | tr -d ' ')" = "3" ]
}

@test "apply -y continues non-interactively with extra Spaces" {
  config="$CALLER_PWD/one-space.json"
  write_spaces_config "$config" 1
  printf '2\n' > "$MOCK_SPACE_COUNT"

  run wallpapers apply --config "$config" --wallpapers -y

  [ "$status" -eq 0 ]
  [[ "$output" == *"leave 1 extra Space(s) unchanged"* ]]
  [[ "$output" == *"Wallpapers applied"* ]]
  if grep -q "spaces:add" "$MOCK_BUTTHAIR_LOG"; then
    echo "unexpected spaces:add call" >&2
    return 1
  fi
  [ "$(wc -l < "$MOCK_OSASCRIPT_LOG" | tr -d ' ')" = "1" ]
}

@test "apply fails when spaces:add returns an error string" {
  config="$CALLER_PWD/two-spaces.json"
  write_spaces_config "$config" 2
  printf '1\n' > "$MOCK_SPACE_COUNT"
  MOCK_ADD_ERROR_ONCE="$BATS_TEST_TMPDIR/add-error"
  export MOCK_ADD_ERROR_ONCE

  run wallpapers apply --config "$config" --wallpapers --yes

  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to add Space 1/1"* ]]
  [[ "$output" == *"error: unable to get Mission Control data from the Dock"* ]]
  [ "$(cat "$MOCK_SPACE_COUNT")" = "1" ]
  [ ! -s "$MOCK_OSASCRIPT_LOG" ]
}

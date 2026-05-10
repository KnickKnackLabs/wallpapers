#!/usr/bin/env bats

setup() {
  load test_helper
  CALLER_PWD="$BATS_TEST_TMPDIR/workspace"
  export CALLER_PWD
  mkdir -p "$CALLER_PWD"
  setup_mock_butthair
}

setup_mock_butthair() {
  MOCK_SPACES_JSON="$BATS_TEST_TMPDIR/spaces.json"
  MOCK_WINDOWS_JSON="$BATS_TEST_TMPDIR/windows.json"
  export MOCK_SPACES_JSON MOCK_WINDOWS_JSON

  cat > "$MOCK_SPACES_JSON" <<'JSON'
[
  { "id": 3, "active": false, "type": "user", "index": 1 },
  { "id": 712, "active": true, "type": "user", "index": 2 }
]
JSON

  cat > "$MOCK_WINDOWS_JSON" <<'JSON'
[
  { "spaces": [2], "app": "Obsidian", "title": "New tab - home", "visible": true, "id": 95481 },
  { "spaces": [2], "app": "Ghostty", "title": "π - fold", "visible": true, "id": 25033 },
  { "spaces": [1], "app": "Firefox", "title": "Roundcube Webmail", "visible": false, "id": 87120 }
]
JSON

  BUTTHAIR="$BATS_TEST_TMPDIR/butthair"
  export BUTTHAIR
  cat > "$BUTTHAIR" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  "spaces:list")
    cat "${MOCK_SPACES_JSON:?}"
    ;;
  "windows:list")
    cat "${MOCK_WINDOWS_JSON:?}"
    ;;
  *)
    echo "unexpected butthair call: $*" >&2
    exit 99
    ;;
esac
BASH
  chmod +x "$BUTTHAIR"
}

@test "snapshot writes WALLPAPERS.tsx in caller directory" {
  run wallpapers snapshot

  [ "$status" -eq 0 ]
  [[ "$output" == *"out:    $CALLER_PWD/WALLPAPERS.tsx"* ]]
  [[ "$output" == *"wrote $CALLER_PWD/WALLPAPERS.tsx"* ]]
  [ -f "$CALLER_PWD/WALLPAPERS.tsx" ]

  run grep -F "macOS space #2, id=712, type=user, active" "$CALLER_PWD/WALLPAPERS.tsx"
  [ "$status" -eq 0 ]

  run wallpapers build

  [ "$status" -eq 0 ]
  run jq -r '.spaces | length' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "2" ]
  run jq -r '.spaces[1].zones[0].name' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "space-2" ]
}

@test "snapshot --json emits normalized snapshot without writing TSX" {
  run wallpapers snapshot --json

  [ "$status" -eq 0 ]
  [ ! -e "$CALLER_PWD/WALLPAPERS.tsx" ]

  snapshot_json="$output"
  run jq -r '.snapshotVersion' <<< "$snapshot_json"
  [ "$output" = "1" ]
  run jq -r '.spaces[1].active' <<< "$snapshot_json"
  [ "$output" = "true" ]
  run jq -r '.spaces[0].id' <<< "$snapshot_json"
  [ "$output" = "3" ]
}

@test "snapshot refuses to overwrite unless --force is passed" {
  echo "existing" > "$CALLER_PWD/WALLPAPERS.tsx"

  run wallpapers snapshot

  [ "$status" -ne 0 ]
  [[ "$output" == *"output already exists"* ]]
  [ "$(cat "$CALLER_PWD/WALLPAPERS.tsx")" = "existing" ]

  run wallpapers snapshot --force

  [ "$status" -eq 0 ]
  run grep -F "<WorkspaceSet" "$CALLER_PWD/WALLPAPERS.tsx"
  [ "$status" -eq 0 ]
}

@test "snapshot accepts an explicit output path relative to caller" {
  run wallpapers snapshot --out recipes/current.tsx

  [ "$status" -eq 0 ]
  [ -f "$CALLER_PWD/recipes/current.tsx" ]
  [ ! -e "$CALLER_PWD/WALLPAPERS.tsx" ]
}

@test "snapshot --include-windows includes window data in comments and JSON" {
  run wallpapers snapshot --include-windows

  [ "$status" -eq 0 ]
  run grep -F "Obsidian — New tab - home" "$CALLER_PWD/WALLPAPERS.tsx"
  [ "$status" -eq 0 ]
  run grep -F "Firefox — Roundcube Webmail (hidden)" "$CALLER_PWD/WALLPAPERS.tsx"
  [ "$status" -eq 0 ]

  run wallpapers build
  [ "$status" -eq 0 ]

  rm "$CALLER_PWD/WALLPAPERS.tsx"
  run wallpapers snapshot --json --include-windows

  [ "$status" -eq 0 ]
  snapshot_json="$output"
  run jq -r '.spaces[1].windows | length' <<< "$snapshot_json"
  [ "$output" = "2" ]
  run jq -r '.spaces[1].windows[0].app' <<< "$snapshot_json"
  [ "$output" = "Ghostty" ]
}


@test "snapshot ignores inherited usage variables from parent mise sessions" {
  usage_json=true usage_out=stale.tsx usage_force=true usage_include_windows=true run wallpapers snapshot

  [ "$status" -eq 0 ]
  [[ "$output" == *"out:    $CALLER_PWD/WALLPAPERS.tsx"* ]]
  [ -f "$CALLER_PWD/WALLPAPERS.tsx" ]
  run grep -F "windows:" "$CALLER_PWD/WALLPAPERS.tsx"
  [ "$status" -ne 0 ]
}

@test "snapshot --json rejects output flags" {
  run wallpapers snapshot --json --out current.tsx

  [ "$status" -eq 2 ]
  [[ "$output" == *"--json cannot be combined"* ]]
}

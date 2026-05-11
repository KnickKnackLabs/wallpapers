#!/usr/bin/env bats

setup() {
  load test_helper
  CALLER_PWD="$BATS_TEST_TMPDIR/workspace"
  export CALLER_PWD
  mkdir -p "$CALLER_PWD"
}

write_recipe() {
  cat > "$CALLER_PWD/WALLPAPERS.tsx" <<'TSX'
import { WorkspaceSet, Space, Zone } from "wallpapers";

export default (
  <WorkspaceSet name="agents" defaults={{ bgColor: "#000000", textColor: "#ffffff" }}>
    <Space name="quad" id="quad" gap={12}>
      <Zone name="quick" id="quick" flex={2} bgColor="#111111" description={process.cwd()} />
      <Zone name="brownie" id="brownie" bgColor="#222222" />
    </Space>
  </WorkspaceSet>
);
TSX
}

@test "build compiles WALLPAPERS.tsx in caller directory" {
  write_recipe

  run wallpapers build

  [ "$status" -eq 0 ]
  [[ "$output" == *"source: $CALLER_PWD/WALLPAPERS.tsx"* ]]
  [[ "$output" == *"out:    $CALLER_PWD/WALLPAPERS.json"* ]]
  [ -f "$CALLER_PWD/WALLPAPERS.json" ]

  run jq -r '.schemaVersion' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "1" ]

  run jq -r '.name' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "agents" ]

  run jq -r '.spaces[0].zones[0].name' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "quick" ]

  run jq -r '.spaces[0].zones[0].flex' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "2" ]

  expected_cwd=$(cd "$CALLER_PWD" && pwd -P)
  run jq -r '.spaces[0].zones[0].description' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "$expected_cwd" ]
}

@test "build --check passes when output is current" {
  write_recipe
  wallpapers build

  run wallpapers build --check

  [ "$status" -eq 0 ]
  [[ "$output" == *"is up to date"* ]]
}

@test "build --check fails when output is missing" {
  write_recipe

  run wallpapers build --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"WALLPAPERS.json is missing"* ]]
}

@test "build ignores inherited usage variables from parent mise sessions" {
  write_recipe

  usage_check=true usage_out=stale.json usage_source=missing.tsx run wallpapers build

  [ "$status" -eq 0 ]
  [[ "$output" == *"source: $CALLER_PWD/WALLPAPERS.tsx"* ]]
  [[ "$output" == *"out:    $CALLER_PWD/WALLPAPERS.json"* ]]
  [ -f "$CALLER_PWD/WALLPAPERS.json" ]
  [ ! -e "$CALLER_PWD/stale.json" ]
}

@test "build accepts explicit source and output paths relative to caller" {
  mkdir -p "$CALLER_PWD/recipes"
  cat > "$CALLER_PWD/recipes/small.tsx" <<'TSX'
import { WorkspaceSet, Space, Zone } from "wallpapers";

export default (
  <WorkspaceSet name="small">
    <Space name="solo">
      <Zone name="one" />
    </Space>
  </WorkspaceSet>
);
TSX

  run wallpapers build --source recipes/small.tsx --out .wallpapers/small.json

  [ "$status" -eq 0 ]
  [ -f "$CALLER_PWD/.wallpapers/small.json" ]

  run jq -r '.spaces[0].zones[0].name' "$CALLER_PWD/.wallpapers/small.json"
  [ "$output" = "one" ]
}

@test "build passes remaining arguments to WALLPAPERS.tsx" {
  cat > "$CALLER_PWD/WALLPAPERS.tsx" <<'TSX'
import { parseArgs } from "util";
import { WorkspaceSet, Space, Zone } from "wallpapers";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    set: { type: "string", default: "quick" },
  },
  strict: true,
});

const sets = {
  quick: (
    <WorkspaceSet name="quick">
      <Space name="quick"><Zone name="quick" /></Space>
    </WorkspaceSet>
  ),
  brownie: (
    <WorkspaceSet name="brownie">
      <Space name="brownie"><Zone name="brownie" /></Space>
    </WorkspaceSet>
  ),
};

export default sets[values.set as keyof typeof sets];
TSX

  run wallpapers build --set brownie

  [ "$status" -eq 0 ]
  run jq -r '.name' "$CALLER_PWD/WALLPAPERS.json"
  [ "$output" = "brownie" ]
}

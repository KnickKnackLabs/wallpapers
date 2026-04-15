#!/usr/bin/env bats

setup() {
  load test_helper
}

# --- Path constants ---

@test "WALLPAPERS_OUTPUT_DIR points to ~/.local/share/wallpapers" {
  [[ "$WALLPAPERS_OUTPUT_DIR" == "$HOME/.local/share/wallpapers" ]]
}

@test "WALLPAPERS_CONFIG_FILE points to ~/.config/wallpapers/config.json" {
  [[ "$WALLPAPERS_CONFIG_FILE" == "$HOME/.config/wallpapers/config.json" ]]
}

@test "WALLPAPERS_STATE_DIR points to ~/.local/state/wallpapers" {
  [[ "$WALLPAPERS_STATE_DIR" == "$HOME/.local/state/wallpapers" ]]
}

# --- resolution helpers ---

@test "resolution_width extracts width from WxH" {
  run resolution_width "3024x1964"
  [[ "$output" == "3024" ]]
}

@test "resolution_height extracts height from WxH" {
  run resolution_height "3024x1964"
  [[ "$output" == "1964" ]]
}

@test "resolution_width handles 1080p" {
  run resolution_width "1920x1080"
  [[ "$output" == "1920" ]]
}

@test "resolution_height handles 1080p" {
  run resolution_height "1920x1080"
  [[ "$output" == "1080" ]]
}

# --- detect_screen_resolution ---

@test "detect_screen_resolution returns a WxH string on macOS" {
  # Skip if not on macOS (no system_profiler)
  command -v system_profiler &>/dev/null || skip "not macOS"
  run detect_screen_resolution
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ ^[0-9]+x[0-9]+$ ]]
}

# --- require_command ---

@test "require_command succeeds for an installed command" {
  run require_command bash
  [[ "$status" -eq 0 ]]
}

@test "require_command fails for a missing command" {
  run require_command nonexistent_cmd_xyz
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"not found"* ]]
}

@test "require_command includes install hint in error" {
  run require_command nonexistent_cmd_xyz "Install with: brew install xyz"
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Install with: brew install xyz"* ]]
}

# --- require_config ---

@test "require_config fails when config does not exist" {
  WALLPAPERS_CONFIG_FILE="$BATS_TEST_TMPDIR/nonexistent.json"
  run require_config
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Config not found"* ]]
}

@test "require_config succeeds when config exists" {
  create_test_config
  run require_config
  [[ "$status" -eq 0 ]]
}

# --- test config fixture ---

@test "create_test_config creates valid JSON with 3 workspaces" {
  create_test_config
  [[ -f "$WALLPAPERS_CONFIG_FILE" ]]
  run jq '.workspaces | length' "$WALLPAPERS_CONFIG_FILE"
  [[ "$output" == "3" ]]
}

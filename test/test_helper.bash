#!/usr/bin/env bash
# Common test fixtures for wallpapers BATS tests.

# Repo root — derive from the test file's own path.
# Do not read MISE_CONFIG_ROOT here; agent shells inherit it from the launcher.
REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Source shared library
source "$REPO_ROOT/lib/common.sh"

# Create a minimal config file in a temp directory.
# Sets WALLPAPERS_CONFIG_FILE and WALLPAPERS_CONFIG_DIR for the test.
create_test_config() {
  local config_dir="$BATS_TEST_TMPDIR/config/wallpapers"
  mkdir -p "$config_dir"
  WALLPAPERS_CONFIG_DIR="$config_dir"
  WALLPAPERS_CONFIG_FILE="$config_dir/config.json"
  cat > "$WALLPAPERS_CONFIG_FILE" <<'JSON'
{
  "workspaces": [
    { "name": "Personal", "bgColor": "#2d3436" },
    { "name": "Code", "bgColor": "#1a1a2e" },
    { "name": "Design", "id": "design", "bgColor": "#0f3460" }
  ],
  "defaults": {
    "bgColor": "#000000",
    "textColor": "#ffffff"
  }
}
JSON
}

# Create a temp output directory for generated wallpapers.
create_test_output_dir() {
  WALLPAPERS_OUTPUT_DIR="$BATS_TEST_TMPDIR/wallpapers"
  mkdir -p "$WALLPAPERS_OUTPUT_DIR"
}

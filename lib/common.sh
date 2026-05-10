#!/usr/bin/env bash
# Shared constants and helpers for wallpapers tasks.

# Paths
WALLPAPERS_OUTPUT_DIR="$HOME/.local/share/wallpapers"
WALLPAPERS_CONFIG_DIR="$HOME/.config/wallpapers"
WALLPAPERS_CONFIG_FILE="$WALLPAPERS_CONFIG_DIR/config.json"
WALLPAPERS_STATE_DIR="$HOME/.local/state/wallpapers"

# Return the directory where the user invoked wallpapers.
# New shiv shims export WALLPAPERS_CALLER_PWD; older shims exported CALLER_PWD.
wallpapers_caller_dir() {
  printf '%s\n' "${WALLPAPERS_CALLER_PWD:-${CALLER_PWD:-$PWD}}"
}

# Resolve a user-provided path relative to the caller directory.
wallpapers_resolve_path() {
  local path="$1"
  case "$path" in
    /*)
      printf '%s\n' "$path"
      ;;
    '~')
      printf '%s\n' "$HOME"
      ;;
    '~'/*)
      printf '%s/%s\n' "$HOME" "${path#~/}"
      ;;
    *)
      printf '%s/%s\n' "$(wallpapers_caller_dir)" "$path"
      ;;
  esac
}

# Detect the primary screen resolution.
# Outputs WxH (e.g. "3024x1964"). Returns 1 if detection fails.
detect_screen_resolution() {
  local res
  res=$(system_profiler SPDisplaysDataType 2>/dev/null \
    | grep -i "Resolution:" \
    | head -1 \
    | sed 's/.*: //' \
    | sed 's/ Retina//' \
    | sed 's/ //g')
  if [[ -z "$res" ]]; then
    echo "error: could not detect screen resolution" >&2
    return 1
  fi
  echo "$res"
}

# Extract width from a WxH resolution string.
resolution_width() {
  echo "${1%%x*}"
}

# Extract height from a WxH resolution string.
resolution_height() {
  echo "${1#*x}"
}

# Check that a command exists, exit with a styled error if not.
# Usage: require_command <cmd> [install hint]
require_command() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" &>/dev/null; then
    if command -v gum &>/dev/null; then
      gum style --foreground 196 "❌ $cmd not found.${hint:+ $hint}"
    else
      echo "error: $cmd not found.${hint:+ $hint}" >&2
    fi
    exit 1
  fi
}

# Check that the config file exists, exit with error if not.
require_config() {
  local config_file="${1:-$WALLPAPERS_CONFIG_FILE}"
  if [[ ! -f "$config_file" ]]; then
    if command -v gum &>/dev/null; then
      gum style --foreground 196 "❌ Config not found. Run: wallpapers config init"
    else
      echo "error: config not found at $config_file" >&2
    fi
    exit 1
  fi
}

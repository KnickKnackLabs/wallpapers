# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wallpapers is a native macOS wallpaper generator that creates labeled wallpapers for workspace/desktop identification. Since macOS doesn't allow naming Spaces/Desktops, this tool generates custom wallpapers with labels to visually identify workspaces.

**Tech stack:** Pure Swift 5.9+ with Core Graphics, bash task scripts, gum for CLI interactions, mise for task orchestration. Zero external dependencies for core functionality. macOS 13+ required.

## Common Commands

All commands can be run via `mise run <task>` or globally via `wp <task>` (after running `mise run install`).

| Command | Purpose |
|---------|---------|
| `mise run quick` | Default task - quick generate with auto-detected resolution, auto-sets wallpaper |
| `mise run generate` | Full interactive generator (colors, resolution, description) |
| `mise run cli "Name" [options]` | Direct CLI without interactive prompts |
| `mise run setup` | Generate wallpapers from config and apply to spaces |
| `mise run setup --generate-only` | Generate wallpapers from config without applying |
| `mise run config:init` | Create starter config at ~/.config/wallpapers/config.json |
| `mise run config:edit` | Open config in $EDITOR |
| `mise run set` | Set wallpaper for current desktop |
| `mise run set:all` | Set wallpaper across all desktops |
| `mise run info:list` | List generated wallpapers |
| `mise run info:space` | Show current desktop number (e.g., "3/5") |
| `mise run info:resolution` | Show screen resolution |
| `mise run clean` | Delete all generated wallpapers |
| `mise run install` | Install global `wp` command to ~/.local/bin |

Direct Swift invocation: `swift src/generate.swift "Name" [options]`

## Architecture

### Core Components

**`src/generate.swift`** - Main wallpaper generator using Core Graphics
- Creates PNG images with text labels
- Supports resolution presets (1080p, 1440p, 4k, macbook-14, macbook-16, imac-24, studio-display) and custom dimensions
- Background/text color customization via hex colors
- RTL/LTR text positioning (Hebrew, Arabic auto-detected)
- Outputs to `output/{name}-{width}x{height}.png`

**`src/current-space.swift`** - Detects current macOS desktop/space number
- Uses private CGS (Core Graphics Server) APIs: `CGSCopyManagedDisplaySpaces()`, `CGSGetActiveSpace()`, `CGSMainConnectionID()`
- Returns "current/total" format (e.g., "3/5")
- Note: Private APIs may break in future macOS versions

**`src/setup.swift`** - Batch wallpaper generator from config
- Reads `~/.config/wallpapers/config.json`
- Generates wallpapers for each workspace by calling generate.swift
- Outputs file paths for the bash wrapper to apply

**`.mise/tasks/`** - File-based bash task definitions
- Each task is a bash script with `#MISE` metadata headers
- Uses gum for interactive prompts (input, choose, confirm, style, spin)
- Auto-discovered by mise

### Data Flow

1. User runs task (e.g., `mise run quick`)
2. Bash task collects input via gum prompts or CLI args
3. Task invokes `swift src/generate.swift` with options
4. Swift generates PNG to `output/` directory
5. Task optionally sets wallpaper via osascript

## Resolution Presets

```
1080p: 1920x1080    macbook-14: 3024x1964
1440p: 2560x1440    macbook-16: 3456x2234
4k: 3840x2160       imac-24: 4480x2520
                    studio-display: 5120x2880
```

## Notes

- No automated test suite - testing is manual through CLI
- macOS-only (AppKit, Core Graphics, osascript)
- Global `wp` command requires ~/.local/bin in PATH

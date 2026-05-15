<!-- Generated from README.tsx — edit that file, then run: mise run readme -->

<div align="center">

# Wallpapers

```
         ▲ ▲
        ╱   ╲
       ╱ ° ° ╲      ╭───╮
      ▕  ───  ▏ ◁━━━│ @ │━╮
       ╲ ╰─╯ ╱      ╰───╯ │
      ╱╱    ╲╲        ◀═══╯
     ╱╱  ╱╲  ╲╲
    ▔▔  ▔▔▔▔  ▔▔
   ZERGLING    TURTLE
               (in peril)
```

**Generate labeled wallpapers for macOS workspaces.**

macOS lets you create multiple desktops ("Spaces") but doesn't let you name them.
This tool generates wallpapers with labels so you can tell them apart.

![lang: Swift + Bash](https://img.shields.io/badge/lang-Swift%20%2B%20Bash-F05138?style=flat&logo=swift&logoColor=white)
[![runtime: mise](https://img.shields.io/badge/runtime-mise-7c3aed?style=flat)](https://mise.jdx.dev)
![tasks: 23](https://img.shields.io/badge/tasks-23-blue?style=flat)
![tests: 33](https://img.shields.io/badge/tests-33-green?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## Quick Start

```bash
# Install
shiv install wallpapers

# Add the wp alias to your shell
eval "$(wallpapers shell)"

# Run the tutorial
wp tutorial
```

## Usage

```bash
wp                # Apply wallpaper (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp snapshot       # Bootstrap WALLPAPERS.tsx from current Spaces
wp build          # Compile WALLPAPERS.tsx to WALLPAPERS.json
wp build --set quick  # Pass arguments to WALLPAPERS.tsx
wp apply --config ./WALLPAPERS.json --wallpapers
wp apply --config ./WALLPAPERS.json --wallpapers --yes  # Add missing Spaces non-interactively
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back to previous workspace
```

## Config

Create your config with `wp config init`, then edit with `wp config edit`:

```json
{
  "workspaces": [
    { "name": "Personal", "bgColor": "#2d3436" },
    { "name": "Code", "bgColor": "#1a1a2e", "description": "Dev environment" },
    { "name": "Design", "bgColor": "#0f3460" }
  ],
  "defaults": {
    "bgColor": "#000000",
    "textColor": "#ffffff"
  }
}
```

The order of workspaces matches your Spaces order (left to right).

For repo-owned recipes, write `WALLPAPERS.tsx`, then run `wp build`. Extra build arguments are forwarded to the TSX file, so a recipe can parse `Bun.argv.slice(2)` and expose variants such as `wp build --set quick`. To start from your current macOS layout, run `wp snapshot`; it writes one starter zone per Space, with optional window comments via `wp snapshot --include-windows`. The generated `WALLPAPERS.json` can be applied explicitly with `wp apply --config ./WALLPAPERS.json --wallpapers`. If the config has more workspaces than macOS has Spaces, `wp apply` can add the missing Spaces after interactive confirmation; headless callers must pass `--yes` (or `-y`) instead of relying on a prompt.

## Resolution presets

Auto-detect is the default. You can also specify a preset with `--resolution`:

| Preset | Dimensions |
| --- | --- |
| `1080p` | 1920×1080 |
| `1440p` | 2560×1440 |
| `4k` | 3840×2160 |
| `macbook-14` | 3024×1964 |
| `macbook-16` | 3456×2234 |
| `imac-24` | 4480×2520 |
| `studio-display` | 5120×2880 |

## All tasks

| Task | Description |
| --- | --- |
| `ai` | Agent instructions for helping users |
| `apply` | Apply workspace config (wallpapers, apps, or both) |
| `apply:undo` | Close windows created by the last 'apply --apps' |
| `build` | Build WALLPAPERS.tsx into a versioned JSON config |
| `clean` | Remove all generated wallpapers |
| `cli` | Run generator directly with arguments |
| `config:edit` | Edit config file in your editor |
| `config:init` | Initialize config file with example workspaces |
| `generate` | Generate a wallpaper interactively |
| `goto` | Switch to a workspace by name |
| `hammerspoon:config` | Install wp workspace integration into Hammerspoon config |
| `help` | Show generator CLI help |
| `info:list` | List generated wallpapers |
| `info:resolution` | Show your screen resolution |
| `info:space` | Show current desktop space |
| `info:wallpaper` | Show current wallpaper file path |
| `lint` | Run codebase convention lints |
| `open` | Open the wallpapers directory in Finder |
| `quick` | Quick generate with just a name (auto-detects screen resolution) |
| `readme` | Regenerate README.md from README.tsx |
| `shell` | Output shell configuration (use with eval) |
| `snapshot` | Snapshot current macOS Spaces into a starter WALLPAPERS.tsx |
| `tutorial` | Interactive tutorial to learn the wallpaper generator |

## Development

```bash
gh repo clone KnickKnackLabs/wallpapers
cd wallpapers && mise trust && mise install
mise run test   # 33 tests
```

**Architecture:** Swift layer (`Sources/WallpaperKit/`) handles Core Graphics rendering. Bash tasks in `.mise/tasks/` handle user interaction via `gum`. Shared helpers live in `lib/common.sh`. Space management delegates to [butthair](https://github.com/KnickKnackLabs/butthair).

<div align="center">

## License

MIT

This README was created using [readme](https://github.com/KnickKnackLabs/readme).

</div>

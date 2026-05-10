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
![tasks: 25](https://img.shields.io/badge/tasks-25-blue?style=flat)
![tests: 18](https://img.shields.io/badge/tests-18-green?style=flat)
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
wp build          # Compile WALLPAPERS.tsx to WALLPAPERS.json
wp apply --config ./WALLPAPERS.json --wallpapers
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

For repo-owned recipes, write `WALLPAPERS.tsx`, then run `wp build`. The generated `WALLPAPERS.json` can be applied explicitly with `wp apply --config ./WALLPAPERS.json --wallpapers`.

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
| `apply:undo` | Close windows created by the last 'apply --apps' |
| `tutorial:apply` | Tutorial: Apply wallpaper to spaces demo |
| `tutorial:navigate` | Tutorial: Workspace navigation demo |
| `tutorial:intro` | Tutorial: Introduction and overview |
| `tutorial:config` | Tutorial: Configuration setup walkthrough |
| `tutorial:generate` | Tutorial: Wallpaper generation demo |
| `tutorial:summary` | Tutorial: Command reference and completion |
| `goto` | Switch to a workspace by name |
| `config:init` | Initialize config file with example workspaces |
| `config:edit` | Edit config file in your editor |
| `shell` | Output shell configuration (use with eval) |
| `quick` | Quick generate with just a name (auto-detects screen resolution) |
| `cli` | Run generator directly with arguments |
| `readme` | Regenerate README.md from README.tsx |
| `info:resolution` | Show your screen resolution |
| `info:list` | List generated wallpapers |
| `info:wallpaper` | Show current wallpaper file path |
| `info:space` | Show current desktop space |
| `clean` | Remove all generated wallpapers |
| `ai` | Agent instructions for helping users |
| `generate` | Generate a wallpaper interactively |
| `build` | Build WALLPAPERS.tsx into a versioned JSON config |
| `hammerspoon:config` | Install wp workspace integration into Hammerspoon config |
| `open` | Open the wallpapers directory in Finder |
| `help` | Show generator CLI help |

## Development

```bash
gh repo clone KnickKnackLabs/wallpapers
cd wallpapers && mise trust && mise install
mise run test   # 18 tests
```

**Architecture:** Swift layer (`Sources/WallpaperKit/`) handles Core Graphics rendering. Bash tasks in `.mise/tasks/` handle user interaction via `gum`. Shared helpers live in `lib/common.sh`. Space management delegates to [butthair](https://github.com/KnickKnackLabs/butthair).

<div align="center">

## License

MIT

This README was created using [readme](https://github.com/KnickKnackLabs/readme).

</div>

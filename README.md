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

Generate labeled wallpapers for macOS workspaces.

**What's a workspace?** macOS lets you create multiple desktops called "Spaces" (swipe left/right with three fingers, or ctrl+←/→). But Apple doesn't let you name them - so this tool generates wallpapers with labels to identify each one.

## Quick Start

```bash
# Install mise (if you don't have it)
curl https://mise.run | sh

# Install wallpapers
git clone https://github.com/KnickKnackLabs/wallpapers.git ~/.local/share/wallpapers
cd ~/.local/share/wallpapers && mise trust && mise install

# Add to your shell config (~/.zshrc or ~/.bashrc)
eval "$(mise -C ~/.local/share/wallpapers run -q shell)"

# Reload shell and run the tutorial
source ~/.zshrc
wp tutorial
```

## Usage

```bash
wp                # Apply wallpaper (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back to previous workspace
```

## Config

Create your config with `wp config:init`, then edit with `wp config:edit`:

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

## Features

- **Native Swift** - Core Graphics rendering, no external dependencies
- **Auto-detect resolution** - Fits your screen perfectly
- **LTR/RTL support** - Works with English, Hebrew, Arabic, etc.
- **Space navigation** - Switch workspaces by name

## Requirements

- macOS 13+
- [mise](https://mise.jdx.dev/) (installs other dependencies automatically)

## All Commands

| Command | Description |
|---------|-------------|
| `wp` | Apply wallpaper (shows picker, or use `--all`) |
| `wp quick` | Quick generate - just enter a name |
| `wp goto [name]` | Switch workspace (picker if no name) |
| `wp goto -` | Go back to previous workspace |
| `wp generate` | Full interactive generator with all options |
| `wp config:init` | Create starter config |
| `wp config:edit` | Open config in editor |
| `wp info:space` | Show current desktop number |
| `wp info:list` | List generated wallpapers |
| `wp clean` | Delete all generated wallpapers |
| `wp tutorial` | Interactive tutorial |

## Advanced

For scripting or direct access:

```bash
swift src/generate.swift "Name" [options]
  -d, --description    Subtitle text
  -r, --resolution     Preset: 1080p, 1440p, 4k, macbook-14, macbook-16, imac-24, studio-display
  --width, --height    Custom dimensions
  --bg-color           Background hex color
  --text-color         Text hex color
```

## License

MIT

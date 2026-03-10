<div align="center">

```
         ▲ ▲
        ╱   ╲
       ╱ ° ° ╲      ╭───╮
      ▕  ───  ▏ ◁━━━│ @ │━╮
       ╲ ╰─╯ ╱      ╰───╯ │
      ╱╱    ╲╲        ◀═══╯
     ╱╱  ╱╲  ╲╲
    ▔▔  ▔▔▔▔  ▔▔
```

# Wallpapers

**A workspace identity system for macOS.**

Generate labeled wallpapers. Navigate desktops by name. Position apps into zones.
All from a single config file.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)](Package.swift)
[![Agent Ready](https://img.shields.io/badge/agent-ready-8A2BE2)](#agent-integration)

</div>

<!-- ┌─────────────────────────────────────────────────────────────────┐
     │  HERO IMAGE                                                    │
     │                                                                │
     │  Generate this by running:                                     │
     │    wp cli "Personal" --bg-color "#2d3436" --style classic      │
     │    wp cli "Code" --bg-color "#1a1a2e" --style diagonal         │
     │    wp cli "Design" --bg-color "#0f3460" --style typography     │
     │    wp cli "Music" --bg-color "#6c5ce7" --style flowfield       │
     │                                                                │
     │  Then stitch them into a single 1400×400 image with a slight  │
     │  perspective tilt (like cards fanning out). Save as:           │
     │    docs/assets/hero.png                                        │
     │                                                                │
     │  Tip: Add a subtle drop shadow under each wallpaper and use   │
     │  a transparent or #0d1117 background to match GitHub dark.     │
     └─────────────────────────────────────────────────────────────────┘ -->

<p align="center">
  <img src="docs/assets/hero.png" alt="Four wallpapers side by side: Personal (classic), Code (diagonal), Design (typography), Music (flowfield)" width="800" />
</p>

<br />

## Why?

macOS lets you create multiple desktops — Apple calls them **Spaces**. You can swipe between them or use `ctrl+←/→`. But Apple doesn't let you name them. After three desktops they all look the same.

This tool generates wallpapers with labels so you always know where you are. But it goes further: it's a full workspace-as-code system with navigation, app layout, and generative art.

<br />

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

<br />

## Usage

```bash
wp                # Apply wallpapers (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back (like cd -)
```

<br />

## Visual Styles

Six built-in styles — from minimal to generative art. Set per-workspace in config or pick interactively with `wp generate`.

<!-- ┌─────────────────────────────────────────────────────────────────┐
     │  STYLE GRID                                                    │
     │                                                                │
     │  Generate all 6 with the same name + color for comparison:     │
     │    for s in classic diagonal tiled typography flowfield         │
     │      perspective; do                                           │
     │      wp cli "Code" --bg-color "#1a1a2e" --style $s \           │
     │        --resolution 1080p --id "style-$s"                      │
     │    done                                                        │
     │                                                                │
     │  Arrange as 3×2 grid, ~400×250 each. Save as:                 │
     │    docs/assets/styles.png                                      │
     │                                                                │
     │  Add style name as a small label below each cell.              │
     └─────────────────────────────────────────────────────────────────┘ -->

<p align="center">
  <img src="docs/assets/styles.png" alt="Grid showing all six visual styles: classic, diagonal, tiled, typography, flowfield, perspective" width="700" />
</p>

<table>
  <tr>
    <td><strong><code>classic</code></strong></td>
    <td>Clean and minimal. Optional watermark and border text.</td>
  </tr>
  <tr>
    <td><strong><code>diagonal</code></strong></td>
    <td>30° diagonal tiling — luxury fashion-brand aesthetic.</td>
  </tr>
  <tr>
    <td><strong><code>tiled</code></strong></td>
    <td>Dense 75° wall-to-wall typography texture.</td>
  </tr>
  <tr>
    <td><strong><code>typography</code></strong></td>
    <td>Scattered multi-layer composition. Design poster feel.</td>
  </tr>
  <tr>
    <td><strong><code>flowfield</code></strong></td>
    <td>Organic noise-driven flowing lines. Topographic texture.</td>
  </tr>
  <tr>
    <td><strong><code>perspective</code></strong></td>
    <td>Experimental ray simulation with obstacle physics.</td>
  </tr>
</table>

> All procedural styles use **seeded randomness** — same workspace name always produces the same output. Deterministic and reproducible.

<br />

## Multi-Zone Layouts

Split a single wallpaper into zones that mirror how you actually use the desktop. Flex proportions, rounded corners, configurable gaps.

<!-- ┌─────────────────────────────────────────────────────────────────┐
     │  MULTI-ZONE IMAGE                                              │
     │                                                                │
     │  Use your config with a 2:1 split space to generate this.     │
     │  Show the wallpaper as it appears on a desktop — ideally      │
     │  inside a macOS window chrome mockup.                          │
     │                                                                │
     │  Save as: docs/assets/multi-zone.png                           │
     └─────────────────────────────────────────────────────────────────┘ -->

<p align="center">
  <img src="docs/assets/multi-zone.png" alt="A wallpaper split into two zones: Code (2/3 width, dark blue) and Browser (1/3 width, navy)" width="700" />
</p>

```json
{
  "spaces": [
    {
      "zones": [
        { "name": "Code", "bgColor": "#1a1a2e", "style": "classic", "flex": 2 },
        { "name": "Browser", "bgColor": "#0f3460", "style": "diagonal", "flex": 1 }
      ],
      "gap": 8,
      "cornerRadius": 10,
      "chromeColor": "#000000"
    }
  ]
}
```

<br />

## Workspace Navigation

Navigate by name, not by swiping. Supports `cd -` to jump back.

```bash
wp goto code       # Jump to "Code" workspace
wp goto            # Show picker
wp goto -          # Back to previous (like cd -)
```

> **Matching:** Workspaces are found by ID, slug, or name (case-insensitive).
> A workspace named `"Skydiving 🪂"` with `"id": "skydiving"` matches `wp goto skydiving`.

<br />

## App Positioning

With [Hammerspoon](https://www.hammerspoon.org/) installed, `wp apply` positions your apps into zones automatically. Your workspace layout becomes code — version it, share it, reproduce it.

```bash
wp apply              # Wallpapers + position apps
wp apply --apps       # Only reposition apps
wp apply:undo         # Undo positioning
```

<!-- ┌─────────────────────────────────────────────────────────────────┐
     │  APP POSITIONING DEMO                                          │
     │                                                                │
     │  Screen recording (GIF or MP4→GIF) showing:                   │
     │  1. Running `wp apply --all`                                   │
     │  2. Wallpapers appearing on each space                        │
     │  3. Apps sliding into position                                │
     │                                                                │
     │  Keep it short (5-8 seconds). Save as:                        │
     │    docs/assets/apply-demo.gif                                  │
     └─────────────────────────────────────────────────────────────────┘ -->

<br />

## Config

Create with `wp config:init`, edit with `wp config:edit`.

<details>
<summary><b>Simple format</b> — one zone per space</summary>

```json
{
  "workspaces": [
    { "name": "Personal", "bgColor": "#2d3436" },
    { "name": "Code", "bgColor": "#1a1a2e", "description": "Dev environment", "style": "diagonal" },
    { "name": "Design", "bgColor": "#0f3460", "style": "typography" },
    { "name": "Skydiving 🪂", "id": "skydiving", "bgColor": "#6c5ce7" }
  ],
  "defaults": {
    "bgColor": "#000000",
    "textColor": "#ffffff",
    "style": "classic"
  }
}
```

</details>

<details>
<summary><b>Full format</b> — multi-zone spaces with app positioning</summary>

```json
{
  "spaces": [
    {
      "zones": [
        {
          "name": "Code",
          "description": "Development",
          "bgColor": "#1a1a2e",
          "style": "classic",
          "watermark": true,
          "flex": 2,
          "apps": ["Code"]
        },
        {
          "name": "Docs",
          "bgColor": "#0f3460",
          "style": "diagonal",
          "flex": 1,
          "apps": ["Safari"]
        }
      ],
      "gap": 8,
      "cornerRadius": 10,
      "chromeColor": "#000000"
    }
  ],
  "defaults": {
    "bgColor": "#000000",
    "textColor": "#ffffff",
    "style": "classic"
  }
}
```

</details>

<details>
<summary><b>Config reference</b></summary>

| Field | Where | Description |
|-------|-------|-------------|
| `name` | zone | Display name on the wallpaper |
| `description` | zone | Subtitle text below the name |
| `bgColor` | zone / defaults | Background hex color (`#RRGGBB`) |
| `textColor` | zone / defaults | Text hex color (`#RRGGBB`) |
| `style` | zone / defaults | Visual style (see [Visual Styles](#visual-styles)) |
| `id` | zone | Override filename slug (for emoji/special char names) |
| `watermark` | zone | Enable center watermark (classic style) |
| `borderText` | zone | Enable border text (classic style) |
| `flex` | zone | Width proportion in multi-zone layouts |
| `apps` | zone | Apps to position in this zone |
| `gap` | space | Pixel gap between zones |
| `cornerRadius` | space | Rounded corner radius for zones |
| `chromeColor` | space | Background color visible in gaps |

**Location:** `~/.config/wallpapers/config.json`

**Workspace order** matches your macOS Spaces order (left to right).

**IDs:** Auto-derived from name (lowercase, spaces→hyphens, alphanumeric only). Override with `id` for emoji or special character names.

</details>

<br />

## All Commands

| Command | Description |
|:--------|:------------|
| `wp` | Apply wallpapers + apps (picker, or `--all`) |
| `wp quick` | Quick generate — just enter a name |
| `wp goto [name]` | Switch workspace (picker if no name) |
| `wp goto -` | Go back to previous workspace |
| `wp generate` | Full interactive generator with all options |
| `wp cli "Name" [opts]` | Direct generation, no prompts |
| `wp config:init` | Create starter config |
| `wp config:edit` | Open config in editor |
| `wp apply:undo` | Undo app positioning |
| `wp info:space` | Show current desktop number |
| `wp info:resolution` | Show screen resolution |
| `wp info:list` | List generated wallpapers |
| `wp info:wallpaper` | Show current wallpaper path |
| `wp clean` | Delete all generated wallpapers |
| `wp tutorial` | Interactive walkthrough |

<details>
<summary><b>CLI flags reference</b></summary>

```bash
swift run generate "Name" [options]
```

| Flag | Description |
|:-----|:------------|
| `-d, --description` | Subtitle text |
| `-r, --resolution` | `1080p` · `1440p` · `4k` · `macbook-14` · `macbook-16` · `imac-24` · `studio-display` |
| `--width, --height` | Custom dimensions |
| `--bg-color` | Background hex (`#RRGGBB`) |
| `--text-color` | Text hex (`#RRGGBB`) |
| `--style` | Visual style |
| `--id` | Override filename slug |
| `--index` | Space index number |
| `--watermark` | Enable center watermark |
| `--border-text` | Enable border text |
| `--watermark-opacity` | `0.0`–`1.0` |
| `--border-opacity` | `0.0`–`1.0` |
| `--gradient-opacity` | `0.0`–`1.0` |
| `-o, --output-dir` | Output directory |

**Resolution presets:**

```
1080p: 1920×1080       macbook-14: 3024×1964
1440p: 2560×1440       macbook-16: 3456×2234
4k:    3840×2160       imac-24:    4480×2520
                       studio-display: 5120×2880
```

</details>

<br />

## Agent Integration

[![Agent Ready](https://img.shields.io/badge/agent-ready-8A2BE2)](#agent-integration)

Built to be used by humans and AI agents alike. All commands accept explicit arguments for non-interactive use.

```bash
# Read workspace definitions
cat ~/.config/wallpapers/config.json

# Generate programmatically
wp cli "Code" --bg-color "#1a1a2e" --style diagonal --resolution macbook-14

# Apply to all spaces
wp apply --all

# Navigate
wp goto code

# Get agent context
wp ai
```

> The `wp ai` command outputs structured context about capabilities, config format, and available commands — ready to feed into an LLM or agent pipeline.

<br />

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  bash tasks (.mise/tasks/)                          │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐ │
│  │apply │ │quick │ │goto  │ │config│ │ generate │ │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──────┘ └────┬─────┘ │
│     │        │        │                    │       │
│  ┌──▼────────▼────────▼────────────────────▼─────┐ │
│  │           WallpaperKit (Swift)                 │ │
│  │  ┌───────────┐ ┌────────┐ ┌────────────────┐  │ │
│  │  │ Generator │ │ Styles │ │ Colors · Noise │  │ │
│  │  └───────────┘ └────────┘ └────────────────┘  │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Core Graphics · Core Text · ImageIO · AppKit       │
│  Zero external dependencies                         │
└─────────────────────────────────────────────────────┘
```

<details>
<summary><b>Key design decisions</b></summary>

- **Deterministic output** — all procedural generation is seeded from workspace name. Same name → same wallpaper.
- **No external dependencies** — only Apple frameworks.
- **Backward-compatible config** — legacy single-zone format auto-converts to multi-zone.
- **Private APIs for space detection** — `CGSCopyManagedDisplaySpaces()` and `CGSGetActiveSpace()` are undocumented; may break in future macOS versions.
- **Functional core, shell orchestration** — Swift library is pure and stateless. Bash tasks handle interaction, state, and OS integration.

</details>

<br />

## Roadmap

> Where this is going. Contributions welcome.

<table>
  <tr>
    <td width="50%" valign="top">

**Workspace Templates**
Pre-built configs for common workflows. Developer, designer, writer. Install like dotfiles.
```bash
wp template:install developer-dark
```

**Theme System**
Named palettes — nord, dracula, solarized, catppuccin — applied across all spaces with one setting.

**More Styles**
Voronoi, gradient mesh, particle systems. The style system is a clean `enum` + render function — adding styles is straightforward.

</td>
    <td width="50%" valign="top">

**Menu Bar App**
WallpaperKit is already a library. Wrap it in a native menu bar app for quick switching and preview.

**Cross-Platform**
Linux via Cairo + `swaymsg`/`wmctrl`. Windows via `IVirtualDesktopManager` COM + Direct2D. Space detection on Windows is actually better-documented than macOS.

**Config Hot-Reload**
Watch the config file, regenerate on change. Edit → see it instantly.

  </td>
  </tr>
</table>

<br />

## Requirements

| | |
|:--|:--|
| **macOS** | 13+ (Ventura or later) |
| **mise** | [mise.jdx.dev](https://mise.jdx.dev/) — installs gum + other tools automatically |
| **Hammerspoon** | [hammerspoon.org](https://www.hammerspoon.org/) — optional, for app positioning + navigation |

<br />

<div align="center">

## License

MIT

---

<sub>
macOS doesn't let you name your Spaces.
<br />
So we did it ourselves.
</sub>

</div>

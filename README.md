<div align="center">

```
         ▲ ▲
        ╱ ● ●╲
  ╔════╗╱     ╲╔════╗
  ║ ◀══╝       ╚══▶ ║
  ╚════╝╲     ╱╚════╝
      ╲╲    ╱╱        ◀═══╯
       ╲╲  ╱╲  ╱╱
      ▔▔  ▔▔▔▔  ▔▔
```

# Wallpapers

**A workspace identity system for macOS.**

Generate labeled wallpapers. Navigate desktops by name. Position apps into zones.
All from a single config file.

[![Swift: 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![macOS: 13+](https://img.shields.io/badge/macOS-13%2B-000000?style=flat&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)
[![dependencies: 0](https://img.shields.io/badge/dependencies-0-brightgreen?style=flat)](Package.swift)
[![agent: ready](https://img.shields.io/badge/agent-ready-8A2BE2?style=flat)](#agent-integration)

</div>

<p align="center">
  <img src="https://placehold.co/1400x400/2d3436/ffffff?text=Personal+%C2%B7+Code+%C2%B7+Design+%C2%B7+Music" alt="Four wallpapers side by side: Personal (classic), Code (diagonal), Design (typography), Music (flowfield)" width="800" />
</p>

<br />

## Why?

macOS lets you create multiple desktops — Apple calls them **Spaces**. You can swipe between them or use `ctrl+←/→`. But Apple doesn't let you name them. After three desktops they all look the same.

This tool generates wallpapers with labels so you always know where you are. But it goes further: it's a full workspace-as-code system with navigation, app layout, and generative art.

<br />

## Quick Start

```bash
# Install
shiv install wallpapers --as wp

# Go!
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

<p align="center">
  <img src="https://placehold.co/1400x500/1a1a2e/ffffff?text=classic+%C2%B7+diagonal+%C2%B7+tiled+%C2%B7+typography+%C2%B7+flowfield+%C2%B7+perspective" alt="Grid showing all six visual styles: classic, diagonal, tiled, typography, flowfield, perspective" width="700" />
</p>

| Style | Description |
| --- | --- |
| **`classic`** | Clean and minimal. Optional watermark and border text. |
| **`diagonal`** | 30° diagonal tiling — luxury fashion-brand aesthetic. |
| **`tiled`** | Dense 75° wall-to-wall typography texture. |
| **`typography`** | Scattered multi-layer composition. Design poster feel. |
| **`flowfield`** | Organic noise-driven flowing lines. Topographic texture. |
| **`perspective`** | Experimental ray simulation with obstacle physics. |

> All procedural styles use **seeded randomness** — same workspace name always produces the same output. Deterministic and reproducible.

<br />

## Multi-Zone Layouts

Split a single wallpaper into zones that mirror how you actually use the desktop. Flex proportions, rounded corners, configurable gaps.

<p align="center">
  <img src="https://placehold.co/1400x400/0f3460/ffffff?text=Code+(2%2F3)+%7C+Browser+(1%2F3)" alt="A wallpaper split into two zones: Code (2/3 width, dark blue) and Browser (1/3 width, navy)" width="700" />
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

<br />

## Config

Create with `wp config:init`, edit with `wp config:edit`.

<details>
<summary><b>Simple format — one zone per space</b></summary>

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
<summary><b>Full format — multi-zone spaces with app positioning</b></summary>

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
| --- | --- | --- |
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
| --- | --- |
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
| --- | --- |
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

[![agent: ready](https://img.shields.io/badge/agent-ready-8A2BE2?style=flat)](#agent-integration)

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

|   |   |
| --- | --- |
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
<br />
<br />
This README was created using <a href="https://github.com/KnickKnackLabs/readme">readme</a>.
</sub></div>

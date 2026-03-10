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

A workspace identity system for macOS. Generate labeled wallpapers, navigate between desktops by name, and position apps into zones — all from a single config file.

macOS doesn't let you name Spaces. This tool fixes that.

<!-- TODO: Add a hero screenshot here showing 3-4 different workspaces side by side,
     ideally showing different visual styles (classic, diagonal, typography).
     Recommended size: 1200px wide, PNG or WebP. -->

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
wp                # Apply wallpapers (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back to previous workspace (like cd -)
```

## Visual Styles

Every wallpaper can use one of six visual styles. Set per-workspace in your config or pick interactively with `wp generate`.

| Style | Description |
|-------|-------------|
| `classic` | Clean and minimal. Optional watermark and border text. |
| `diagonal` | 30° diagonal tiling — luxury fashion-brand aesthetic. |
| `tiled` | Dense 75° wall-to-wall typography texture. |
| `typography` | Scattered multi-layer composition. Design poster feel. |
| `flowfield` | Organic noise-driven flowing lines. Topographic texture. |
| `perspective` | Experimental ray simulation with obstacle physics. |

All procedural styles use seeded randomness — same workspace name always produces the same output.

<!-- TODO: Add a 2x3 grid of style previews here. Generate one wallpaper per style
     with the same name (e.g., "Code") and same background color, so the style
     differences are clear. Recommended: 600x400px per cell, or one combined image. -->

## Multi-Zone Layouts

A single wallpaper can contain multiple zones — split your desktop visually to match how you use it. Zones use flex proportions (like CSS flexbox) with configurable gaps and rounded corners.

<!-- TODO: Add a screenshot of a multi-zone wallpaper, e.g., a 2:1 split
     with "Code" on the left and "Browser" on the right. -->

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

## App Positioning

With [Hammerspoon](https://www.hammerspoon.org/) installed, `wp apply` goes beyond wallpapers — it positions your apps into zones automatically. Define which apps go where in your config, and your entire workspace layout is applied in one command.

```json
{
  "zones": [
    {
      "name": "Code",
      "flex": 2,
      "apps": ["Code", "Terminal"]
    },
    {
      "name": "Reference",
      "flex": 1,
      "apps": ["Safari"]
    }
  ]
}
```

```bash
wp apply              # Apply wallpapers + position apps
wp apply --apps       # Only reposition apps
wp apply:undo         # Undo app positioning
```

Your workspace is now code. Version it, share it, reproduce it.

## Workspace Navigation

Navigate between spaces by name instead of swiping. The `goto` command supports a `cd -` style shortcut to jump back to where you were.

```bash
wp goto code          # Switch to "Code" workspace
wp goto               # Show picker
wp goto -             # Jump back to previous workspace
```

Workspaces are matched by ID, slug, or name (case-insensitive). If your workspace is named "Skydiving 🪂" with `"id": "skydiving"`, both `wp goto skydiving` and the full name work.

## Config

Create your config with `wp config:init`, then edit with `wp config:edit`.

**Simple format** — one zone per space:

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

**Full format** — multi-zone spaces with app positioning:

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

Config location: `~/.config/wallpapers/config.json`

The workspace order matches your macOS Spaces order (left to right). Both formats are supported — the legacy format is auto-converted internally.

**Workspace IDs:** Each workspace gets a filename-safe slug derived from its name (lowercase, spaces→hyphens, alphanumeric only). Use the `id` field to override, especially for names with emojis or special characters.

## All Commands

| Command | Description |
|---------|-------------|
| `wp` | Apply wallpapers + apps (shows picker, or use `--all`) |
| `wp quick` | Quick generate — just enter a name |
| `wp goto [name]` | Switch workspace (picker if no name) |
| `wp goto -` | Go back to previous workspace |
| `wp generate` | Full interactive generator with all options |
| `wp cli "Name" [options]` | Direct generation without prompts |
| `wp config:init` | Create starter config |
| `wp config:edit` | Open config in editor |
| `wp apply:undo` | Undo app positioning |
| `wp info:space` | Show current desktop number |
| `wp info:resolution` | Show screen resolution |
| `wp info:list` | List generated wallpapers |
| `wp info:wallpaper` | Show current wallpaper path |
| `wp hammerspoon:config` | Generate Hammerspoon integration config |
| `wp clean` | Delete all generated wallpapers |
| `wp tutorial` | Interactive tutorial |

## Scripting & CLI Reference

For scripting or direct access, bypass the interactive prompts:

```bash
swift run generate "Name" [options]
```

| Flag | Description |
|------|-------------|
| `-d, --description` | Subtitle text |
| `-r, --resolution` | Preset: `1080p`, `1440p`, `4k`, `macbook-14`, `macbook-16`, `imac-24`, `studio-display` |
| `--width, --height` | Custom dimensions |
| `--bg-color` | Background hex color (`#RRGGBB`) |
| `--text-color` | Text hex color (`#RRGGBB`) |
| `--id` | Override filename slug |
| `--index` | Space index number |
| `--style` | Visual style (see [Visual Styles](#visual-styles)) |
| `--watermark` | Enable center watermark (classic style) |
| `--border-text` | Enable border text (classic style) |
| `--watermark-opacity` | Watermark opacity (0.0–1.0) |
| `--border-opacity` | Border text opacity (0.0–1.0) |
| `--gradient-opacity` | Bottom gradient opacity (0.0–1.0) |
| `-o, --output-dir` | Output directory |

Resolution presets:

```
1080p: 1920×1080       macbook-14: 3024×1964
1440p: 2560×1440       macbook-16: 3456×2234
4k:    3840×2160       imac-24:    4480×2520
                       studio-display: 5120×2880
```

## Agent Integration

This tool is designed to be used by both humans and AI agents. The `wp ai` command outputs structured context about the tool's capabilities, config format, and available commands — suitable for feeding into an LLM or agent system.

If you're building an agent that manages workspaces, you can:

1. Read the config programmatically (`~/.config/wallpapers/config.json`)
2. Generate wallpapers via the CLI (`wp cli "Name" --bg-color "#1a1a2e" --style diagonal`)
3. Apply to spaces (`wp apply --all`)
4. Navigate spaces (`wp goto <name>`)

All commands are non-interactive when given explicit arguments, making them safe for automated pipelines.

<!-- TODO: Add an example of an agent workflow — e.g., a script that reads a
     project manifest and creates workspace configs automatically. -->

## Architecture

**Swift library + bash orchestration.** The core rendering lives in `WallpaperKit` (pure Swift, Core Graphics, zero external dependencies). Bash tasks in `.mise/tasks/` handle user interaction, state management, and macOS integration via `osascript` and Hammerspoon.

```
Sources/
├── WallpaperKit/          # Core library — rendering, styles, layout
│   ├── Generator.swift    # Wallpaper + multi-zone rendering
│   ├── Style.swift        # Style enum
│   ├── Styles/            # Style implementations (diagonal, flowfield, etc.)
│   ├── Colors.swift       # Hex parsing, luminance, contrast
│   ├── Noise.swift        # Seeded RNG + 2D noise for procedural styles
│   └── ...
├── generate/main.swift    # CLI: single wallpaper
├── setup/main.swift       # CLI: batch generation from config
└── playground/main.swift  # Experimental ray simulation sandbox
```

Key design decisions:
- **Deterministic output** — all procedural generation is seeded from workspace name
- **No external dependencies** — only Apple frameworks (AppKit, Core Graphics, Core Text, ImageIO)
- **Backward-compatible config** — legacy single-zone format auto-converts to the new multi-zone format
- **Private APIs for space detection** — `CGSCopyManagedDisplaySpaces()` and `CGSGetActiveSpace()` are undocumented; may break in future macOS versions

## Roadmap

Where this project could go next.

### Visual Styles
- **More generative styles** — voronoi diagrams, gradient mesh, particle systems. The style system is a clean enum + render function; adding new styles is straightforward.
- **Style parameters in config** — expose angles, opacities, densities, and noise scales as per-workspace config options for fine-grained customization.
- **Theme system** — named color palettes (nord, dracula, solarized, catppuccin) that can be applied across all workspaces with a single setting.

### Workspace Templates
- **Pre-built configs** for common workflows: developer (code + terminal + browser), designer (figma + preview + reference), writer (editor + research + notes).
- **Shareable templates** — publish and install workspace configs like dotfiles. `wp template:install developer-dark`.

### Platform Support
- **Multi-monitor** — per-display configs. The resolution system and multi-zone layout already handle arbitrary dimensions; per-display workspace definitions would be the next step.
- **Linux / Wayland** — the rendering concepts (labeled wallpapers, workspace navigation) apply directly. Port the rendering to Cairo or Skia, use `swaymsg` / `wmctrl` for workspace switching.
- **Windows** — Windows 10+ virtual desktops are accessible via the `IVirtualDesktopManager` COM interface. Wallpaper setting via `SystemParametersInfo` or registry. Rendering via Direct2D or cross-platform Skia backend. Space detection is actually better-documented than on macOS.

### App & Integration
- **Menu bar app** — the Swift core is already a library (`WallpaperKit`). Wrapping it in a lightweight menu bar app would enable quick switching, regeneration, and preview without the terminal.
- **Config hot-reload** — watch the config file with FSEvents and regenerate wallpapers on change. Edit your config, see the result instantly.
- **Animated wallpapers** — the ray simulation already generates paths over time. Rendering to HEIC sequences or video for dynamic wallpapers is a short step from here.

## Requirements

- macOS 13+
- [mise](https://mise.jdx.dev/) (installs gum and other tools automatically)
- [Hammerspoon](https://www.hammerspoon.org/) (optional, for app positioning and space navigation)

## License

MIT

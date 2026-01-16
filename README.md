# Wallpapers

Generate labeled wallpapers for macOS workspaces. Since macOS doesn't let you name Spaces/Desktops, use custom wallpapers to identify them instead.

## Features

- **Zero dependencies** - Uses native Swift with Core Graphics (no Python, no npm)
- **Auto-detect screen resolution** - Generates wallpapers that fit perfectly
- **Auto-detect current space** - Knows which desktop you're on
- **LTR/RTL support** - Text positions correctly for English, Hebrew, Arabic, etc.
- **Beautiful CLI** - Interactive prompts powered by [gum](https://github.com/charmbracelet/gum)

## Requirements

- macOS 13+ (uses native Swift and Core Graphics)
- Swift 5.9+ (included with Xcode Command Line Tools)
- [mise](https://mise.jdx.dev/) for task running

## Quick Start

```bash
# Clone the repo
git clone https://gecgithub01.walmart.com/vn5a6e7/wallpapers.git
cd wallpapers

# Install mise tools (just gum)
mise install

# Install the 'wp' command globally
mise run install

# Now use from anywhere!
wp quick       # Generate a wallpaper
wp set         # Set it as your current desktop's wallpaper
wp set:all     # Or set the same wallpaper on all desktops
```

> **Note:** Requires `~/.local/bin` in your PATH. The installer will warn you if it's missing.

## Tasks

### Generate
| Task | Description |
|------|-------------|
| `mise run generate` | Interactive wallpaper generator with full options |
| `mise run quick` | Quick generate - just enter a name |
| `mise run cli` | Direct CLI access to the generator |
| `mise run help` | Show generator CLI options |

### Set Wallpaper
| Task | Description |
|------|-------------|
| `mise run set` | Set wallpaper for current desktop |
| `mise run set:all` | Set wallpaper for all desktops (cycles through spaces) |

### Info
| Task | Description |
|------|-------------|
| `mise run info:list` | List generated wallpapers |
| `mise run info:resolution` | Show your screen resolution |
| `mise run info:space` | Show current desktop number |

### Utilities
| Task | Description |
|------|-------------|
| `mise run clean` | Delete all generated wallpapers |
| `mise run open` | Open output folder in Finder |
| `mise run install` | Install `wp` command to ~/.local/bin |
| `mise run uninstall` | Remove `wp` command |

## CLI Usage

For scripting or advanced usage:

```bash
# Basic
swift src/generate.swift "My Workspace"

# With description
swift src/generate.swift "Code" -d "Main development"

# Custom resolution
swift src/generate.swift "Design" --width 2880 --height 1864

# Custom colors
swift src/generate.swift "Music" --bg-color "#1a1a2e" --text-color "#00d9ff"

# Preset resolutions
swift src/generate.swift "Work" -r 4k
```

### Resolution Presets

- `1080p` - 1920x1080
- `1440p` - 2560x1440
- `4k` - 3840x2160
- `macbook-14` - 3024x1964
- `macbook-16` - 3456x2234
- `imac-24` - 4480x2520
- `studio-display` - 5120x2880

## How It Works

1. **Generator** (`src/generate.swift`) - Creates PNG wallpapers using Core Graphics
2. **Space Detection** (`src/current-space.swift`) - Uses private macOS APIs to detect current desktop
3. **Tasks** (`.mise/tasks/`) - File-based mise tasks with gum-powered CLI experiences

### Text Positioning

- **LTR languages** (English, etc.) → Bottom-left corner
- **RTL languages** (Hebrew, Arabic) → Bottom-right corner

## Output

Generated wallpapers are saved to `output/` with filenames like:
- `code-2880x1864.png`
- `design-1920x1080.png`

## License

MIT

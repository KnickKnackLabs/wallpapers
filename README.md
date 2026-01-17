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
- [gum](https://github.com/charmbracelet/gum) for interactive prompts
- [jq](https://jqlang.github.io/jq/) for JSON processing

## Installation

```bash
git clone https://github.com/KnickKnackLabs/wallpapers.git ~/.local/share/wallpapers && cd ~/.local/share/wallpapers && mise install && mise run tutorial
```

Or step by step:

```bash
git clone https://github.com/KnickKnackLabs/wallpapers.git ~/.local/share/wallpapers
cd ~/.local/share/wallpapers
mise install      # Install dependencies (gum, jq)
mise run tutorial # Interactive tutorial
```

### Global `wp` Command

Add this to your shell config (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
eval "$(mise -C ~/.local/share/wallpapers run -q shell)"
```

Then reload your shell (`source ~/.zshrc`) and use `wp` from anywhere:

```bash
wp quick          # Generate a wallpaper
wp apply --all    # Apply wallpapers to all spaces
wp goto code      # Switch to a workspace by name
wp tutorial       # Interactive tutorial
```

Shell completions work automatically if you have mise completions set up.

## Tasks

### Getting Started
| Task | Description |
|------|-------------|
| `mise run tutorial` | Interactive tutorial to learn the tool |
| `mise run shell` | Output shell config for `wp` alias (use with eval) |

### Generate
| Task | Description |
|------|-------------|
| `mise run generate` | Interactive wallpaper generator with full options |
| `mise run quick` | Quick generate - just enter a name |
| `mise run cli` | Direct CLI access to the generator |

### Apply & Navigate
| Task | Description |
|------|-------------|
| `mise run apply` | Apply wallpaper to current or all spaces |
| `mise run apply --all` | Generate and apply wallpapers to all spaces from config |
| `mise run goto` | Switch to a workspace by name |
| `mise run goto -` | Go back to previous workspace |

### Config
| Task | Description |
|------|-------------|
| `mise run config:init` | Create starter config file |
| `mise run config:edit` | Open config in your editor |

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

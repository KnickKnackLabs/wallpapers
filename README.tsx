// Bun's --tsconfig-override flag is broken (oven-sh/bun#22023), so when this
// file lives outside the readme repo, auto-discovery won't find the right
// tsconfig. The pragma below ensures our custom JSX runtime is used regardless.
/** @jsxImportSource jsx-md */

import {
  Heading, Paragraph, CodeBlock, Blockquote, LineBreak, HR,
  Bold, Code, Link, Image,
  Badge, Badges, Center, Details, Section,
  Table, TableHead, TableRow, Cell,
  List, Item,
  Raw, HtmlLink, Sub, Align, HtmlTable, HtmlTr, HtmlTd,
} from "readme/src/components";

// --- Custom components ---

function StyleRow({ name, desc }: { name: string; desc: string }) {
  return (
    <TableRow>
      <Cell><Bold><Code>{name}</Code></Bold></Cell>
      <Cell>{desc}</Cell>
    </TableRow>
  );
}

// --- Data ---

const styles = [
  { name: "classic", desc: "Clean and minimal. Optional watermark and border text." },
  { name: "diagonal", desc: "30° diagonal tiling — luxury fashion-brand aesthetic." },
  { name: "tiled", desc: "Dense 75° wall-to-wall typography texture." },
  { name: "typography", desc: "Scattered multi-layer composition. Design poster feel." },
  { name: "flowfield", desc: "Organic noise-driven flowing lines. Topographic texture." },
  { name: "perspective", desc: "Experimental ray simulation with obstacle physics." },
];

const commands = [
  { cmd: "wp", desc: "Apply wallpapers + apps (picker, or `--all`)" },
  { cmd: "wp quick", desc: "Quick generate — just enter a name" },
  { cmd: "wp goto [name]", desc: "Switch workspace (picker if no name)" },
  { cmd: "wp goto -", desc: "Go back to previous workspace" },
  { cmd: "wp generate", desc: "Full interactive generator with all options" },
  { cmd: 'wp cli "Name" [opts]', desc: "Direct generation, no prompts" },
  { cmd: "wp config:init", desc: "Create starter config" },
  { cmd: "wp config:edit", desc: "Open config in editor" },
  { cmd: "wp apply:undo", desc: "Undo app positioning" },
  { cmd: "wp info:space", desc: "Show current desktop number" },
  { cmd: "wp info:resolution", desc: "Show screen resolution" },
  { cmd: "wp info:list", desc: "List generated wallpapers" },
  { cmd: "wp info:wallpaper", desc: "Show current wallpaper path" },
  { cmd: "wp clean", desc: "Delete all generated wallpapers" },
  { cmd: "wp tutorial", desc: "Interactive walkthrough" },
];

const configFields = [
  { field: "name", where: "zone", desc: "Display name on the wallpaper" },
  { field: "description", where: "zone", desc: "Subtitle text below the name" },
  { field: "bgColor", where: "zone / defaults", desc: "Background hex color (`#RRGGBB`)" },
  { field: "textColor", where: "zone / defaults", desc: "Text hex color (`#RRGGBB`)" },
  { field: "style", where: "zone / defaults", desc: "Visual style (see [Visual Styles](#visual-styles))" },
  { field: "id", where: "zone", desc: "Override filename slug (for emoji/special char names)" },
  { field: "watermark", where: "zone", desc: "Enable center watermark (classic style)" },
  { field: "borderText", where: "zone", desc: "Enable border text (classic style)" },
  { field: "flex", where: "zone", desc: "Width proportion in multi-zone layouts" },
  { field: "apps", where: "zone", desc: "Apps to position in this zone" },
  { field: "gap", where: "space", desc: "Pixel gap between zones" },
  { field: "cornerRadius", where: "space", desc: "Rounded corner radius for zones" },
  { field: "chromeColor", where: "space", desc: "Background color visible in gaps" },
];

const cliFlags = [
  { flag: "-d, --description", desc: "Subtitle text" },
  { flag: "-r, --resolution", desc: "`1080p` · `1440p` · `4k` · `macbook-14` · `macbook-16` · `imac-24` · `studio-display`" },
  { flag: "--width, --height", desc: "Custom dimensions" },
  { flag: "--bg-color", desc: "Background hex (`#RRGGBB`)" },
  { flag: "--text-color", desc: "Text hex (`#RRGGBB`)" },
  { flag: "--style", desc: "Visual style" },
  { flag: "--id", desc: "Override filename slug" },
  { flag: "--index", desc: "Space index number" },
  { flag: "--watermark", desc: "Enable center watermark" },
  { flag: "--border-text", desc: "Enable border text" },
  { flag: "--watermark-opacity", desc: "`0.0`–`1.0`" },
  { flag: "--border-opacity", desc: "`0.0`–`1.0`" },
  { flag: "--gradient-opacity", desc: "`0.0`–`1.0`" },
  { flag: "-o, --output-dir", desc: "Output directory" },
];

// --- README ---

const readme = (
  <>
    <Center>
      <CodeBlock>{`         ▲ ▲
        ╱ ● ●╲
  ╔════╗╱     ╲╔════╗
  ║ ◀══╝       ╚══▶ ║
  ╚════╝╲     ╱╚════╝
      ╲╲    ╱╱        ◀═══╯
       ╲╲  ╱╲  ╱╱
      ▔▔  ▔▔▔▔  ▔▔`}</CodeBlock>

      <Heading level={1}>Wallpapers</Heading>

      <Paragraph>
        <Bold>A workspace identity system for macOS.</Bold>
      </Paragraph>

      <Paragraph>
        Generate labeled wallpapers. Navigate desktops by name. Position apps into zones.{"\n"}
        All from a single config file.
      </Paragraph>

      <Badges>
        <Badge label="Swift" value="5.9+" color="F05138" logo="swift" logoColor="white" href="https://swift.org" />
        <Badge label="macOS" value="13+" color="000000" logo="apple" logoColor="white" href="https://www.apple.com/macos/" />
        <Badge label="License" value="MIT" color="blue" href="LICENSE" />
        <Badge label="dependencies" value="0" color="brightgreen" href="Package.swift" />
        <Badge label="agent" value="ready" color="8A2BE2" href="#agent-integration" />
      </Badges>
    </Center>

    {/* TODO: Replace with real hero image (docs/assets/hero.png)
         wp cli "Personal" --bg-color "#2d3436" --style classic
         wp cli "Code" --bg-color "#1a1a2e" --style diagonal
         wp cli "Design" --bg-color "#0f3460" --style typography
         wp cli "Music" --bg-color "#6c5ce7" --style flowfield
         Stitch into a single 1400×400 image with perspective tilt. */}
    <Align>
      <Image src="https://placehold.co/1400x400/2d3436/ffffff?text=Personal+%C2%B7+Code+%C2%B7+Design+%C2%B7+Music" alt="Four wallpapers side by side: Personal (classic), Code (diagonal), Design (typography), Music (flowfield)" width={800} />
    </Align>

    <LineBreak />

    <Section title="Why?">
      <Paragraph>
        macOS lets you create multiple desktops — Apple calls them <Bold>Spaces</Bold>.
        You can swipe between them or use <Code>ctrl+←/→</Code>.
        But Apple doesn't let you name them. After three desktops they all look the same.
      </Paragraph>

      <Paragraph>
        This tool generates wallpapers with labels so you always know where you are.
        But it goes further: it's a full workspace-as-code system with navigation, app layout, and generative art.
      </Paragraph>
    </Section>

    <LineBreak />

    <Section title="Quick Start">
      <CodeBlock lang="bash">{`# Install
shiv install wallpapers --as wp

# Go!
wp tutorial`}</CodeBlock>
    </Section>

    <LineBreak />

    <Section title="Usage">
      <CodeBlock lang="bash">{`wp                # Apply wallpapers (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back (like cd -)`}</CodeBlock>
    </Section>

    <LineBreak />

    <Section title="Visual Styles">
      <Paragraph>
        Six built-in styles — from minimal to generative art. Set per-workspace
        in config or pick interactively with <Code>wp generate</Code>.
      </Paragraph>

      {/* TODO: Replace with real style grid (docs/assets/styles.png)
           for s in classic diagonal tiled typography flowfield perspective; do
             wp cli "Code" --bg-color "#1a1a2e" --style $s --resolution 1080p --id "style-$s"
           done
           Arrange as 3×2 grid, ~400×250 each. */}
      <Align>
        <Image src="https://placehold.co/1400x500/1a1a2e/ffffff?text=classic+%C2%B7+diagonal+%C2%B7+tiled+%C2%B7+typography+%C2%B7+flowfield+%C2%B7+perspective" alt="Grid showing all six visual styles: classic, diagonal, tiled, typography, flowfield, perspective" width={700} />
      </Align>

      <Table>
        <TableHead>
          <Cell>Style</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {styles.map(s => <StyleRow name={s.name} desc={s.desc} />)}
      </Table>

      <Blockquote>
        All procedural styles use <Bold>seeded randomness</Bold> — same workspace name always produces the same output. Deterministic and reproducible.
      </Blockquote>
    </Section>

    <LineBreak />

    <Section title="Multi-Zone Layouts">
      <Paragraph>
        Split a single wallpaper into zones that mirror how you actually use the desktop.
        Flex proportions, rounded corners, configurable gaps.
      </Paragraph>

      {/* TODO: Replace with real multi-zone image (docs/assets/multi-zone.png)
           Use a 2:1 split config, show inside a macOS window chrome mockup. */}
      <Align>
        <Image src="https://placehold.co/1400x400/0f3460/ffffff?text=Code+(2%2F3)+%7C+Browser+(1%2F3)" alt="A wallpaper split into two zones: Code (2/3 width, dark blue) and Browser (1/3 width, navy)" width={700} />
      </Align>

      <CodeBlock lang="json">{`{
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
}`}</CodeBlock>
    </Section>

    <LineBreak />

    <Section title="Workspace Navigation">
      <Paragraph>
        Navigate by name, not by swiping. Supports <Code>cd -</Code> to jump back.
      </Paragraph>

      <CodeBlock lang="bash">{`wp goto code       # Jump to "Code" workspace
wp goto            # Show picker
wp goto -          # Back to previous (like cd -)`}</CodeBlock>

      <Blockquote>
        <Bold>Matching:</Bold> Workspaces are found by ID, slug, or name (case-insensitive).{"\n"}
        A workspace named <Code>{'"Skydiving 🪂"'}</Code> with <Code>{'"id": "skydiving"'}</Code> matches <Code>wp goto skydiving</Code>.
      </Blockquote>
    </Section>

    <LineBreak />

    <Section title="App Positioning">
      <Paragraph>
        With <Link href="https://www.hammerspoon.org/">Hammerspoon</Link> installed,{" "}
        <Code>wp apply</Code> positions your apps into zones automatically. Your workspace
        layout becomes code — version it, share it, reproduce it.
      </Paragraph>

      <CodeBlock lang="bash">{`wp apply              # Wallpapers + position apps
wp apply --apps       # Only reposition apps
wp apply:undo         # Undo positioning`}</CodeBlock>
    </Section>

    <LineBreak />

    <Section title="Config">
      <Paragraph>
        Create with <Code>wp config:init</Code>, edit with <Code>wp config:edit</Code>.
      </Paragraph>

      <Details summary="Simple format — one zone per space">
        <CodeBlock lang="json">{`{
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
}`}</CodeBlock>
      </Details>

      <Details summary="Full format — multi-zone spaces with app positioning">
        <CodeBlock lang="json">{`{
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
}`}</CodeBlock>
      </Details>

      <Details summary="Config reference">
        <Table>
          <TableHead>
            <Cell>Field</Cell>
            <Cell>Where</Cell>
            <Cell>Description</Cell>
          </TableHead>
          {configFields.map(f => (
            <TableRow>
              <Cell><Code>{f.field}</Code></Cell>
              <Cell>{f.where}</Cell>
              <Cell>{f.desc}</Cell>
            </TableRow>
          ))}
        </Table>

        <Paragraph>
          <Bold>Location:</Bold> <Code>~/.config/wallpapers/config.json</Code>
        </Paragraph>

        <Paragraph>
          <Bold>Workspace order</Bold> matches your macOS Spaces order (left to right).
        </Paragraph>

        <Paragraph>
          <Bold>IDs:</Bold> Auto-derived from name (lowercase, spaces→hyphens, alphanumeric only).
          Override with <Code>id</Code> for emoji or special character names.
        </Paragraph>
      </Details>
    </Section>

    <LineBreak />

    <Section title="All Commands">
      <Table>
        <TableHead>
          <Cell>Command</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {commands.map(c => (
          <TableRow>
            <Cell><Code>{c.cmd}</Code></Cell>
            <Cell>{c.desc}</Cell>
          </TableRow>
        ))}
      </Table>

      <Details summary="CLI flags reference">
        <CodeBlock lang="bash">{`swift run generate "Name" [options]`}</CodeBlock>

        <Table>
          <TableHead>
            <Cell>Flag</Cell>
            <Cell>Description</Cell>
          </TableHead>
          {cliFlags.map(f => (
            <TableRow>
              <Cell><Code>{f.flag}</Code></Cell>
              <Cell>{f.desc}</Cell>
            </TableRow>
          ))}
        </Table>

        <Paragraph><Bold>Resolution presets:</Bold></Paragraph>

        <CodeBlock>{`1080p: 1920×1080       macbook-14: 3024×1964
1440p: 2560×1440       macbook-16: 3456×2234
4k:    3840×2160       imac-24:    4480×2520
                       studio-display: 5120×2880`}</CodeBlock>
      </Details>
    </Section>

    <LineBreak />

    <Section title="Agent Integration">
      <Badges>
        <Badge label="agent" value="ready" color="8A2BE2" href="#agent-integration" />
      </Badges>

      <Paragraph>
        Built to be used by humans and AI agents alike. All commands accept explicit arguments for non-interactive use.
      </Paragraph>

      <CodeBlock lang="bash">{`# Read workspace definitions
cat ~/.config/wallpapers/config.json

# Generate programmatically
wp cli "Code" --bg-color "#1a1a2e" --style diagonal --resolution macbook-14

# Apply to all spaces
wp apply --all

# Navigate
wp goto code

# Get agent context
wp ai`}</CodeBlock>

      <Blockquote>
        The <Code>wp ai</Code> command outputs structured context about capabilities,
        config format, and available commands — ready to feed into an LLM or agent pipeline.
      </Blockquote>
    </Section>

    <LineBreak />

    <Section title="Architecture">
      <CodeBlock>{`┌─────────────────────────────────────────────────────┐
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
└─────────────────────────────────────────────────────┘`}</CodeBlock>

      <Details summary="Key design decisions">
        <List>
          <Item><Bold>Deterministic output</Bold> — all procedural generation is seeded from workspace name. Same name → same wallpaper.</Item>
          <Item><Bold>No external dependencies</Bold> — only Apple frameworks.</Item>
          <Item><Bold>Backward-compatible config</Bold> — legacy single-zone format auto-converts to multi-zone.</Item>
          <Item><Bold>Private APIs for space detection</Bold> — <Code>CGSCopyManagedDisplaySpaces()</Code> and <Code>CGSGetActiveSpace()</Code> are undocumented; may break in future macOS versions.</Item>
          <Item><Bold>Functional core, shell orchestration</Bold> — Swift library is pure and stateless. Bash tasks handle interaction, state, and OS integration.</Item>
        </List>
      </Details>
    </Section>

    <LineBreak />

    <Section title="Roadmap">
      <Blockquote>Where this is going. Contributions welcome.</Blockquote>

      <HtmlTable>
        <HtmlTr>
          <HtmlTd width="50%" valign="top">
            <Paragraph>
              <Bold>Workspace Templates</Bold>{"\n"}
              Pre-built configs for common workflows. Developer, designer, writer. Install like dotfiles.
            </Paragraph>
            <CodeBlock lang="bash">{`wp template:install developer-dark`}</CodeBlock>
            <Paragraph>
              <Bold>Theme System</Bold>{"\n"}
              Named palettes — nord, dracula, solarized, catppuccin — applied across all spaces with one setting.
            </Paragraph>
            <Paragraph>
              <Bold>More Styles</Bold>{"\n"}
              Voronoi, gradient mesh, particle systems. The style system is a clean <Code>enum</Code> + render function — adding styles is straightforward.
            </Paragraph>
          </HtmlTd>
          <HtmlTd width="50%" valign="top">
            <Paragraph>
              <Bold>Menu Bar App</Bold>{"\n"}
              WallpaperKit is already a library. Wrap it in a native menu bar app for quick switching and preview.
            </Paragraph>
            <Paragraph>
              <Bold>Cross-Platform</Bold>{"\n"}
              {"Linux via Cairo + `swaymsg`/`wmctrl`. Windows via `IVirtualDesktopManager` COM + Direct2D. Space detection on Windows is actually better-documented than macOS."}
            </Paragraph>
            <Paragraph>
              <Bold>Config Hot-Reload</Bold>{"\n"}
              Watch the config file, regenerate on change. Edit → see it instantly.
            </Paragraph>
          </HtmlTd>
        </HtmlTr>
      </HtmlTable>
    </Section>

    <LineBreak />

    <Section title="Requirements">
      <Table>
        <TableHead>
          <Cell>{" "}</Cell>
          <Cell>{" "}</Cell>
        </TableHead>
        <TableRow>
          <Cell><Bold>macOS</Bold></Cell>
          <Cell>13+ (Ventura or later)</Cell>
        </TableRow>
        <TableRow>
          <Cell><Bold>mise</Bold></Cell>
          <Cell><Link href="https://mise.jdx.dev/">mise.jdx.dev</Link> — installs gum + other tools automatically</Cell>
        </TableRow>
        <TableRow>
          <Cell><Bold>Hammerspoon</Bold></Cell>
          <Cell><Link href="https://www.hammerspoon.org/">hammerspoon.org</Link> — optional, for app positioning + navigation</Cell>
        </TableRow>
      </Table>
    </Section>

    <LineBreak />

    <Center>
      <Section title="License">
        <Paragraph>MIT</Paragraph>
      </Section>

      <HR />

      <Sub>
        macOS doesn't let you name your Spaces.{"\n"}
        <Raw>{"<br />"}</Raw>{"\n"}
        So we did it ourselves.{"\n"}
        <Raw>{"<br />"}</Raw>{"\n"}
        <Raw>{"<br />"}</Raw>{"\n"}
        This README was created using <HtmlLink href="https://github.com/KnickKnackLabs/readme">readme</HtmlLink>.
      </Sub>
    </Center>
  </>
);

console.log(readme);

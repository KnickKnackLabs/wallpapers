/** @jsxImportSource jsx-md */

import { existsSync, readdirSync, readFileSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock,
  Bold, Code, Link,
  Badge, Badges, Center, Section,
  Table, TableHead, TableRow, Cell,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const REPO_DIR = resolve(import.meta.dirname);

type TaskInfo = { name: string; filePath: string; desc: string };

function hiddenTask(filePath: string): boolean {
  return readFileSync(filePath, "utf-8").includes("#MISE hide=true");
}

function taskDescription(filePath: string): string {
  const content = readFileSync(filePath, "utf-8");
  const match = content.match(/#MISE description="(.+?)"/);
  return match?.[1] ?? "";
}

// Count public tasks, including namespace _default entrypoints and excluding hidden helpers.
function collectTasks(dir: string, prefix = ""): TaskInfo[] {
  const tasks: TaskInfo[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === "test") continue;
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      const defaultTask = join(full, "_default");
      if (existsSync(defaultTask) && !hiddenTask(defaultTask)) {
        tasks.push({ name: `${prefix}${entry.name}`, filePath: defaultTask, desc: taskDescription(defaultTask) });
      }
      tasks.push(...collectTasks(full, `${prefix}${entry.name}:`));
    } else if (!entry.name.startsWith("_") && !hiddenTask(full)) {
      tasks.push({ name: `${prefix}${entry.name}`, filePath: full, desc: taskDescription(full) });
    }
  }
  return tasks;
}

const taskDir = join(REPO_DIR, ".mise/tasks");
const taskInfo = collectTasks(taskDir);
const tasks = taskInfo.map((task) => task.name);

// Count tests from .bats files
const testDir = join(REPO_DIR, "test");
const testCount = readdirSync(testDir)
  .filter((f) => f.endsWith(".bats"))
  .reduce((sum, f) => {
    const content = readFileSync(join(testDir, f), "utf-8");
    return sum + (content.match(/@test /g) || []).length;
  }, 0);

// Resolution presets for the table
const resolutions = [
  { name: "1080p", dims: "1920×1080" },
  { name: "1440p", dims: "2560×1440" },
  { name: "4k", dims: "3840×2160" },
  { name: "macbook-14", dims: "3024×1964" },
  { name: "macbook-16", dims: "3456×2234" },
  { name: "imac-24", dims: "4480×2520" },
  { name: "studio-display", dims: "5120×2880" },
];

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Heading level={1}>Wallpapers</Heading>

      <CodeBlock lang="">{`         ▲ ▲
        ╱   ╲
       ╱ ° ° ╲      ╭───╮
      ▕  ───  ▏ ◁━━━│ @ │━╮
       ╲ ╰─╯ ╱      ╰───╯ │
      ╱╱    ╲╲        ◀═══╯
     ╱╱  ╱╲  ╲╲
    ▔▔  ▔▔▔▔  ▔▔
   ZERGLING    TURTLE
               (in peril)`}</CodeBlock>

      <Paragraph>
        <Bold>Generate labeled wallpapers for macOS workspaces.</Bold>
      </Paragraph>

      <Paragraph>
        macOS lets you create multiple desktops ("Spaces") but doesn't let you name them.{"\n"}
        This tool generates wallpapers with labels so you can tell them apart.
      </Paragraph>

      <Badges>
        <Badge label="lang" value="Swift + Bash" color="F05138" logo="swift" logoColor="white" />
        <Badge label="runtime" value="mise" color="7c3aed" href="https://mise.jdx.dev" />
        <Badge label="tasks" value={`${tasks.length}`} color="blue" />
        <Badge label="tests" value={`${testCount}`} color="green" />
        <Badge label="License" value="MIT" color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <Section title="Quick Start">
      <CodeBlock lang="bash">{`# Install
shiv install wallpapers

# Add the wp alias to your shell
eval "$(wallpapers shell)"

# Run the tutorial
wp tutorial`}</CodeBlock>
    </Section>

    <Section title="Usage">
      <CodeBlock lang="bash">{`wp                # Apply wallpaper (picker or --all)
wp --all          # Apply wallpapers to all spaces from config
wp quick          # Quick one-off wallpaper for current space
wp snapshot       # Bootstrap WALLPAPERS.tsx from current Spaces
wp build          # Compile WALLPAPERS.tsx to WALLPAPERS.json
wp apply --config ./WALLPAPERS.json --wallpapers
wp goto           # Switch workspace (picker)
wp goto code      # Switch to workspace by name
wp goto -         # Go back to previous workspace`}</CodeBlock>
    </Section>

    <Section title="Config">
      <Paragraph>
        Create your config with <Code>wp config init</Code>, then edit
        with <Code>wp config edit</Code>:
      </Paragraph>

      <CodeBlock lang="json">{`{
  "workspaces": [
    { "name": "Personal", "bgColor": "#2d3436" },
    { "name": "Code", "bgColor": "#1a1a2e", "description": "Dev environment" },
    { "name": "Design", "bgColor": "#0f3460" }
  ],
  "defaults": {
    "bgColor": "#000000",
    "textColor": "#ffffff"
  }
}`}</CodeBlock>

      <Paragraph>
        The order of workspaces matches your Spaces order (left to right).
      </Paragraph>

      <Paragraph>
        For repo-owned recipes, write <Code>WALLPAPERS.tsx</Code>, then run{" "}
        <Code>wp build</Code>. To start from your current macOS layout, run{" "}
        <Code>wp snapshot</Code>; it writes one starter zone per Space, with optional window
        comments via <Code>wp snapshot --include-windows</Code>. The generated{" "}
        <Code>WALLPAPERS.json</Code> can be applied explicitly with{" "}
        <Code>wp apply --config ./WALLPAPERS.json --wallpapers</Code>.
      </Paragraph>
    </Section>

    <Section title="Resolution presets">
      <Paragraph>
        Auto-detect is the default. You can also specify a preset with <Code>--resolution</Code>:
      </Paragraph>

      <Table>
        <TableHead>
          <Cell>Preset</Cell>
          <Cell>Dimensions</Cell>
        </TableHead>
        {resolutions.map((r) => (
          <TableRow>
            <Cell><Code>{r.name}</Code></Cell>
            <Cell>{r.dims}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="All tasks">
      <Table>
        <TableHead>
          <Cell>Task</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {taskInfo.map((t) => (
          <TableRow>
            <Cell><Code>{t.name}</Code></Cell>
            <Cell>{t.desc}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{`gh repo clone KnickKnackLabs/wallpapers
cd wallpapers && mise trust && mise install
mise run test   # ${testCount} tests`}</CodeBlock>

      <Paragraph>
        <Bold>Architecture:</Bold> Swift layer (<Code>Sources/WallpaperKit/</Code>) handles
        Core Graphics rendering. Bash tasks in <Code>.mise/tasks/</Code> handle user
        interaction via <Code>gum</Code>. Shared helpers live in <Code>lib/common.sh</Code>.
        Space management delegates to{" "}
        <Link href="https://github.com/KnickKnackLabs/butthair">butthair</Link>.
      </Paragraph>
    </Section>

    <Center>
      <Section title="License">
        <Paragraph>MIT</Paragraph>
      </Section>

      <Paragraph>
        {"This README was created using "}
        <Link href="https://github.com/KnickKnackLabs/readme">readme</Link>.
      </Paragraph>
    </Center>
  </>
);

console.log(`<!-- Generated from README.tsx — edit that file, then run: mise run readme -->\n\n${readme}`);

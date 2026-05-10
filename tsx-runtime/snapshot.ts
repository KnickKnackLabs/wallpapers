import { mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, resolve } from "path";

type SpaceSnapshot = {
  index: number;
  id?: number | string;
  active: boolean;
  type?: string;
  windows?: WindowSnapshot[];
};

type WindowSnapshot = {
  id?: number | string;
  app: string;
  title: string;
  visible?: boolean;
  spaces: number[];
};

type Options = {
  spaces?: string;
  windows?: string;
  out?: string;
  json: boolean;
};

function usage(): never {
  console.error("Usage: snapshot.ts --spaces <spaces.json> [--windows <windows.json>] [--out <WALLPAPERS.tsx> | --json]");
  process.exit(2);
}

function parseArgs(argv: string[]): Options {
  const options: Options = { json: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--spaces":
        i += 1;
        if (i >= argv.length) usage();
        options.spaces = argv[i];
        break;
      case "--windows":
        i += 1;
        if (i >= argv.length) usage();
        options.windows = argv[i];
        break;
      case "--out":
        i += 1;
        if (i >= argv.length) usage();
        options.out = argv[i];
        break;
      case "--json":
        options.json = true;
        break;
      case "-h":
      case "--help":
        usage();
        break;
      default:
        console.error(`Unknown argument: ${arg}`);
        usage();
    }
  }

  if (!options.spaces) usage();
  if (options.json === Boolean(options.out)) usage();
  return options;
}

function readJson(path: string): unknown {
  return JSON.parse(readFileSync(path, "utf8"));
}

function asObject(value: unknown, label: string): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value as Record<string, unknown>;
}

function asNumber(value: unknown, label: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new Error(`${label} must be a number`);
  }
  return value;
}

function asOptionalId(value: unknown): number | string | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.length > 0) return value;
  return undefined;
}

function asOptionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function parseSpaces(raw: unknown): SpaceSnapshot[] {
  if (!Array.isArray(raw)) {
    throw new Error("spaces snapshot must be an array");
  }

  const spaces = raw.map((item, position) => {
    const space = asObject(item, `spaces[${position}]`);
    const index = space.index === undefined ? position + 1 : asNumber(space.index, `spaces[${position}].index`);
    return {
      index,
      id: asOptionalId(space.id),
      active: space.active === true,
      type: asOptionalString(space.type),
    };
  });

  if (spaces.length === 0) {
    throw new Error("spaces snapshot is empty");
  }

  return spaces.sort((a, b) => a.index - b.index);
}

function parseWindows(raw: unknown): WindowSnapshot[] {
  if (!Array.isArray(raw)) {
    throw new Error("windows snapshot must be an array");
  }

  return raw.flatMap((item, position) => {
    const win = asObject(item, `windows[${position}]`);
    const spacesRaw = win.spaces;
    if (!Array.isArray(spacesRaw)) return [];
    const spaces = spacesRaw.filter((space): space is number => typeof space === "number" && Number.isFinite(space));
    if (spaces.length === 0) return [];

    return [{
      id: asOptionalId(win.id),
      app: asOptionalString(win.app) ?? "Unknown app",
      title: asOptionalString(win.title) ?? "Untitled",
      visible: typeof win.visible === "boolean" ? win.visible : undefined,
      spaces,
    }];
  });
}

function attachWindows(spaces: SpaceSnapshot[], windows: WindowSnapshot[]): SpaceSnapshot[] {
  return spaces.map((space) => ({
    ...space,
    windows: windows
      .filter((win) => win.spaces.includes(space.index))
      .sort((a, b) => `${a.app}\u0000${a.title}`.localeCompare(`${b.app}\u0000${b.title}`)),
  }));
}

function commentText(value: string): string {
  return value.replace(/\*\//g, "* /").replace(/[\r\n]+/g, " ");
}

function spaceComment(space: SpaceSnapshot): string {
  const parts = [`macOS space #${space.index}`];
  if (space.id !== undefined) parts.push(`id=${space.id}`);
  if (space.type) parts.push(`type=${space.type}`);
  if (space.active) parts.push("active");
  return parts.join(", ");
}

function renderTsx(spaces: SpaceSnapshot[]): string {
  const lines = [
    'import { WorkspaceSet, Space, Zone } from "wallpapers";',
    "",
    "export default (",
    '  <WorkspaceSet defaults={{ bgColor: "#000000", textColor: "#ffffff", gap: 4 }}>',
  ];

  for (const space of spaces) {
    lines.push(`    {/* ${commentText(spaceComment(space))} */}`);
    if (space.windows && space.windows.length > 0) {
      lines.push("    {/* windows:");
      for (const win of space.windows) {
        const visible = win.visible === false ? " (hidden)" : "";
        lines.push(`      - ${commentText(`${win.app} — ${win.title}${visible}`)}`);
      }
      lines.push("    */}");
    }
    lines.push("    <Space>");
    lines.push(`      <Zone name="space-${space.index}" description="TODO" />`);
    lines.push("    </Space>");
    lines.push("");
  }

  lines.push("  </WorkspaceSet>");
  lines.push(");");
  lines.push("");
  return lines.join("\n");
}

const options = parseArgs(process.argv.slice(2));
const spacesPath = resolve(options.spaces!);
const windowsPath = options.windows ? resolve(options.windows) : undefined;

let spaces = parseSpaces(readJson(spacesPath));
if (windowsPath) {
  spaces = attachWindows(spaces, parseWindows(readJson(windowsPath)));
}

const snapshot = {
  snapshotVersion: 1,
  generatedBy: {
    tool: "wallpapers",
    command: "snapshot",
  },
  spaces,
};

if (options.json) {
  process.stdout.write(`${JSON.stringify(snapshot, null, 2)}\n`);
} else {
  const out = resolve(options.out!);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, renderTsx(spaces));
  console.log(`wrote ${out}`);
}

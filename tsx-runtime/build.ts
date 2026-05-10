import { mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, resolve } from "path";
import { pathToFileURL } from "url";

import { defineWorkspaceSet } from "wallpapers";

type Options = {
  source?: string;
  out?: string;
  check: boolean;
  recipeArgs: string[];
};

function usage(): never {
  console.error("Usage: build.ts --source <WALLPAPERS.tsx> --out <WALLPAPERS.json> [--check] [-- <args...>]");
  process.exit(2);
}

function parseArgs(argv: string[]): Options {
  const options: Options = { check: false, recipeArgs: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--") {
      options.recipeArgs = argv.slice(i + 1);
      break;
    }
    switch (arg) {
      case "--source":
        i += 1;
        if (i >= argv.length) usage();
        options.source = argv[i];
        break;
      case "--out":
        i += 1;
        if (i >= argv.length) usage();
        options.out = argv[i];
        break;
      case "--check":
        options.check = true;
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
  if (!options.source || !options.out) usage();
  return options;
}

const options = parseArgs(process.argv.slice(2));
const source = resolve(options.source!);
const out = resolve(options.out!);

const recipeArgv = [Bun.argv[0] ?? "bun", source, ...options.recipeArgs];
(Bun as unknown as { argv: string[] }).argv = recipeArgv;
process.argv = recipeArgv;

const mod = await import(pathToFileURL(source).href);
const exported = mod.default ?? mod.workspaceSet ?? mod.config;
if (exported === undefined) {
  throw new Error("WALLPAPERS.tsx must export default <WorkspaceSet ... />");
}

const config = defineWorkspaceSet(exported);
const json = `${JSON.stringify(config, null, 2)}\n`;

if (options.check) {
  let existing = "";
  try {
    existing = readFileSync(out, "utf8");
  } catch {
    console.error(`WALLPAPERS.json is missing: ${out}`);
    process.exit(1);
  }
  if (existing !== json) {
    console.error(`WALLPAPERS.json is out of date: ${out}`);
    process.exit(1);
  }
  console.log(`ok: ${out} is up to date`);
} else {
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, json);
  console.log(`wrote ${out}`);
}

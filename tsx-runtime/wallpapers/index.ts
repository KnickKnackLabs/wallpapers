type Child = unknown;

type Props = Record<string, unknown> & { children?: Child };

type ElementLike = {
  type?: unknown;
  props?: Props;
};

type Node = Record<string, unknown> & { kind: string };

function isElementLike(value: unknown): value is ElementLike {
  return typeof value === "object" && value !== null && "type" in value && "props" in value;
}

function childrenArray(children: Child): unknown[] {
  if (children === undefined || children === null || children === false) return [];
  return Array.isArray(children) ? children.flatMap(childrenArray) : [children];
}

function renderNode(value: unknown): unknown {
  if (isElementLike(value)) {
    if (typeof value.type !== "function") {
      throw new Error(`Unsupported JSX node type: ${String(value.type)}`);
    }
    return renderNode(value.type(value.props ?? {}));
  }
  return value;
}

function renderChildren(children: Child, expectedKind: string): Node[] {
  return childrenArray(children).map((child) => {
    const node = renderNode(child);
    if (typeof node !== "object" || node === null || (node as Node).kind !== expectedKind) {
      throw new Error(`Expected <${expectedKind}> child`);
    }
    return node as Node;
  });
}

function copyDefined(source: Record<string, unknown>, keys: string[]): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const key of keys) {
    if (source[key] !== undefined) out[key] = source[key];
  }
  return out;
}

function withoutKind(node: Node): Record<string, unknown> {
  const { kind: _kind, ...rest } = node;
  return rest;
}

export function Zone(props: Props): Node {
  if (typeof props.name !== "string" || props.name.length === 0) {
    throw new Error("<Zone> requires a non-empty name");
  }

  return {
    kind: "Zone",
    ...copyDefined(props, [
      "name",
      "id",
      "description",
      "flex",
      "bgColor",
      "textColor",
      "resolution",
      "width",
      "height",
      "style",
      "borderText",
      "watermark",
      "borderOpacity",
      "watermarkOpacity",
      "gradientOpacity",
      "apps",
    ]),
  };
}

export function Space(props: Props): Node {
  const zones = renderChildren(props.children, "Zone").map(withoutKind);
  if (zones.length === 0) {
    throw new Error("<Space> requires at least one <Zone>");
  }

  return {
    kind: "Space",
    ...copyDefined(props, ["name", "id", "gap", "cornerRadius", "chromeColor"]),
    zones,
  };
}

export function WorkspaceSet(props: Props): Record<string, unknown> {
  const spaces = renderChildren(props.children, "Space").map(withoutKind);
  if (spaces.length === 0) {
    throw new Error("<WorkspaceSet> requires at least one <Space>");
  }

  return {
    schemaVersion: 1,
    generatedBy: {
      tool: "wallpapers",
    },
    ...copyDefined(props, ["name", "id", "defaults"]),
    spaces,
  };
}

export function defineWorkspaceSet(value: unknown): Record<string, unknown> {
  const config = renderNode(value);
  if (typeof config !== "object" || config === null || !Array.isArray((config as { spaces?: unknown }).spaces)) {
    throw new Error("WALLPAPERS.tsx must export a <WorkspaceSet> tree");
  }
  return config as Record<string, unknown>;
}

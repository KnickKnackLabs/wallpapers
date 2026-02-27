import Foundation
import WallpaperKit

// MARK: - Config Models (new format: spaces/zones)

struct Zone: Codable {
    let name: String
    let id: String?
    let description: String?
    let flex: Double?
    let bgColor: String?
    let textColor: String?
    let resolution: String?
    let width: Int?
    let height: Int?
    let style: String?
    let borderText: Bool?
    let watermark: Bool?
    let borderOpacity: Double?
    let watermarkOpacity: Double?
    let gradientOpacity: Double?
}

struct Space: Codable {
    let zones: [Zone]
    let gap: Double?
    let cornerRadius: Double?
    let chromeColor: String?
}

struct Defaults: Codable {
    let bgColor: String?
    let textColor: String?
    let resolution: String?
    let style: String?
    let borderText: Bool?
    let watermark: Bool?
    let borderOpacity: Double?
    let watermarkOpacity: Double?
    let gradientOpacity: Double?
    let gap: Double?
    let cornerRadius: Double?
    let chromeColor: String?
}

struct SpaceConfig: Codable {
    let spaces: [Space]
    let defaults: Defaults?
}

// MARK: - Legacy config (backward compat)

struct LegacyWorkspace: Codable {
    let name: String
    let id: String?
    let description: String?
    let bgColor: String?
    let textColor: String?
    let resolution: String?
    let width: Int?
    let height: Int?
    let style: String?
    let borderText: Bool?
    let watermark: Bool?
    let borderOpacity: Double?
    let watermarkOpacity: Double?
    let gradientOpacity: Double?
}

struct LegacyConfig: Codable {
    let workspaces: [LegacyWorkspace]
    let defaults: Defaults?
}

/// Convert legacy config to new format (each workspace becomes a single-zone space).
func convertLegacy(_ legacy: LegacyConfig) -> SpaceConfig {
    let spaces = legacy.workspaces.map { ws -> Space in
        let zone = Zone(
            name: ws.name, id: ws.id, description: ws.description,
            flex: nil,
            bgColor: ws.bgColor, textColor: ws.textColor,
            resolution: ws.resolution, width: ws.width, height: ws.height,
            style: ws.style,
            borderText: ws.borderText, watermark: ws.watermark,
            borderOpacity: ws.borderOpacity, watermarkOpacity: ws.watermarkOpacity,
            gradientOpacity: ws.gradientOpacity
        )
        return Space(zones: [zone], gap: nil, cornerRadius: nil, chromeColor: nil)
    }
    return SpaceConfig(spaces: spaces, defaults: legacy.defaults)
}

// MARK: - Zone → ZoneParams helper

func makeZoneParams(zone: Zone, defaults: Defaults?) -> ZoneParams {
    let bgColorHex = zone.bgColor ?? defaults?.bgColor ?? "#000000"
    let textColorHex = zone.textColor ?? defaults?.textColor ?? "#ffffff"

    let bg = parseHexColor(bgColorHex) ?? (r: 0, g: 0, b: 0)
    let text = parseHexColor(textColorHex) ?? (r: 1, g: 1, b: 1)

    let styleName = zone.style ?? defaults?.style ?? "classic"
    let style = WallpaperStyle(rawValue: styleName) ?? .classic

    let enableWatermark = style == .classic && (zone.watermark ?? defaults?.watermark ?? true)
    let enableBorderText = style == .classic && (zone.borderText ?? defaults?.borderText ?? true)

    return ZoneParams(
        name: zone.name, description: zone.description,
        bgColor: bg, textColor: text,
        style: style,
        enableWatermark: enableWatermark,
        watermarkOpacity: CGFloat(zone.watermarkOpacity ?? defaults?.watermarkOpacity ?? 0.08),
        enableBorderText: enableBorderText,
        borderOpacity: CGFloat(zone.borderOpacity ?? defaults?.borderOpacity ?? 0.15),
        gradientOpacity: CGFloat(zone.gradientOpacity ?? defaults?.gradientOpacity ?? 0.4)
    )
}

// MARK: - CLI

func printUsage() {
    print("""
    Usage: setup [options]

    Options:
      --generate-only     Only generate wallpapers, don't apply to spaces
      --width <pixels>    Override width for all wallpapers
      --height <pixels>   Override height for all wallpapers
      -h, --help          Show this help

    Reads config from ~/.config/wallpapers/config.json
    Supports both new format (spaces/zones) and legacy format (workspaces).
    """)
}

var args = Array(CommandLine.arguments.dropFirst())

var generateOnly = false
var customWidth: Int?
var customHeight: Int?

var i = 0
while i < args.count {
    let arg = args[i]
    switch arg {
    case "--generate-only":
        generateOnly = true
    case "--width":
        i += 1
        if i < args.count { customWidth = Int(args[i]) }
    case "--height":
        i += 1
        if i < args.count { customHeight = Int(args[i]) }
    case "-h", "--help":
        printUsage()
        exit(0)
    default:
        break
    }
    i += 1
}

// Read config
let configPath = NSString(string: "~/.config/wallpapers/config.json").expandingTildeInPath
guard FileManager.default.fileExists(atPath: configPath) else {
    fputs("Error: Config not found at \(configPath)\n", stderr)
    fputs("Run: mise run config:init\n", stderr)
    exit(1)
}

guard let configData = FileManager.default.contents(atPath: configPath) else {
    fputs("Error: Could not read config file\n", stderr)
    exit(1)
}

// Try new format first, fall back to legacy
let config: SpaceConfig
do {
    config = try JSONDecoder().decode(SpaceConfig.self, from: configData)
} catch {
    // Try legacy format
    do {
        let legacy = try JSONDecoder().decode(LegacyConfig.self, from: configData)
        config = convertLegacy(legacy)
    } catch let legacyError {
        fputs("Error: Invalid config JSON - \(legacyError.localizedDescription)\n", stderr)
        exit(1)
    }
}

if config.spaces.isEmpty {
    fputs("Error: No spaces defined in config\n", stderr)
    exit(1)
}

// Generate wallpapers
let outputDir = NSString(string: "~/.local/share/wallpapers").expandingTildeInPath
var generatedFiles: [String] = []

for (index, space) in config.spaces.enumerated() {
    let zoneNames = space.zones.map(\.name).joined(separator: " + ")
    print("[\(index + 1)/\(config.spaces.count)] Generating: \(zoneNames)")

    // Resolution: CLI args > first zone > defaults > 1080p
    let width: Int
    let height: Int
    if let w = customWidth, let h = customHeight {
        width = w
        height = h
    } else if let firstZone = space.zones.first,
              let w = firstZone.width, let h = firstZone.height {
        width = w
        height = h
    } else if let firstZone = space.zones.first,
              let res = firstZone.resolution ?? config.defaults?.resolution,
              let preset = resolutions[res] {
        width = preset.width
        height = preset.height
    } else {
        width = 1920
        height = 1080
    }

    if space.zones.count == 1 {
        // Single zone — use simple path (no chrome/rounding)
        let zone = space.zones[0]
        let params = makeZoneParams(zone: zone, defaults: config.defaults)

        let bgColorHex = zone.bgColor ?? config.defaults?.bgColor ?? "#000000"
        let textColorHex = zone.textColor ?? config.defaults?.textColor ?? "#ffffff"

        if let path = generateWallpaper(
            name: zone.name,
            description: zone.description,
            width: width,
            height: height,
            bgColor: bgColorHex,
            textColor: textColorHex,
            workspaceId: zone.id,
            spaceIndex: index + 1,
            outputDir: outputDir,
            style: params.style,
            enableWatermark: params.enableWatermark,
            watermarkOpacity: params.watermarkOpacity,
            enableBorderText: params.enableBorderText,
            borderOpacity: params.borderOpacity,
            gradientOpacity: params.gradientOpacity
        ) {
            generatedFiles.append(path)
        } else {
            fputs("Error generating wallpaper for '\(zone.name)'\n", stderr)
            exit(1)
        }
    } else {
        // Multi-zone — use space wallpaper with flex layout
        let gap = CGFloat(space.gap ?? config.defaults?.gap ?? 8)
        let cornerRadius = CGFloat(space.cornerRadius ?? config.defaults?.cornerRadius ?? 10)
        let chromeColorHex = space.chromeColor ?? config.defaults?.chromeColor ?? "#000000"
        let chrome = parseHexColor(chromeColorHex) ?? (r: 0, g: 0, b: 0)

        let spaceZones = space.zones.map { zone -> SpaceZone in
            let params = makeZoneParams(zone: zone, defaults: config.defaults)
            return SpaceZone(zone: params, flex: CGFloat(zone.flex ?? 1))
        }

        if let path = generateSpaceWallpaper(
            zones: spaceZones,
            width: width,
            height: height,
            spaceIndex: index + 1,
            outputDir: outputDir,
            gap: gap,
            cornerRadius: cornerRadius,
            chromeColor: chrome
        ) {
            generatedFiles.append(path)
        } else {
            fputs("Error generating space wallpaper\n", stderr)
            exit(1)
        }
    }
}

print("\nGenerated \(generatedFiles.count) wallpaper(s)")

if generateOnly {
    print("MODE:generate-only")
} else {
    print("MODE:apply")
    for file in generatedFiles {
        print("FILE:\(file)")
    }
}

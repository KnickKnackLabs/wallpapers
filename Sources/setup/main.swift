import Foundation
import WallpaperKit

// MARK: - Config Models

struct Workspace: Codable {
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
}

struct Config: Codable {
    let workspaces: [Workspace]
    let defaults: Defaults?
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

let config: Config
do {
    config = try JSONDecoder().decode(Config.self, from: configData)
} catch {
    fputs("Error: Invalid config JSON - \(error.localizedDescription)\n", stderr)
    exit(1)
}

if config.workspaces.isEmpty {
    fputs("Error: No workspaces defined in config\n", stderr)
    exit(1)
}

// Generate wallpapers directly via WallpaperKit
var generatedFiles: [String] = []

for (index, workspace) in config.workspaces.enumerated() {
    print("[\(index + 1)/\(config.workspaces.count)] Generating: \(workspace.name)")

    // Colors (workspace -> defaults -> hardcoded)
    let bgColor = workspace.bgColor ?? config.defaults?.bgColor ?? "#000000"
    let textColor = workspace.textColor ?? config.defaults?.textColor ?? "#ffffff"

    // Resolution: CLI args > workspace > defaults > 1080p
    let width: Int
    let height: Int
    if let w = customWidth, let h = customHeight {
        width = w
        height = h
    } else if let w = workspace.width, let h = workspace.height {
        width = w
        height = h
    } else if let res = workspace.resolution ?? config.defaults?.resolution,
              let preset = resolutions[res] {
        width = preset.width
        height = preset.height
    } else {
        width = 1920
        height = 1080
    }

    // Style (workspace -> defaults -> classic)
    let styleName = workspace.style ?? config.defaults?.style ?? "classic"
    let style = WallpaperStyle(rawValue: styleName) ?? .classic

    // Classic-specific decorations
    let enableWatermark = style == .classic && (workspace.watermark ?? config.defaults?.watermark ?? true)
    let enableBorderText = style == .classic && (workspace.borderText ?? config.defaults?.borderText ?? true)
    let borderOpacity = workspace.borderOpacity ?? config.defaults?.borderOpacity ?? 0.15
    let watermarkOpacity = workspace.watermarkOpacity ?? config.defaults?.watermarkOpacity ?? 0.08
    let gradientOpacity = workspace.gradientOpacity ?? config.defaults?.gradientOpacity ?? 0.4

    if let path = generateWallpaper(
        name: workspace.name,
        description: workspace.description,
        width: width,
        height: height,
        bgColor: bgColor,
        textColor: textColor,
        workspaceId: workspace.id,
        spaceIndex: index + 1,
        outputDir: NSString(string: "~/.local/share/wallpapers").expandingTildeInPath,
        style: style,
        enableWatermark: enableWatermark,
        watermarkOpacity: CGFloat(watermarkOpacity),
        enableBorderText: enableBorderText,
        borderOpacity: CGFloat(borderOpacity),
        gradientOpacity: CGFloat(gradientOpacity)
    ) {
        generatedFiles.append(path)
    } else {
        fputs("Error generating wallpaper for '\(workspace.name)'\n", stderr)
        exit(1)
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

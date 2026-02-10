import Foundation
import WallpaperKit

func printUsage() {
    let usage = """
    Usage: generate <name> [options]

    Options:
      -d, --description <text>    Optional description text
      -r, --resolution <preset>   Resolution preset (default: 1080p)
                                  Options: 1080p, 1440p, 4k, macbook-14,
                                           macbook-16, imac-24, studio-display
      --width <pixels>            Custom width (overrides preset)
      --height <pixels>           Custom height (overrides preset)
      --bg-color <hex>            Background color (default: #000000)
      --text-color <hex>          Text color (default: #ffffff)
      --id <slug>                 Workspace ID for filename (default: derived from name)
      --index <n>                 Space index for filename (e.g., 1, 2, 3)
      -o, --output-dir <path>     Output directory (default: ~/.local/share/wallpapers)
      --style <name>              Visual style: classic, diagonal, tiled,
                                  flowfield, typography, perspective (default: classic)
      --watermark                 Add centered watermark text (classic style)
      --watermark-opacity <n>     Watermark opacity 0.0-1.0 (default: 0.08)
      --border-text               Add repeated text around border (classic style)
      --border-opacity <n>        Border text opacity 0.0-1.0 (default: 0.15)
      --gradient-opacity <n>      Bottom gradient opacity 0.0-1.0 (default: 0.4)
      -h, --help                  Show this help message
    """
    print(usage)
}

var args = Array(CommandLine.arguments.dropFirst())

var name: String?
var description: String?
var resolution = "1080p"
var customWidth: Int?
var customHeight: Int?
var bgColor = "#000000"
var textColor = "#ffffff"
var workspaceId: String?
var spaceIndex: Int?
var outputDir = NSString(string: "~/.local/share/wallpapers").expandingTildeInPath
var style: WallpaperStyle = .classic
var enableWatermark = false
var watermarkOpacity: CGFloat = 0.08
var enableBorderText = false
var borderOpacity: CGFloat = 0.15
var gradientOpacity: CGFloat = 0.4

var i = 0
while i < args.count {
    let arg = args[i]

    switch arg {
    case "-h", "--help":
        printUsage()
        exit(0)

    case "-d", "--description":
        i += 1
        if i < args.count { description = args[i] }

    case "-r", "--resolution":
        i += 1
        if i < args.count { resolution = args[i] }

    case "--width":
        i += 1
        if i < args.count { customWidth = Int(args[i]) }

    case "--height":
        i += 1
        if i < args.count { customHeight = Int(args[i]) }

    case "--bg-color":
        i += 1
        if i < args.count { bgColor = args[i] }

    case "--text-color":
        i += 1
        if i < args.count { textColor = args[i] }

    case "--id":
        i += 1
        if i < args.count { workspaceId = args[i] }

    case "--index":
        i += 1
        if i < args.count { spaceIndex = Int(args[i]) }

    case "-o", "--output-dir":
        i += 1
        if i < args.count { outputDir = args[i] }

    case "--style":
        i += 1
        if i < args.count, let s = WallpaperStyle(rawValue: args[i]) {
            style = s
        }

    case "--watermark":
        enableWatermark = true

    case "--watermark-opacity":
        i += 1
        if i < args.count { watermarkOpacity = CGFloat(Double(args[i]) ?? 0.08) }

    case "--border-text":
        enableBorderText = true

    case "--border-opacity":
        i += 1
        if i < args.count { borderOpacity = CGFloat(Double(args[i]) ?? 0.15) }

    case "--gradient-opacity":
        i += 1
        if i < args.count { gradientOpacity = CGFloat(Double(args[i]) ?? 0.4) }

    default:
        if !arg.hasPrefix("-") && name == nil {
            name = arg
        }
    }

    i += 1
}

guard let workspaceName = name else {
    fputs("Error: Workspace name is required\n", stderr)
    printUsage()
    exit(1)
}

let width: Int
let height: Int

if let w = customWidth, let h = customHeight {
    width = w
    height = h
} else if let preset = resolutions[resolution] {
    width = preset.width
    height = preset.height
} else {
    fputs("Error: Unknown resolution preset '\(resolution)'\n", stderr)
    exit(1)
}

if let outputPath = generateWallpaper(
    name: workspaceName,
    description: description,
    width: width,
    height: height,
    bgColor: bgColor,
    textColor: textColor,
    workspaceId: workspaceId,
    spaceIndex: spaceIndex,
    outputDir: outputDir,
    style: style,
    enableWatermark: enableWatermark,
    watermarkOpacity: watermarkOpacity,
    enableBorderText: enableBorderText,
    borderOpacity: borderOpacity,
    gradientOpacity: gradientOpacity
) {
    print("Generated: \(outputPath)")
} else {
    exit(1)
}

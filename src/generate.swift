#!/usr/bin/env swift
//
// Wallpaper generator for macOS workspace identification.
// Uses native Core Graphics - no external dependencies required.
//

import Foundation
import AppKit  // For NSAttributedString keys and image writing
import CoreText
import UniformTypeIdentifiers
import ImageIO

// MARK: - Resolution Presets

let resolutions: [String: (width: Int, height: Int)] = [
    "1080p": (1920, 1080),
    "1440p": (2560, 1440),
    "4k": (3840, 2160),
    "macbook-14": (3024, 1964),
    "macbook-16": (3456, 2234),
    "imac-24": (4480, 2520),
    "studio-display": (5120, 2880),
]

// MARK: - Text Direction

/// Detects if text contains RTL characters (Hebrew, Arabic, etc.)
func isRTL(_ text: String) -> Bool {
    for scalar in text.unicodeScalars {
        // Hebrew: U+0590 to U+05FF
        // Arabic: U+0600 to U+06FF, U+0750 to U+077F, U+08A0 to U+08FF
        // Arabic Extended: U+FB50 to U+FDFF, U+FE70 to U+FEFF
        let value = scalar.value
        if (0x0590...0x05FF).contains(value) ||  // Hebrew
           (0x0600...0x06FF).contains(value) ||  // Arabic
           (0x0750...0x077F).contains(value) ||  // Arabic Supplement
           (0x08A0...0x08FF).contains(value) ||  // Arabic Extended-A
           (0xFB50...0xFDFF).contains(value) ||  // Arabic Presentation Forms-A
           (0xFE70...0xFEFF).contains(value) {   // Arabic Presentation Forms-B
            return true
        }
    }
    return false
}

// MARK: - Color Helpers

func parseHexColor(_ hex: String) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hexString.hasPrefix("#") {
        hexString.removeFirst()
    }

    guard hexString.count == 6,
          let hexValue = UInt64(hexString, radix: 16) else {
        return nil
    }

    let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
    let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
    let b = CGFloat(hexValue & 0xFF) / 255.0

    return (r, g, b)
}

// MARK: - Wallpaper Generation

func generateWallpaper(
    name: String,
    description: String?,
    width: Int,
    height: Int,
    bgColor: String,
    textColor: String,
    outputDir: String
) -> String? {

    // Parse colors
    guard let bg = parseHexColor(bgColor),
          let text = parseHexColor(textColor) else {
        fputs("Error: Invalid color format\n", stderr)
        return nil
    }

    // Create bitmap context
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("Error: Failed to create graphics context\n", stderr)
        return nil
    }

    // Fill background
    context.setFillColor(red: bg.r, green: bg.g, blue: bg.b, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Calculate font sizes based on resolution
    let nameFontSize = CGFloat(max(48, height / 20))
    let descFontSize = CGFloat(max(24, height / 40))

    // Create fonts
    let nameFont = CTFontCreateWithName("Helvetica-Bold" as CFString, nameFontSize, nil)
    let descFont = CTFontCreateWithName("Helvetica" as CFString, descFontSize, nil)

    // Text color
    let textCGColor = CGColor(red: text.r, green: text.g, blue: text.b, alpha: 1.0)

    // Create attributed strings
    let nameAttributes: [NSAttributedString.Key: Any] = [
        .font: nameFont,
        .foregroundColor: textCGColor
    ]
    let nameAttrString = NSAttributedString(string: name, attributes: nameAttributes)
    let nameLine = CTLineCreateWithAttributedString(nameAttrString)
    let nameBounds = CTLineGetBoundsWithOptions(nameLine, [])

    var descLine: CTLine?
    var descBounds = CGRect.zero

    if let description = description, !description.isEmpty {
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: descFont,
            .foregroundColor: textCGColor
        ]
        let descAttrString = NSAttributedString(string: description, attributes: descAttributes)
        descLine = CTLineCreateWithAttributedString(descAttrString)
        descBounds = CTLineGetBoundsWithOptions(descLine!, [])
    }

    // Calculate positions (bottom-left for LTR, bottom-right for RTL)
    let margin: CGFloat = CGFloat(max(40, height / 25))  // ~4% of height
    let gap: CGFloat = 10
    let rtl = isRTL(name)

    // Description goes above the name
    // In CG coordinates, Y=0 is at bottom, so we position from bottom up
    let descY = margin
    let nameY = descLine != nil ? descY + descBounds.height + gap : margin

    // X position: left margin for LTR, right margin for RTL
    let nameX: CGFloat
    let descX: CGFloat

    if rtl {
        // Right-align for RTL
        nameX = CGFloat(width) - margin - nameBounds.width
        descX = CGFloat(width) - margin - descBounds.width
    } else {
        // Left-align for LTR
        nameX = margin
        descX = margin
    }

    // Draw name
    context.textPosition = CGPoint(x: nameX, y: nameY)
    CTLineDraw(nameLine, context)

    // Draw description if present (below name visually, which means lower Y in CG coords)
    if let descLine = descLine {
        context.textPosition = CGPoint(x: descX, y: descY)
        CTLineDraw(descLine, context)
    }

    // Create image from context
    guard let image = context.makeImage() else {
        fputs("Error: Failed to create image\n", stderr)
        return nil
    }

    // Create output directory if needed
    let fileManager = FileManager.default
    try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Generate filename
    let safeName = name
        .lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    let filename = "\(safeName)-\(width)x\(height).png"
    let outputPath = (outputDir as NSString).appendingPathComponent(filename)
    let outputURL = URL(fileURLWithPath: outputPath)

    // Write PNG
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fputs("Error: Failed to create image destination\n", stderr)
        return nil
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        fputs("Error: Failed to write image\n", stderr)
        return nil
    }

    return outputPath
}

// MARK: - CLI

func printUsage() {
    let usage = """
    Usage: generate.swift <name> [options]

    Options:
      -d, --description <text>    Optional description text
      -r, --resolution <preset>   Resolution preset (default: 1080p)
                                  Options: 1080p, 1440p, 4k, macbook-14,
                                           macbook-16, imac-24, studio-display
      --width <pixels>            Custom width (overrides preset)
      --height <pixels>           Custom height (overrides preset)
      --bg-color <hex>            Background color (default: #000000)
      --text-color <hex>          Text color (default: #ffffff)
      -o, --output-dir <path>     Output directory (default: output)
      -h, --help                  Show this help message
    """
    print(usage)
}

func main() -> Int32 {
    var args = Array(CommandLine.arguments.dropFirst())

    // Defaults
    var name: String?
    var description: String?
    var resolution = "1080p"
    var customWidth: Int?
    var customHeight: Int?
    var bgColor = "#000000"
    var textColor = "#ffffff"
    var outputDir = "output"

    // Parse arguments
    var i = 0
    while i < args.count {
        let arg = args[i]

        switch arg {
        case "-h", "--help":
            printUsage()
            return 0

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

        case "-o", "--output-dir":
            i += 1
            if i < args.count { outputDir = args[i] }

        default:
            if !arg.hasPrefix("-") && name == nil {
                name = arg
            }
        }

        i += 1
    }

    // Validate
    guard let workspaceName = name else {
        fputs("Error: Workspace name is required\n", stderr)
        printUsage()
        return 1
    }

    // Determine dimensions
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
        return 1
    }

    // Generate
    if let outputPath = generateWallpaper(
        name: workspaceName,
        description: description,
        width: width,
        height: height,
        bgColor: bgColor,
        textColor: textColor,
        outputDir: outputDir
    ) {
        print("Generated: \(outputPath)")
        return 0
    }

    return 1
}

exit(main())

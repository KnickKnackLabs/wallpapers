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

// MARK: - Style System

enum WallpaperStyle: String {
    case classic
    case diagonal
    case tiled
    case flowfield
    case typography
    case perspective
}

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

/// Perceived luminance (0 = dark, 1 = bright)
func luminance(_ c: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
}

/// Returns a decoration color that contrasts with the background.
/// On dark backgrounds: lighten the bg. On bright backgrounds: darken it.
func decorationColor(_ bg: (r: CGFloat, g: CGFloat, b: CGFloat)) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
    if luminance(bg) > 0.5 {
        // Bright bg: darken
        return (r: bg.r * 0.4, g: bg.g * 0.4, b: bg.b * 0.4)
    } else {
        // Dark bg: lighten
        return (r: min(1, bg.r + 0.4), g: min(1, bg.g + 0.4), b: min(1, bg.b + 0.4))
    }
}

// MARK: - Decorations

func drawWatermark(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat), opacity: CGFloat
) {
    let fontSize = CGFloat(max(100, height / 4))
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let dc = decorationColor(bgColor)
    let color = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity)

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let attrString = NSAttributedString(string: name.uppercased(), attributes: attributes)
    let line = CTLineCreateWithAttributedString(attrString)
    let bounds = CTLineGetBoundsWithOptions(line, [])

    let angle: CGFloat = 0  // horizontal

    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: angle)
    context.textPosition = CGPoint(
        x: -(bounds.origin.x + bounds.width / 2),
        y: -(bounds.origin.y + bounds.height / 2)
    )
    CTLineDraw(line, context)
    context.restoreGState()
}

func drawBorderText(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat), opacity: CGFloat,
    margin: CGFloat
) {
    let fontSize = CGFloat(max(14, height / 80))
    let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
    let dc = decorationColor(bgColor)
    let color = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity)

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let attrString = NSAttributedString(string: name, attributes: attributes)
    let line = CTLineCreateWithAttributedString(attrString)
    let bounds = CTLineGetBoundsWithOptions(line, [])
    let textWidth = bounds.width
    let textHeight = bounds.height
    let step = textWidth + textHeight * 2  // gap = 2x text height

    let inset = margin * 0.6

    // Clockwise flow: bottom→right→top→left (like text around a circle)

    // Bottom edge: left → right
    var x = inset
    while x < CGFloat(width) - inset {
        context.textPosition = CGPoint(x: x, y: inset)
        CTLineDraw(line, context)
        x += step
    }

    // Right edge: bottom → top (rotate +90°)
    context.saveGState()
    context.translateBy(x: CGFloat(width) - inset, y: inset)
    context.rotate(by: .pi / 2)
    var pos = CGFloat(0)
    while pos < CGFloat(height) - inset * 2 {
        context.textPosition = CGPoint(x: pos, y: 0)
        CTLineDraw(line, context)
        pos += step
    }
    context.restoreGState()

    // Top edge: right → left (rotate 180°)
    context.saveGState()
    context.translateBy(x: CGFloat(width) - inset, y: CGFloat(height) - inset)
    context.rotate(by: .pi)
    x = 0
    while x < CGFloat(width) - inset * 2 {
        context.textPosition = CGPoint(x: x, y: 0)
        CTLineDraw(line, context)
        x += step
    }
    context.restoreGState()

    // Left edge: top → bottom (rotate -90°)
    context.saveGState()
    context.translateBy(x: inset, y: CGFloat(height) - inset)
    context.rotate(by: -.pi / 2)
    pos = 0
    while pos < CGFloat(height) - inset * 2 {
        context.textPosition = CGPoint(x: pos, y: 0)
        CTLineDraw(line, context)
        pos += step
    }
    context.restoreGState()
}

// MARK: - Style Renderers

/// Diagonal style: Tiled text at an angle across the entire canvas.
/// Creates a luxury fashion-brand pattern (like a monogram wallpaper).
func drawStyleDiagonal(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let fontSize = CGFloat(max(24, height / 30))
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let dc = decorationColor(bgColor)

    let text = name.uppercased()

    // Spacing between text instances (measured from sharp pass)
    let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.12)
    let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
    let sharpAttrString = NSAttributedString(string: text, attributes: sharpAttrs)
    let sharpLine = CTLineCreateWithAttributedString(sharpAttrString)
    let bounds = CTLineGetBoundsWithOptions(sharpLine, [])
    let textWidth = bounds.width
    let textHeight = bounds.height

    let hSpacing = textWidth * 1.8
    let vSpacing = textHeight * 2.5

    // Angle: 30 degrees
    let angle: CGFloat = 30.0 * .pi / 180.0

    // Cover the full canvas after rotation - use diagonal for safety
    let diagonal = sqrt(CGFloat(width * width + height * height))
    let cols = Int(ceil(diagonal / hSpacing)) + 2
    let rows = Int(ceil(diagonal / vSpacing)) + 2

    let startX = -CGFloat(cols) * hSpacing / 2
    let startY = -CGFloat(rows) * vSpacing / 2

    // Glow pass attributes
    let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.06)
    let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
    let glowAttrString = NSAttributedString(string: text, attributes: glowAttrs)
    let glowLine = CTLineCreateWithAttributedString(glowAttrString)

    // Pass 1: Soft glow - blurred shadow creates a halo behind each instance
    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: angle)
    context.setShadow(offset: .zero, blur: 8,
                      color: CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.15))

    for row in 0..<rows {
        let rowOffset: CGFloat = (row % 2 == 0) ? 0 : hSpacing / 2
        for col in 0..<cols {
            let x = startX + CGFloat(col) * hSpacing + rowOffset
            let y = startY + CGFloat(row) * vSpacing
            context.textPosition = CGPoint(x: x - textWidth / 2, y: y - textHeight / 2)
            CTLineDraw(glowLine, context)
        }
    }
    context.restoreGState()

    // Pass 2: Sharp text on top
    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: angle)

    for row in 0..<rows {
        let rowOffset: CGFloat = (row % 2 == 0) ? 0 : hSpacing / 2
        for col in 0..<cols {
            let x = startX + CGFloat(col) * hSpacing + rowOffset
            let y = startY + CGFloat(row) * vSpacing
            context.textPosition = CGPoint(x: x - textWidth / 2, y: y - textHeight / 2)
            CTLineDraw(sharpLine, context)
        }
    }
    context.restoreGState()
}

/// Tiled style: Text rotated sideways, packed tight, wall-to-wall coverage.
/// Dense typographic texture filling the entire canvas.
func drawStyleTiled(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let fontSize = CGFloat(max(18, height / 40))
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let dc = decorationColor(bgColor)

    let text = name.uppercased()

    // Measure text
    let measureColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 1.0)
    let measureAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: measureColor]
    let measureStr = NSAttributedString(string: text, attributes: measureAttrs)
    let measureLine = CTLineCreateWithAttributedString(measureStr)
    let bounds = CTLineGetBoundsWithOptions(measureLine, [])
    let textWidth = bounds.width
    let textHeight = bounds.height

    // Tight spacing - just enough gap to breathe
    let hSpacing = textWidth * 1.15
    let vSpacing = textHeight * 1.4

    // Steep angle - nearly sideways
    let angle: CGFloat = 75.0 * .pi / 180.0

    let diagonal = sqrt(CGFloat(width * width + height * height))
    let cols = Int(ceil(diagonal / hSpacing)) + 2
    let rows = Int(ceil(diagonal / vSpacing)) + 2

    let startX = -CGFloat(cols) * hSpacing / 2
    let startY = -CGFloat(rows) * vSpacing / 2

    // Glow pass
    let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.05)
    let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
    let glowLine = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: glowAttrs))

    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: angle)
    context.setShadow(offset: .zero, blur: 6,
                      color: CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.12))

    for row in 0..<rows {
        for col in 0..<cols {
            let x = startX + CGFloat(col) * hSpacing
            let y = startY + CGFloat(row) * vSpacing
            context.textPosition = CGPoint(x: x - textWidth / 2, y: y - textHeight / 2)
            CTLineDraw(glowLine, context)
        }
    }
    context.restoreGState()

    // Sharp pass
    let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.10)
    let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
    let sharpLine = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: sharpAttrs))

    context.saveGState()
    context.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    context.rotate(by: angle)

    for row in 0..<rows {
        for col in 0..<cols {
            let x = startX + CGFloat(col) * hSpacing
            let y = startY + CGFloat(row) * vSpacing
            context.textPosition = CGPoint(x: x - textWidth / 2, y: y - textHeight / 2)
            CTLineDraw(sharpLine, context)
        }
    }
    context.restoreGState()
}

// MARK: - Wallpaper Generation

func generateWallpaper(
    name: String,
    description: String?,
    width: Int,
    height: Int,
    bgColor: String,
    textColor: String,
    workspaceId: String?,
    spaceIndex: Int?,
    outputDir: String,
    style: WallpaperStyle = .classic,
    enableWatermark: Bool = false,
    watermarkOpacity: CGFloat = 0.08,
    enableBorderText: Bool = false,
    borderOpacity: CGFloat = 0.15,
    gradientOpacity: CGFloat = 0.4
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

    // Draw style-specific decorations (behind main title)
    let margin: CGFloat = CGFloat(max(40, height / 25))

    switch style {
    case .classic:
        if enableWatermark {
            drawWatermark(
                context: context, name: name, width: width, height: height,
                bgColor: bg, opacity: watermarkOpacity
            )
        }
        if enableBorderText {
            drawBorderText(
                context: context, name: name, width: width, height: height,
                bgColor: bg, opacity: borderOpacity, margin: margin
            )
        }

    case .diagonal:
        drawStyleDiagonal(
            context: context, name: name, width: width, height: height,
            bgColor: bg
        )

    case .tiled:
        drawStyleTiled(
            context: context, name: name, width: width, height: height,
            bgColor: bg
        )

    case .flowfield, .typography, .perspective:
        break  // stubs - to be implemented
    }

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

    // Subtle gradient at bottom to lift title area
    let gradientHeight = margin * 3
    let gradientColors = [
        CGColor(red: bg.r, green: bg.g, blue: bg.b, alpha: gradientOpacity),
        CGColor(red: bg.r, green: bg.g, blue: bg.b, alpha: 0.0)
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0, 1]) {
        context.saveGState()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: gradientHeight),
            options: []
        )
        context.restoreGState()
    }

    // Shadow color: darken the background color (works for both light and dark bgs)
    let shadowR = bg.r * 0.3
    let shadowG = bg.g * 0.3
    let shadowB = bg.b * 0.3

    // Draw name and description with double shadow for depth
    // First pass: large soft shadow for atmosphere
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -4), blur: 24,
                      color: CGColor(red: shadowR, green: shadowG, blue: shadowB, alpha: 0.7))

    context.textPosition = CGPoint(x: nameX, y: nameY)
    CTLineDraw(nameLine, context)

    if let descLine = descLine {
        context.textPosition = CGPoint(x: descX, y: descY)
        CTLineDraw(descLine, context)
    }
    context.restoreGState()

    // Second pass: tight shadow for definition
    context.saveGState()
    context.setShadow(offset: CGSize(width: 1, height: -1), blur: 3,
                      color: CGColor(red: shadowR, green: shadowG, blue: shadowB, alpha: 0.9))

    context.textPosition = CGPoint(x: nameX, y: nameY)
    CTLineDraw(nameLine, context)

    if let descLine = descLine {
        context.textPosition = CGPoint(x: descX, y: descY)
        CTLineDraw(descLine, context)
    }
    context.restoreGState()

    // Create image from context
    guard let image = context.makeImage() else {
        fputs("Error: Failed to create image\n", stderr)
        return nil
    }

    // Create output directory if needed
    let fileManager = FileManager.default
    try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Generate filename: {id}.{index}.png
    // ID defaults to slugified name if not provided
    let slug = workspaceId ?? name
        .lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .filter { $0.isLetter || $0.isNumber || $0 == "-" }

    let filename: String
    if let index = spaceIndex {
        filename = "\(slug).\(index).png"
    } else {
        filename = "\(slug).png"
    }
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
      --id <slug>                 Workspace ID for filename (default: derived from name)
      --index <n>                 Space index for filename (e.g., 1, 2, 3)
      -o, --output-dir <path>     Output directory (default: ~/.local/share/wallpapers)
      --style <name>              Visual style: classic, diagonal, tiled,
                                  flowfield, typography, perspective (default: classic)
      --watermark                 Add diagonal watermark text (classic style)
      --watermark-opacity <n>     Watermark opacity 0.0-1.0 (default: 0.08)
      --border-text               Add repeated text around border
      --border-opacity <n>        Border text opacity 0.0-1.0 (default: 0.15)
      --gradient-opacity <n>      Bottom gradient opacity 0.0-1.0 (default: 0.4)
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
    var workspaceId: String?
    var spaceIndex: Int?
    var outputDir = NSString(string: "~/.local/share/wallpapers").expandingTildeInPath
    var style: WallpaperStyle = .classic
    var enableWatermark = false
    var watermarkOpacity: CGFloat = 0.08
    var enableBorderText = false
    var borderOpacity: CGFloat = 0.15
    var gradientOpacity: CGFloat = 0.4

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
        return 0
    }

    return 1
}

exit(main())

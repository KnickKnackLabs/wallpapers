import Foundation
import AppKit
import CoreGraphics
import CoreText
import UniformTypeIdentifiers
import ImageIO

// MARK: - Zone rendering (reusable core)

/// Parameters describing a single zone to render.
public struct ZoneParams {
    public let name: String
    public let description: String?
    public let bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
    public let textColor: (r: CGFloat, g: CGFloat, b: CGFloat)
    public let style: WallpaperStyle
    public let enableWatermark: Bool
    public let watermarkOpacity: CGFloat
    public let enableBorderText: Bool
    public let borderOpacity: CGFloat
    public let gradientOpacity: CGFloat

    public init(
        name: String, description: String? = nil,
        bgColor: (r: CGFloat, g: CGFloat, b: CGFloat),
        textColor: (r: CGFloat, g: CGFloat, b: CGFloat),
        style: WallpaperStyle = .classic,
        enableWatermark: Bool = false, watermarkOpacity: CGFloat = 0.08,
        enableBorderText: Bool = false, borderOpacity: CGFloat = 0.15,
        gradientOpacity: CGFloat = 0.4
    ) {
        self.name = name
        self.description = description
        self.bgColor = bgColor
        self.textColor = textColor
        self.style = style
        self.enableWatermark = enableWatermark
        self.watermarkOpacity = watermarkOpacity
        self.enableBorderText = enableBorderText
        self.borderOpacity = borderOpacity
        self.gradientOpacity = gradientOpacity
    }
}

/// Render a single zone's content into the current context.
/// Assumes the context is already translated so (0,0) is the zone's origin,
/// and optionally clipped to the zone's bounds.
public func renderZone(
    context: CGContext, zone: ZoneParams, width: Int, height: Int
) {
    let bg = zone.bgColor
    let text = zone.textColor

    // Fill background
    context.setFillColor(red: bg.r, green: bg.g, blue: bg.b, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Draw style-specific decorations
    let margin: CGFloat = CGFloat(max(40, height / 25))

    switch zone.style {
    case .classic:
        if zone.enableWatermark {
            drawWatermark(
                context: context, name: zone.name, width: width, height: height,
                bgColor: bg, opacity: zone.watermarkOpacity
            )
        }
        if zone.enableBorderText {
            drawBorderText(
                context: context, name: zone.name, width: width, height: height,
                bgColor: bg, opacity: zone.borderOpacity, margin: margin
            )
        }

    case .diagonal:
        drawStyleDiagonal(
            context: context, name: zone.name, width: width, height: height,
            bgColor: bg
        )

    case .tiled:
        drawStyleTiled(
            context: context, name: zone.name, width: width, height: height,
            bgColor: bg
        )

    case .flowfield:
        drawStyleFlowfield(
            context: context, name: zone.name, width: width, height: height,
            bgColor: bg
        )

    case .typography:
        drawStyleTypography(
            context: context, name: zone.name, width: width, height: height,
            bgColor: bg
        )

    case .perspective:
        drawStylePerspective(
            context: context, name: zone.name, width: width, height: height,
            bgColor: bg
        )
    }

    // Title and description rendering
    let nameFontSize = CGFloat(max(48, height / 20))
    let descFontSize = CGFloat(max(24, height / 40))

    let nameFont = CTFontCreateWithName("Helvetica-Bold" as CFString, nameFontSize, nil)
    let descFont = CTFontCreateWithName("Helvetica" as CFString, descFontSize, nil)

    let textCGColor = CGColor(red: text.r, green: text.g, blue: text.b, alpha: 1.0)

    let nameAttributes: [NSAttributedString.Key: Any] = [
        .font: nameFont,
        .foregroundColor: textCGColor
    ]
    let nameAttrString = NSAttributedString(string: zone.name, attributes: nameAttributes)
    let nameLine = CTLineCreateWithAttributedString(nameAttrString)
    let nameBounds = CTLineGetBoundsWithOptions(nameLine, [])

    var descLine: CTLine?
    var descBounds = CGRect.zero

    if let description = zone.description, !description.isEmpty {
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: descFont,
            .foregroundColor: textCGColor
        ]
        let descAttrString = NSAttributedString(string: description, attributes: descAttributes)
        descLine = CTLineCreateWithAttributedString(descAttrString)
        descBounds = CTLineGetBoundsWithOptions(descLine!, [])
    }

    let gap: CGFloat = 10
    let rtl = isRTL(zone.name)

    let descY = margin
    let nameY = descLine != nil ? descY + descBounds.height + gap : margin

    let nameX: CGFloat
    let descX: CGFloat

    if rtl {
        nameX = CGFloat(width) - margin - nameBounds.width
        descX = CGFloat(width) - margin - descBounds.width
    } else {
        nameX = margin
        descX = margin
    }

    // Bottom gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientHeight = margin * 3
    let gradientColors = [
        CGColor(red: bg.r, green: bg.g, blue: bg.b, alpha: zone.gradientOpacity),
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

    // Double shadow for depth
    let shadowR = bg.r * 0.3
    let shadowG = bg.g * 0.3
    let shadowB = bg.b * 0.3

    // First pass: large soft shadow
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
}

// MARK: - Space wallpaper (multi-zone)

/// Parameters for a zone within a space layout.
public struct SpaceZone {
    public let zone: ZoneParams
    public let flex: CGFloat

    public init(zone: ZoneParams, flex: CGFloat = 1) {
        self.zone = zone
        self.flex = flex
    }
}

/// Generate a wallpaper for a space containing one or more zones.
/// Zones are laid out left-to-right using flex proportions, with rounded
/// corners and chrome (dark background) between them.
public func generateSpaceWallpaper(
    zones: [SpaceZone],
    width: Int,
    height: Int,
    spaceIndex: Int?,
    outputDir: String,
    gap: CGFloat = 8,
    cornerRadius: CGFloat = 10,
    chromeColor: (r: CGFloat, g: CGFloat, b: CGFloat) = (0, 0, 0)
) -> String? {
    guard !zones.isEmpty else { return nil }

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

    let w = CGFloat(width)
    let h = CGFloat(height)

    // Fill chrome background
    context.setFillColor(red: chromeColor.r, green: chromeColor.g, blue: chromeColor.b, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: w, height: h))

    // Compute zone rects from flex values.
    // Gap applies between zones AND around the edges (like CSS padding).
    let edgeGaps = gap * 2  // left + right
    let innerGaps = CGFloat(zones.count - 1) * gap
    let availableWidth = w - edgeGaps - innerGaps
    let availableHeight = h - gap * 2  // top + bottom
    let totalFlex = zones.map(\.flex).reduce(0, +)

    var offsetX = gap
    for sz in zones {
        let zoneWidth = availableWidth * (sz.flex / totalFlex)
        let zoneRect = CGRect(x: offsetX, y: gap, width: zoneWidth, height: availableHeight)

        context.saveGState()

        // Clip to rounded rect
        let clipPath = CGPath(roundedRect: zoneRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(clipPath)
        context.clip()

        // Translate so zone renders from (0,0)
        context.translateBy(x: zoneRect.origin.x, y: zoneRect.origin.y)

        // Render zone content at zone dimensions
        renderZone(context: context, zone: sz.zone, width: Int(zoneWidth), height: Int(availableHeight))

        context.restoreGState()

        offsetX += zoneWidth + gap
    }

    // Export PNG
    guard let image = context.makeImage() else {
        fputs("Error: Failed to create image\n", stderr)
        return nil
    }

    let fileManager = FileManager.default
    try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Use first zone's name for the filename slug
    let firstZone = zones[0].zone
    let slug = firstZone.name
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

// MARK: - Single wallpaper (backward compat)

/// Generate a single wallpaper. Wraps the zone rendering system for
/// backward compatibility with the CLI and old config format.
public func generateWallpaper(
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

    guard let bg = parseHexColor(bgColor),
          let text = parseHexColor(textColor) else {
        fputs("Error: Invalid color format\n", stderr)
        return nil
    }

    let zone = ZoneParams(
        name: name, description: description,
        bgColor: bg, textColor: text,
        style: style,
        enableWatermark: enableWatermark, watermarkOpacity: watermarkOpacity,
        enableBorderText: enableBorderText, borderOpacity: borderOpacity,
        gradientOpacity: gradientOpacity
    )

    // Single zone = no chrome, no rounding, no gap
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

    renderZone(context: context, zone: zone, width: width, height: height)

    // Export PNG
    guard let image = context.makeImage() else {
        fputs("Error: Failed to create image\n", stderr)
        return nil
    }

    let fileManager = FileManager.default
    try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

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

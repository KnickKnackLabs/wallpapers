import Foundation
import AppKit
import CoreGraphics
import CoreText
import UniformTypeIdentifiers
import ImageIO

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

    // Draw style-specific decorations
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

    case .flowfield:
        drawStyleFlowfield(
            context: context, name: name, width: width, height: height,
            bgColor: bg
        )

    case .typography:
        drawStyleTypography(
            context: context, name: name, width: width, height: height,
            bgColor: bg
        )

    case .perspective:
        drawStylePerspective(
            context: context, name: name, width: width, height: height,
            bgColor: bg
        )
    }

    // Title and description rendering (common to all styles)
    let nameFontSize = CGFloat(max(48, height / 20))
    let descFontSize = CGFloat(max(24, height / 40))

    let nameFont = CTFontCreateWithName("Helvetica-Bold" as CFString, nameFontSize, nil)
    let descFont = CTFontCreateWithName("Helvetica" as CFString, descFontSize, nil)

    let textCGColor = CGColor(red: text.r, green: text.g, blue: text.b, alpha: 1.0)

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

    let gap: CGFloat = 10
    let rtl = isRTL(name)

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

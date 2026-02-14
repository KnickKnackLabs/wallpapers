import CoreGraphics
import CoreText
import AppKit

/// Tiled style: Text rotated sideways, packed tight, wall-to-wall coverage.
/// Dense typographic texture filling the entire canvas.
public func drawStyleTiled(
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
    let measureLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: measureAttrs))
    let bounds = CTLineGetBoundsWithOptions(measureLine, [])
    let textWidth = bounds.width
    let textHeight = bounds.height

    let hSpacing = textWidth * 1.15
    let vSpacing = textHeight * 1.4
    let angle: CGFloat = 75.0 * .pi / 180.0

    let diagonal = sqrt(CGFloat(width * width + height * height))
    let cols = Int(ceil(diagonal / hSpacing)) + 2
    let rows = Int(ceil(diagonal / vSpacing)) + 2

    let startX = -CGFloat(cols) * hSpacing / 2
    let startY = -CGFloat(rows) * vSpacing / 2

    // Glow pass
    let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.05)
    let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
    let glowLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: glowAttrs))

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
    let sharpLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: sharpAttrs))

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

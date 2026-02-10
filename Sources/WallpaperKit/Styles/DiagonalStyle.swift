import CoreGraphics
import CoreText
import AppKit

/// Diagonal style: Tiled text at 30° across the entire canvas.
/// Creates a luxury fashion-brand pattern with dual-layer glow.
public func drawStyleDiagonal(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let fontSize = CGFloat(max(24, height / 30))
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let dc = decorationColor(bgColor)

    let text = name.uppercased()

    // Measure text from sharp pass
    let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.12)
    let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
    let sharpLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: sharpAttrs))
    let bounds = CTLineGetBoundsWithOptions(sharpLine, [])
    let textWidth = bounds.width
    let textHeight = bounds.height

    let hSpacing = textWidth * 1.8
    let vSpacing = textHeight * 2.5
    let angle: CGFloat = 30.0 * .pi / 180.0

    let diagonal = sqrt(CGFloat(width * width + height * height))
    let cols = Int(ceil(diagonal / hSpacing)) + 2
    let rows = Int(ceil(diagonal / vSpacing)) + 2

    let startX = -CGFloat(cols) * hSpacing / 2
    let startY = -CGFloat(rows) * vSpacing / 2

    // Glow pass
    let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: 0.06)
    let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
    let glowLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: glowAttrs))

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

    // Sharp pass
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

import CoreGraphics
import CoreText
import AppKit

public func drawWatermark(
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

    let angle: CGFloat = 0

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

public func drawBorderText(
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
    let step = textWidth + textHeight * 2

    let inset = margin * 0.6

    // Bottom edge: left -> right
    var x = inset
    while x < CGFloat(width) - inset {
        context.textPosition = CGPoint(x: x, y: inset)
        CTLineDraw(line, context)
        x += step
    }

    // Right edge: bottom -> top
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

    // Top edge: right -> left
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

    // Left edge: top -> bottom
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

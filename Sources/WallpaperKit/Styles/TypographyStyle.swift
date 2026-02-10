import CoreGraphics
import CoreText
import AppKit

/// Typography style: Scattered text at varying sizes, weights, and opacities.
/// Design-poster aesthetic with compositional depth.
public func drawStyleTypography(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let dc = decorationColor(bgColor)
    let text = name.uppercased()
    let w = CGFloat(width)
    let h = CGFloat(height)

    struct Layer {
        let count: Int
        let minSize: CGFloat
        let maxSize: CGFloat
        let minOpacity: CGFloat
        let maxOpacity: CGFloat
        let maxRotation: CGFloat
        let blur: CGFloat
    }

    let layers: [Layer] = [
        // Background giants - very large, very faint
        Layer(count: 3, minSize: h * 0.15, maxSize: h * 0.28,
              minOpacity: 0.03, maxOpacity: 0.05, maxRotation: 25, blur: 10),
        // Mid-layer - medium text, moderate opacity
        Layer(count: 5, minSize: h * 0.06, maxSize: h * 0.12,
              minOpacity: 0.05, maxOpacity: 0.09, maxRotation: 15, blur: 6),
        // Detail layer - smaller, slightly more visible
        Layer(count: 10, minSize: h * 0.025, maxSize: h * 0.05,
              minOpacity: 0.07, maxOpacity: 0.12, maxRotation: 10, blur: 4),
    ]

    var seed = 0
    for layer in layers {
        for _ in 0..<layer.count {
            let r0 = seededRandom(name: name, index: seed); seed += 1
            let r1 = seededRandom(name: name, index: seed); seed += 1
            let r2 = seededRandom(name: name, index: seed); seed += 1
            let r3 = seededRandom(name: name, index: seed); seed += 1
            let r4 = seededRandom(name: name, index: seed); seed += 1

            let fontSize = layer.minSize + r0 * (layer.maxSize - layer.minSize)
            let opacity = layer.minOpacity + r1 * (layer.maxOpacity - layer.minOpacity)
            let rotation = (r2 - 0.5) * 2 * layer.maxRotation * .pi / 180.0
            let x = r3 * w
            let y = r4 * h

            let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

            // Glow pass
            let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity * 0.5)
            let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
            let glowLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: glowAttrs))

            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: rotation)
            context.setShadow(offset: .zero, blur: layer.blur,
                              color: CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity))
            context.textPosition = .zero
            CTLineDraw(glowLine, context)
            context.restoreGState()

            // Sharp pass
            let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity)
            let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
            let sharpLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: sharpAttrs))

            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: rotation)
            context.textPosition = .zero
            CTLineDraw(sharpLine, context)
            context.restoreGState()
        }
    }
}

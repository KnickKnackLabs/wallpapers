import CoreGraphics

/// Flowfield style: Organic flowing lines driven by noise.
/// Creates a topographic/wind-pattern texture.
public func drawStyleFlowfield(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let dc = decorationColor(bgColor)
    let w = CGFloat(width)
    let h = CGFloat(height)

    // Seed the noise offset from the workspace name for variety
    var nameHash: UInt64 = 0
    for char in name.unicodeScalars { nameHash = nameHash &* 31 &+ UInt64(char.value) }
    let offsetX = CGFloat(nameHash % 1000)
    let offsetY = CGFloat((nameHash >> 16) % 1000)

    let noiseScale: CGFloat = 0.003
    let stepLength: CGFloat = 4
    let lineSteps = 30
    let gridSpacing: CGFloat = 12

    let cols = Int(w / gridSpacing)
    let rows = Int(h / gridSpacing)

    context.saveGState()
    context.setLineCap(.round)

    for row in 0..<rows {
        for col in 0..<cols {
            var x = CGFloat(col) * gridSpacing + gridSpacing / 2
            var y = CGFloat(row) * gridSpacing + gridSpacing / 2

            let lineNoise = noise2D(x: x * 0.01 + offsetX + 500, y: y * 0.01 + offsetY + 500)
            let opacity = 0.04 + lineNoise * 0.08
            let lineWidth = 0.5 + lineNoise * 1.0

            context.setStrokeColor(CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity))
            context.setLineWidth(lineWidth)

            context.beginPath()
            context.move(to: CGPoint(x: x, y: y))

            for _ in 0..<lineSteps {
                let n = noise2D(x: x * noiseScale + offsetX, y: y * noiseScale + offsetY)
                let angle = n * .pi * 4

                x += cos(angle) * stepLength
                y += sin(angle) * stepLength

                if x < 0 || x > w || y < 0 || y > h { break }

                context.addLine(to: CGPoint(x: x, y: y))
            }

            context.strokePath()
        }
    }

    context.restoreGState()
}

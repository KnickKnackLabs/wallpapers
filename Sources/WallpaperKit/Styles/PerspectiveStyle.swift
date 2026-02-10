import CoreGraphics
import CoreText
import AppKit

/// Perspective style: Text flows along smooth paths radiating from a vanishing point.
/// Rays repel each other so they never cross, creating organic flowing streams.
public func drawStylePerspective(
    context: CGContext, name: String, width: Int, height: Int,
    bgColor: (r: CGFloat, g: CGFloat, b: CGFloat)
) {
    let dc = decorationColor(bgColor)
    let text = name.uppercased()
    let w = CGFloat(width)
    let h = CGFloat(height)

    let vpX = w / 2
    let vpY = h / 2

    var nameHash: UInt64 = 0
    for char in name.unicodeScalars { nameHash = nameHash &* 31 &+ UInt64(char.value) }

    let rayCount = 8 + Int(nameHash % 4)  // 8-11 rays
    let baseAngle = CGFloat(nameHash % 360) * .pi / 180.0
    let margin: CGFloat = 100
    let stepSize: CGFloat = 3
    let repulsionStrength: CGFloat = 0.15

    // State for each ray
    struct RayState {
        var x: CGFloat
        var y: CGFloat
        var direction: CGFloat
        var totalDist: CGFloat = 0
        var nextPlaceDist: CGFloat = 15
        var alive: Bool = true
        let pulsePhase: CGFloat
        let noiseOffsetX: CGFloat
        let noiseOffsetY: CGFloat
    }

    var rays: [RayState] = (0..<rayCount).map { ray in
        let angle = baseAngle + CGFloat(ray) * (2 * .pi / CGFloat(rayCount))
        return RayState(
            x: vpX, y: vpY, direction: angle,
            pulsePhase: CGFloat(ray) * 1.7 + CGFloat(nameHash % 100) * 0.1,
            noiseOffsetX: CGFloat(ray) * 17.3 + CGFloat(nameHash % 200),
            noiseOffsetY: CGFloat(ray) * 5.1 + CGFloat(nameHash % 300) * 0.7
        )
    }

    // Simulate all rays simultaneously so they can repel
    let maxSteps = 2000
    for _ in 0..<maxSteps {
        // Check if any rays are still alive
        if !rays.contains(where: { $0.alive }) { break }

        for i in 0..<rayCount where rays[i].alive {
            // Noise-based gentle curve
            let noiseVal = noise2D(
                x: rays[i].totalDist * 0.004 + rays[i].noiseOffsetX,
                y: rays[i].noiseOffsetY
            )
            let nudge = (noiseVal - 0.5) * 0.04

            // Repulsion from other rays - ramps up with distance from VP
            // so rays don't explode at the origin
            let distFromVP = sqrt((rays[i].x - vpX) * (rays[i].x - vpX) +
                                  (rays[i].y - vpY) * (rays[i].y - vpY))
            let rampUp = min(distFromVP / 200, 1.0)  // 0 at VP, full at 200px out

            var repelX: CGFloat = 0
            var repelY: CGFloat = 0
            for j in 0..<rayCount where j != i && rays[j].alive {
                let dx = rays[i].x - rays[j].x
                let dy = rays[i].y - rays[j].y
                let distSq = dx * dx + dy * dy
                let minDist: CGFloat = 250
                if distSq < minDist * minDist && distSq > 1 {
                    let dist = sqrt(distSq)
                    let force = repulsionStrength * rampUp * (minDist - dist) / dist
                    repelX += dx * force
                    repelY += dy * force
                }
            }

            rays[i].direction += nudge

            // Step forward with repulsion baked into position
            rays[i].x += cos(rays[i].direction) * stepSize + repelX
            rays[i].y += sin(rays[i].direction) * stepSize + repelY

            // Update direction to match actual movement (so text rotation follows)
            if abs(repelX) > 0.01 || abs(repelY) > 0.01 {
                let moveX = cos(rays[i].direction) * stepSize + repelX
                let moveY = sin(rays[i].direction) * stepSize + repelY
                rays[i].direction = atan2(moveY, moveX)
            }
            rays[i].totalDist += stepSize

            // Kill ray if it leaves the screen
            if rays[i].x < -margin || rays[i].x > w + margin ||
               rays[i].y < -margin || rays[i].y > h + margin {
                rays[i].alive = false
                continue
            }

            // Place text when we've traveled far enough
            if rays[i].totalDist >= rays[i].nextPlaceDist {
                let depthT = min(rays[i].totalDist / (sqrt(w * w + h * h) / 2), 1.0)

                // Base size grows with distance, pulsation modulates
                let baseSize = h * 0.008 + depthT * h * 0.045
                let pulse = sin(rays[i].totalDist * 0.015 + rays[i].pulsePhase) * 0.4 + 1.0
                let fontSize = max(6, baseSize * pulse)

                let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
                let measureAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
                ]
                let measureLine = CTLineCreateWithAttributedString(
                    NSAttributedString(string: text, attributes: measureAttrs))
                let bounds = CTLineGetBoundsWithOptions(measureLine, [])

                rays[i].nextPlaceDist = rays[i].totalDist + bounds.width * 0.7

                let opacity: CGFloat = 0.03 + depthT * 0.10

                // Glow pass
                let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity * 0.5)
                let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
                let glowLine = CTLineCreateWithAttributedString(
                    NSAttributedString(string: text, attributes: glowAttrs))

                context.saveGState()
                context.translateBy(x: rays[i].x, y: rays[i].y)
                context.rotate(by: rays[i].direction)
                context.setShadow(offset: .zero, blur: fontSize * 0.15,
                                  color: CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity))
                context.textPosition = CGPoint(x: -bounds.width / 2, y: -bounds.height / 2)
                CTLineDraw(glowLine, context)
                context.restoreGState()

                // Sharp pass
                let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity)
                let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
                let sharpLine = CTLineCreateWithAttributedString(
                    NSAttributedString(string: text, attributes: sharpAttrs))

                context.saveGState()
                context.translateBy(x: rays[i].x, y: rays[i].y)
                context.rotate(by: rays[i].direction)
                context.textPosition = CGPoint(x: -bounds.width / 2, y: -bounds.height / 2)
                CTLineDraw(sharpLine, context)
                context.restoreGState()
            }
        }
    }
}

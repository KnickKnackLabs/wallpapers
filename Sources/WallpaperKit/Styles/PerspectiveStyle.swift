import CoreGraphics
import CoreText
import AppKit

// MARK: - Ray simulation (pure, testable)

/// A single point along a ray's path.
public struct RayPoint {
    public let x: CGFloat
    public let y: CGFloat
    public let direction: CGFloat
    public let totalDist: CGFloat
}

/// Simulate rays radiating from a vanishing point with angular repulsion.
/// Returns an array of paths (one per ray), where each path is a sequence of RayPoints.
public func simulateRays(
    rayCount: Int,
    baseAngle: CGFloat,
    vpX: CGFloat,
    vpY: CGFloat,
    width: CGFloat,
    height: CGFloat,
    nameHash: UInt64,
    stepSize: CGFloat = 3,
    maxSteps: Int = 2000,
    margin: CGFloat = 100,
    angularRepulsion: CGFloat = 0.06,
    repulsionThreshold: CGFloat = .pi / 2
) -> [[RayPoint]] {

    struct RayState {
        var x: CGFloat
        var y: CGFloat
        var direction: CGFloat
        var totalDist: CGFloat = 0
        var alive: Bool = true
        let noiseOffsetX: CGFloat
        let noiseOffsetY: CGFloat
    }

    var rays: [RayState] = (0..<rayCount).map { ray in
        let angle = baseAngle + CGFloat(ray) * (2 * .pi / CGFloat(rayCount))
        return RayState(
            x: vpX, y: vpY, direction: angle,
            noiseOffsetX: CGFloat(ray) * 17.3 + CGFloat(nameHash % 200),
            noiseOffsetY: CGFloat(ray) * 5.1 + CGFloat(nameHash % 300) * 0.7
        )
    }

    var paths: [[RayPoint]] = Array(repeating: [], count: rayCount)

    // Record initial positions
    for i in 0..<rayCount {
        paths[i].append(RayPoint(
            x: rays[i].x, y: rays[i].y,
            direction: rays[i].direction, totalDist: 0
        ))
    }

    for _ in 0..<maxSteps {
        if !rays.contains(where: { $0.alive }) { break }

        for i in 0..<rayCount where rays[i].alive {
            // Noise-based gentle curve
            let noiseVal = noise2D(
                x: rays[i].totalDist * 0.004 + rays[i].noiseOffsetX,
                y: rays[i].noiseOffsetY
            )
            let nudge = (noiseVal - 0.5) * 0.04

            // Angular repulsion: push directions apart
            var angularPush: CGFloat = 0
            let distFromVP = sqrt((rays[i].x - vpX) * (rays[i].x - vpX) +
                                  (rays[i].y - vpY) * (rays[i].y - vpY))
            // Decay repulsion as rays get further from center (they've already separated)
            let decay = 1.0 / (1.0 + distFromVP * 0.005)

            for j in 0..<rayCount where j != i && rays[j].alive {
                var angleDiff = rays[i].direction - rays[j].direction
                // Normalize to [-pi, pi]
                while angleDiff > .pi { angleDiff -= 2 * .pi }
                while angleDiff < -.pi { angleDiff += 2 * .pi }

                let absDiff = abs(angleDiff)
                if absDiff < repulsionThreshold && absDiff > 0.001 {
                    let force = angularRepulsion * decay * (repulsionThreshold - absDiff) / repulsionThreshold
                    // Push away: if angleDiff > 0, push more positive; if < 0, push more negative
                    angularPush += angleDiff > 0 ? force : -force
                }
            }

            rays[i].direction += nudge + angularPush

            // Step forward
            rays[i].x += cos(rays[i].direction) * stepSize
            rays[i].y += sin(rays[i].direction) * stepSize
            rays[i].totalDist += stepSize

            // Kill ray if it leaves the screen
            if rays[i].x < -margin || rays[i].x > width + margin ||
               rays[i].y < -margin || rays[i].y > height + margin {
                rays[i].alive = false
                continue
            }

            paths[i].append(RayPoint(
                x: rays[i].x, y: rays[i].y,
                direction: rays[i].direction,
                totalDist: rays[i].totalDist
            ))
        }
    }

    return paths
}

// MARK: - Rendering

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

    let paths = simulateRays(
        rayCount: rayCount, baseAngle: baseAngle,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: nameHash
    )

    let maxDist = sqrt(w * w + h * h) / 2

    for ray in 0..<rayCount {
        let pulsePhase = CGFloat(ray) * 1.7 + CGFloat(nameHash % 100) * 0.1
        var nextPlaceDist: CGFloat = 15

        for point in paths[ray] {
            guard point.totalDist >= nextPlaceDist else { continue }

            let depthT = min(point.totalDist / maxDist, 1.0)

            // Base size grows with distance, pulsation modulates
            let baseSize = h * 0.008 + depthT * h * 0.045
            let pulse = sin(point.totalDist * 0.015 + pulsePhase) * 0.4 + 1.0
            let fontSize = max(6, baseSize * pulse)

            let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
            let measureAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            ]
            let measureLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: measureAttrs))
            let bounds = CTLineGetBoundsWithOptions(measureLine, [])

            nextPlaceDist = point.totalDist + bounds.width * 0.7

            let opacity: CGFloat = 0.03 + depthT * 0.10

            // Glow pass
            let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity * 0.5)
            let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
            let glowLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: glowAttrs))

            context.saveGState()
            context.translateBy(x: point.x, y: point.y)
            context.rotate(by: point.direction)
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
            context.translateBy(x: point.x, y: point.y)
            context.rotate(by: point.direction)
            context.textPosition = CGPoint(x: -bounds.width / 2, y: -bounds.height / 2)
            CTLineDraw(sharpLine, context)
            context.restoreGState()
        }
    }
}

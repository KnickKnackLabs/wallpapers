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
            // Noise-based curve: two octaves for broad sweeps + medium detail
            let n1 = noise2D(
                x: rays[i].totalDist * 0.001 + rays[i].noiseOffsetX,
                y: rays[i].noiseOffsetY
            )
            let n2 = noise2D(
                x: rays[i].totalDist * 0.003 + rays[i].noiseOffsetX + 500,
                y: rays[i].noiseOffsetY + 500
            )
            let nudge = (n1 - 0.5) * 0.12 + (n2 - 0.5) * 0.04

            // Angular repulsion: push directions apart (heads)
            var angularPush: CGFloat = 0
            let distFromVP = sqrt((rays[i].x - vpX) * (rays[i].x - vpX) +
                                  (rays[i].y - vpY) * (rays[i].y - vpY))
            let decay = 1.0 / (1.0 + distFromVP * 0.005)

            for j in 0..<rayCount where j != i && rays[j].alive {
                var angleDiff = rays[i].direction - rays[j].direction
                while angleDiff > .pi { angleDiff -= 2 * .pi }
                while angleDiff < -.pi { angleDiff += 2 * .pi }

                let absDiff = abs(angleDiff)
                if absDiff < repulsionThreshold && absDiff > 0.001 {
                    let force = angularRepulsion * decay * (repulsionThreshold - absDiff) / repulsionThreshold
                    angularPush += angleDiff > 0 ? force : -force
                }
            }

            // Trail repulsion: repel from the entire body of other snakes
            let trailRadius: CGFloat = 80
            let trailStrength: CGFloat = 0.08
            var trailPushX: CGFloat = 0
            var trailPushY: CGFloat = 0
            let sampleStride = 5  // Check every 5th trail point for performance

            for j in 0..<rayCount where j != i {
                let trail = paths[j]
                var idx = 0
                while idx < trail.count {
                    let tp = trail[idx]
                    let dx = rays[i].x - tp.x
                    let dy = rays[i].y - tp.y
                    let distSq = dx * dx + dy * dy
                    if distSq < trailRadius * trailRadius && distSq > 1 {
                        let dist = sqrt(distSq)
                        let force = trailStrength * (trailRadius - dist) / trailRadius
                        trailPushX += (dx / dist) * force
                        trailPushY += (dy / dist) * force
                    }
                    idx += sampleStride
                }
            }

            // Convert trail push into a directional nudge
            let trailPushMag = sqrt(trailPushX * trailPushX + trailPushY * trailPushY)
            var trailAnglePush: CGFloat = 0
            if trailPushMag > 0.001 {
                let trailPushAngle = atan2(trailPushY, trailPushX)
                var diff = trailPushAngle - rays[i].direction
                while diff > .pi { diff -= 2 * .pi }
                while diff < -.pi { diff += 2 * .pi }
                trailAnglePush = diff * min(trailPushMag, 0.15)
            }

            rays[i].direction += nudge + angularPush + trailAnglePush

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

// MARK: - Path smoothing

/// Smooth a ray path using a moving average over positions.
/// Preserves totalDist (arc-length) but smooths x, y, and recomputes direction from neighbors.
public func smoothPath(_ path: [RayPoint], windowSize: Int = 7) -> [RayPoint] {
    guard path.count > windowSize else { return path }
    let half = windowSize / 2

    var smoothed: [RayPoint] = []
    for i in 0..<path.count {
        let lo = max(0, i - half)
        let hi = min(path.count - 1, i + half)
        let count = CGFloat(hi - lo + 1)

        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        for j in lo...hi {
            sumX += path[j].x
            sumY += path[j].y
        }

        let x = sumX / count
        let y = sumY / count

        // Compute tangent direction from neighbors
        let prev = max(0, i - 1)
        let next = min(path.count - 1, i + 1)
        let angle: CGFloat
        if next > prev {
            angle = atan2(path[next].y - path[prev].y, path[next].x - path[prev].x)
        } else {
            angle = path[i].direction
        }

        smoothed.append(RayPoint(x: x, y: y, direction: angle, totalDist: path[i].totalDist))
    }
    return smoothed
}

// MARK: - Path interpolation

/// Query a position and tangent angle at a given arc-length distance along a ray path.
/// Returns nil if the distance exceeds the path length.
public func pointAlongPath(_ path: [RayPoint], atDist targetDist: CGFloat) -> (x: CGFloat, y: CGFloat, angle: CGFloat)? {
    guard path.count >= 2 else { return nil }

    for i in 1..<path.count {
        let prev = path[i - 1]
        let curr = path[i]

        if curr.totalDist >= targetDist {
            // Interpolate between prev and curr
            let segLen = curr.totalDist - prev.totalDist
            guard segLen > 0 else { continue }
            let t = (targetDist - prev.totalDist) / segLen

            let x = prev.x + t * (curr.x - prev.x)
            let y = prev.y + t * (curr.y - prev.y)

            // Tangent from segment direction
            let angle = atan2(curr.y - prev.y, curr.x - prev.x)
            return (x, y, angle)
        }
    }
    return nil
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

    // Constant font size with very subtle growth
    let fontSize = h * 0.012
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

    // Measure text width once
    let measureAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    ]
    let measureLine = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: measureAttrs))
    let bounds = CTLineGetBoundsWithOptions(measureLine, [])
    let textWidth = bounds.width

    // Stride: text width + small gap
    let gap = fontSize * 0.4
    let stride = textWidth + gap

    // Skip the first bit near the vanishing point where everything converges
    let startOffset: CGFloat = 30

    let smoothedPaths = paths.map { smoothPath($0) }

    for path in smoothedPaths {
        guard let lastPoint = path.last else { continue }
        let pathLength = lastPoint.totalDist

        var dist = startOffset
        while dist < pathLength {
            guard let pos = pointAlongPath(path, atDist: dist) else { break }

            let depthT = min(dist / maxDist, 1.0)
            let opacity: CGFloat = 0.03 + depthT * 0.12

            // Glow pass
            let glowColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity * 0.5)
            let glowAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: glowColor]
            let glowLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: glowAttrs))

            context.saveGState()
            context.translateBy(x: pos.x, y: pos.y)
            context.rotate(by: pos.angle)
            context.setShadow(offset: .zero, blur: fontSize * 0.15,
                              color: CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity))
            context.textPosition = CGPoint(x: 0, y: -bounds.height / 2)
            CTLineDraw(glowLine, context)
            context.restoreGState()

            // Sharp pass
            let sharpColor = CGColor(red: dc.r, green: dc.g, blue: dc.b, alpha: opacity)
            let sharpAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: sharpColor]
            let sharpLine = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: sharpAttrs))

            context.saveGState()
            context.translateBy(x: pos.x, y: pos.y)
            context.rotate(by: pos.angle)
            context.textPosition = CGPoint(x: 0, y: -bounds.height / 2)
            CTLineDraw(sharpLine, context)
            context.restoreGState()

            dist += stride
        }
    }
}

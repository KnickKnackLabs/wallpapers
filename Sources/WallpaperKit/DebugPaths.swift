import CoreGraphics
import AppKit

/// Render just the ray paths as colored lines for debugging.
/// Each ray gets a distinct color so crossings are easy to spot.
public func debugDrawPaths(
    name: String, width: Int, height: Int,
    outputPath: String
) {
    let w = CGFloat(width)
    let h = CGFloat(height)

    var nameHash: UInt64 = 0
    for char in name.unicodeScalars { nameHash = nameHash &* 31 &+ UInt64(char.value) }

    let rayCount = 8 + Int(nameHash % 4)
    let baseAngle = CGFloat(nameHash % 360) * .pi / 180.0

    let rawPaths = simulateRays(
        rayCount: rayCount, baseAngle: baseAngle,
        vpX: w / 2, vpY: h / 2, width: w, height: h,
        nameHash: nameHash
    )
    let paths = rawPaths.map { smoothPath($0) }

    // Distinct colors for each ray
    let colors: [(CGFloat, CGFloat, CGFloat)] = [
        (1.0, 0.4, 0.4),  // red
        (0.4, 1.0, 0.4),  // green
        (0.4, 0.4, 1.0),  // blue
        (1.0, 1.0, 0.4),  // yellow
        (1.0, 0.4, 1.0),  // magenta
        (0.4, 1.0, 1.0),  // cyan
        (1.0, 0.7, 0.3),  // orange
        (0.7, 0.3, 1.0),  // purple
        (0.3, 1.0, 0.7),  // mint
        (1.0, 0.5, 0.7),  // pink
        (0.6, 0.8, 0.3),  // lime
    ]

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return }

    // Dark background
    ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

    // Draw each ray path
    for (rayIdx, path) in paths.enumerated() {
        guard path.count >= 2 else { continue }
        let c = colors[rayIdx % colors.count]

        ctx.setStrokeColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 0.8))
        ctx.setLineWidth(2.0)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: path[0].x, y: path[0].y))
        for i in 1..<path.count {
            ctx.addLine(to: CGPoint(x: path[i].x, y: path[i].y))
        }
        ctx.strokePath()

        // Draw dots at regular intervals to show direction
        for (i, point) in path.enumerated() where i % 50 == 0 {
            ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1.0))
            ctx.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
        }
    }

    // Vanishing point marker
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.8))
    ctx.fillEllipse(in: CGRect(x: w/2 - 4, y: h/2 - 4, width: 8, height: 8))

    // Export
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: outputPath) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("Debug paths: \(outputPath)")
}

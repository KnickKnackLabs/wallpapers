import Foundation
import CoreGraphics
import CoreText
import ImageIO
import AppKit
import WallpaperKit

// MARK: - Playground for ray simulation experiments
//
// Each scenario sets up a controlled simulation and renders a debug path image.
// Run: swift run playground [scenario-name] [-o output-dir]
//
// This is a permanent part of the codebase — add new scenarios as you
// explore the physics.

// MARK: - Scenario rendering

/// Render ray paths + obstacles as a debug image.
func renderScenario(
    name: String,
    paths: [[RayPoint]],
    obstacles: [[CGPoint]] = [],
    vpX: CGFloat, vpY: CGFloat,
    width: Int = 1920, height: Int = 1080,
    outputPath: String
) {
    let w = CGFloat(width)
    let h = CGFloat(height)

    let colors: [(CGFloat, CGFloat, CGFloat)] = [
        (1.0, 0.4, 0.4),  // red
        (0.4, 1.0, 0.4),  // green
        (0.4, 0.4, 1.0),  // blue
        (1.0, 1.0, 0.4),  // yellow
        (1.0, 0.4, 1.0),  // magenta
        (0.4, 1.0, 1.0),  // cyan
        (1.0, 0.7, 0.3),  // orange
        (0.7, 0.3, 1.0),  // purple
    ]

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("Failed to create context\n", stderr)
        return
    }

    // Dark background
    ctx.setFillColor(CGColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

    // Draw obstacles
    for obstacle in obstacles {
        for pt in obstacle {
            ctx.setFillColor(CGColor(red: 1, green: 0.3, blue: 0.2, alpha: 0.6))
            ctx.fillEllipse(in: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))
        }
    }

    // Draw ray paths
    let smoothedPaths = paths.map { smoothPath($0) }
    for (rayIdx, path) in smoothedPaths.enumerated() {
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

        // Direction dots
        for (i, point) in path.enumerated() where i % 50 == 0 {
            ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1.0))
            ctx.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
        }
    }

    // Vanishing point
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.8))
    ctx.fillEllipse(in: CGRect(x: vpX - 5, y: vpY - 5, width: 10, height: 10))

    // Label
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.4))
    let font = CTFontCreateWithName("Helvetica" as CFString, 14, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0.4)
    ]
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: name, attributes: attrs))
    ctx.textPosition = CGPoint(x: 20, y: 20)
    CTLineDraw(line, ctx)

    // Export
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: outputPath) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("  \(name) → \(outputPath)")
}

// MARK: - Scenarios

/// Single ray aimed right, with a point magnet in its path.
func scenarioPointMagnet(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w * 0.1, vpY = h / 2

    // One magnet point right in the ray's path
    let magnet = CGPoint(x: w * 0.5, y: h / 2)
    // Dense cluster of points to make a strong repulsive field
    let obstaclePoints = (0..<20).map { i -> CGPoint in
        let angle = CGFloat(i) * (2 * .pi / 20)
        let r: CGFloat = 5
        return CGPoint(x: magnet.x + cos(angle) * r, y: magnet.y + sin(angle) * r)
    }

    let paths = simulateRays(
        rayCount: 1, baseAngle: 0,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 42,
        angularRepulsion: 0, // no other rays to repel
        obstacles: [obstaclePoints]
    )

    renderScenario(
        name: "Point Magnet — single ray deflected by obstacle",
        paths: paths, obstacles: [obstaclePoints],
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/point-magnet.png"
    )
}

/// Single ray aimed at a wall (vertical line of points).
func scenarioWall(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w * 0.1, vpY = h / 2

    // Vertical wall at x = 60% across, spanning most of the height
    let wallX = w * 0.6
    let wallPoints = stride(from: h * 0.1, through: h * 0.9, by: 3).map { y in
        CGPoint(x: wallX, y: y)
    }

    let paths = simulateRays(
        rayCount: 1, baseAngle: 0,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 42,
        angularRepulsion: 0,
        obstacles: [wallPoints]
    )

    renderScenario(
        name: "Wall — single ray meets vertical barrier",
        paths: paths, obstacles: [wallPoints],
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/wall.png"
    )
}

/// Two rays aimed directly at each other from opposite sides.
func scenarioHeadOn(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w / 2, vpY = h / 2

    // Two rays: one going right, one going left — they start at opposite edges
    // We simulate from center with opposing angles
    let paths = simulateRays(
        rayCount: 2, baseAngle: 0,  // 0 and π (opposite directions)
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 42,
        angularRepulsion: 0.06
    )

    renderScenario(
        name: "Head-On — two rays in opposite directions",
        paths: paths, obstacles: [],
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/head-on.png"
    )
}

/// Single ray navigating a corridor (two parallel walls).
func scenarioCorridor(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w * 0.1, vpY = h / 2

    // Two horizontal walls creating a corridor
    let topWall = stride(from: w * 0.3, through: w * 0.8, by: 3).map { x in
        CGPoint(x: x, y: h * 0.35)
    }
    let bottomWall = stride(from: w * 0.3, through: w * 0.8, by: 3).map { x in
        CGPoint(x: x, y: h * 0.65)
    }

    let paths = simulateRays(
        rayCount: 1, baseAngle: 0,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 42,
        angularRepulsion: 0,
        obstacles: [topWall, bottomWall]
    )

    renderScenario(
        name: "Corridor — ray between two walls",
        paths: paths, obstacles: [topWall, bottomWall],
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/corridor.png"
    )
}

/// Fan of rays from center — the default perspective setup, for reference.
func scenarioFan(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w / 2, vpY = h / 2

    let paths = simulateRays(
        rayCount: 10, baseAngle: 0.3,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 7777
    )

    renderScenario(
        name: "Fan — 10 rays from center (reference)",
        paths: paths, obstacles: [],
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/fan.png"
    )
}

/// Rays navigating around a cluster of obstacles.
func scenarioObstacleField(outputDir: String) {
    let w: CGFloat = 1920, h: CGFloat = 1080
    let vpX = w / 2, vpY = h / 2

    // Scatter several obstacle clusters
    let clusterCenters: [CGPoint] = [
        CGPoint(x: w * 0.3, y: h * 0.3),
        CGPoint(x: w * 0.7, y: h * 0.4),
        CGPoint(x: w * 0.4, y: h * 0.7),
        CGPoint(x: w * 0.6, y: h * 0.6),
    ]

    let obstacles: [[CGPoint]] = clusterCenters.map { center in
        (0..<15).map { i in
            let angle = CGFloat(i) * (2 * .pi / 15)
            let r: CGFloat = 8
            return CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
        }
    }

    let paths = simulateRays(
        rayCount: 8, baseAngle: 0.5,
        vpX: vpX, vpY: vpY, width: w, height: h,
        nameHash: 12345,
        obstacles: obstacles
    )

    renderScenario(
        name: "Obstacle Field — rays navigating clusters",
        paths: paths, obstacles: obstacles,
        vpX: vpX, vpY: vpY,
        outputPath: "\(outputDir)/obstacle-field.png"
    )
}

// MARK: - CLI

let scenarios: [(String, (String) -> Void)] = [
    ("point-magnet", scenarioPointMagnet),
    ("wall", scenarioWall),
    ("head-on", scenarioHeadOn),
    ("corridor", scenarioCorridor),
    ("fan", scenarioFan),
    ("obstacle-field", scenarioObstacleField),
]

var args = Array(CommandLine.arguments.dropFirst())
var outputDir = "/tmp/playground"
var requestedScenario: String? = nil

var i = 0
while i < args.count {
    switch args[i] {
    case "-o", "--output-dir":
        i += 1
        if i < args.count { outputDir = args[i] }
    case "-h", "--help":
        print("""
        Usage: playground [scenario] [-o output-dir]

        Scenarios:
        \(scenarios.map { "  \($0.0)" }.joined(separator: "\n"))
          all         Run all scenarios (default)

        Output defaults to /tmp/playground/
        """)
        exit(0)
    default:
        if !args[i].hasPrefix("-") {
            requestedScenario = args[i]
        }
    }
    i += 1
}

// Create output dir
try FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true)

print("Playground → \(outputDir)/")

if let name = requestedScenario, name != "all" {
    if let scenario = scenarios.first(where: { $0.0 == name }) {
        scenario.1(outputDir)
    } else {
        fputs("Unknown scenario: \(name)\n", stderr)
        fputs("Available: \(scenarios.map { $0.0 }.joined(separator: ", "))\n", stderr)
        exit(1)
    }
} else {
    for (_, run) in scenarios {
        run(outputDir)
    }
}

print("Done!")

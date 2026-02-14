import XCTest
@testable import WallpaperKit

final class RaySimulationTests: XCTestCase {

    let width: CGFloat = 3840
    let height: CGFloat = 2160

    func testRaysSpreadApart() {
        // After simulation, adjacent rays should have more angular separation
        // than they started with (repulsion pushes them apart)
        let rayCount = 10
        let baseAngle: CGFloat = 0
        let vpX = width / 2
        let vpY = height / 2

        let paths = simulateRays(
            rayCount: rayCount, baseAngle: baseAngle,
            vpX: vpX, vpY: vpY, width: width, height: height,
            nameHash: 12345
        )

        // Measure angular spread at a distance from the vanishing point
        // by looking at ray positions ~200px out
        var anglesAtDistance: [CGFloat] = []
        for path in paths {
            if let point = path.first(where: { $0.totalDist >= 200 }) {
                let angle = atan2(point.y - vpY, point.x - vpX)
                anglesAtDistance.append(angle)
            }
        }

        anglesAtDistance.sort()
        guard anglesAtDistance.count >= 2 else {
            XCTFail("Not enough rays reached 200px distance")
            return
        }

        // Check that minimum angular gap is reasonable
        // With 10 rays around a circle, ideal spacing is 2*pi/10 = 0.628 rad
        // We allow down to half that as minimum gap
        var minGap: CGFloat = .infinity
        for i in 0..<anglesAtDistance.count {
            let j = (i + 1) % anglesAtDistance.count
            var gap = anglesAtDistance[j] - anglesAtDistance[i]
            if gap < 0 { gap += 2 * .pi }
            if i == anglesAtDistance.count - 1 {
                gap = (2 * .pi) - (anglesAtDistance.last! - anglesAtDistance.first!)
            }
            minGap = min(minGap, gap)
        }

        let idealSpacing = 2 * CGFloat.pi / CGFloat(rayCount)
        XCTAssertGreaterThan(minGap, idealSpacing * 0.3,
            "Minimum angular gap (\(minGap) rad) is too small — rays are bunching up")
    }

    func testNoRayCrossing() {
        // The angular order of rays should be preserved throughout the simulation
        let rayCount = 8
        let paths = simulateRays(
            rayCount: rayCount, baseAngle: 0.5,
            vpX: width / 2, vpY: height / 2,
            width: width, height: height,
            nameHash: 67890
        )

        // Check angular order at several distances
        let checkDistances: [CGFloat] = [50, 150, 300, 500]
        let vpX = width / 2
        let vpY = height / 2

        var previousOrder: [Int]?
        for dist in checkDistances {
            var anglesWithIndex: [(index: Int, angle: CGFloat)] = []
            for (i, path) in paths.enumerated() {
                if let point = path.first(where: { $0.totalDist >= dist }) {
                    let angle = atan2(point.y - vpY, point.x - vpX)
                    anglesWithIndex.append((i, angle))
                }
            }

            guard anglesWithIndex.count == rayCount else { continue }

            anglesWithIndex.sort { $0.angle < $1.angle }
            let order = anglesWithIndex.map { $0.index }

            if let prev = previousOrder {
                // The cyclic order should match (rays may wrap around, but relative order stays)
                // Find where ray 0 is in both orderings and check they match cyclically
                if let prevStart = prev.firstIndex(of: order[0]) {
                    let rotatedPrev = Array(prev[prevStart...]) + Array(prev[..<prevStart])
                    XCTAssertEqual(order, rotatedPrev,
                        "Ray order changed between distances — rays crossed at dist ~\(dist)")
                }
            }
            previousOrder = order
        }
    }

    func testAllRaysReachEdges() {
        // Every ray should eventually leave the canvas (alive → false means path ends)
        let rayCount = 10
        let paths = simulateRays(
            rayCount: rayCount, baseAngle: 0,
            vpX: width / 2, vpY: height / 2,
            width: width, height: height,
            nameHash: 11111
        )

        XCTAssertEqual(paths.count, rayCount)
        for (i, path) in paths.enumerated() {
            XCTAssertGreaterThan(path.count, 1, "Ray \(i) has no path points beyond origin")
            if let last = path.last {
                XCTAssertGreaterThan(last.totalDist, 100,
                    "Ray \(i) died too early at dist \(last.totalDist)")
            }
        }
    }

    func testDeterminism() {
        // Same inputs must produce identical outputs
        let args = (rayCount: 8, baseAngle: CGFloat(1.2),
                    vpX: width / 2, vpY: height / 2,
                    width: width, height: height,
                    nameHash: UInt64(99999))

        let paths1 = simulateRays(
            rayCount: args.rayCount, baseAngle: args.baseAngle,
            vpX: args.vpX, vpY: args.vpY,
            width: args.width, height: args.height,
            nameHash: args.nameHash
        )
        let paths2 = simulateRays(
            rayCount: args.rayCount, baseAngle: args.baseAngle,
            vpX: args.vpX, vpY: args.vpY,
            width: args.width, height: args.height,
            nameHash: args.nameHash
        )

        XCTAssertEqual(paths1.count, paths2.count)
        for i in 0..<paths1.count {
            XCTAssertEqual(paths1[i].count, paths2[i].count,
                "Ray \(i) path length differs between runs")
            for j in 0..<paths1[i].count {
                XCTAssertEqual(paths1[i][j].x, paths2[i][j].x, accuracy: 0.0001)
                XCTAssertEqual(paths1[i][j].y, paths2[i][j].y, accuracy: 0.0001)
                XCTAssertEqual(paths1[i][j].direction, paths2[i][j].direction, accuracy: 0.0001)
            }
        }
    }

    func testDifferentNamesProduceDifferentPaths() {
        let paths1 = simulateRays(
            rayCount: 8, baseAngle: 0,
            vpX: width / 2, vpY: height / 2,
            width: width, height: height,
            nameHash: 12345
        )
        let paths2 = simulateRays(
            rayCount: 8, baseAngle: 0,
            vpX: width / 2, vpY: height / 2,
            width: width, height: height,
            nameHash: 54321
        )

        // At least some paths should differ
        var hasDifference = false
        for i in 0..<min(paths1.count, paths2.count) {
            let len = min(paths1[i].count, paths2[i].count)
            if len > 10 {
                let p1 = paths1[i][10]
                let p2 = paths2[i][10]
                if abs(p1.x - p2.x) > 1 || abs(p1.y - p2.y) > 1 {
                    hasDifference = true
                    break
                }
            }
        }
        XCTAssertTrue(hasDifference, "Different name hashes should produce different ray paths")
    }
}

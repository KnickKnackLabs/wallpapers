import CoreGraphics

/// Simple deterministic hash for seeded randomness from workspace name.
/// Returns values in 0.0..<1.0.
public func seededRandom(name: String, index: Int) -> CGFloat {
    var hash: UInt64 = 5381
    for char in name.unicodeScalars {
        hash = hash &* 33 &+ UInt64(char.value)
    }
    hash = hash &* 31 &+ UInt64(index &* 7919)
    hash ^= hash >> 13
    hash = hash &* 0x5bd1e995
    hash ^= hash >> 15
    return CGFloat(hash % 10000) / 10000.0
}

/// Simple 2D noise function using value noise with smoothing.
public func noise2D(x: CGFloat, y: CGFloat) -> CGFloat {
    let xi = Int(floor(x)) & 255
    let yi = Int(floor(y)) & 255
    let xf = x - floor(x)
    let yf = y - floor(y)

    // Smoothstep interpolation
    let u = xf * xf * (3 - 2 * xf)
    let v = yf * yf * (3 - 2 * yf)

    // Hash-based pseudo-random values at corners
    func hash(_ a: Int, _ b: Int) -> CGFloat {
        var h = UInt64(a &* 374761393 &+ b &* 668265263)
        h = (h ^ (h >> 13)) &* 1274126177
        h = h ^ (h >> 16)
        return CGFloat(h & 0xFFFF) / 65535.0
    }

    let n00 = hash(xi, yi)
    let n10 = hash(xi + 1, yi)
    let n01 = hash(xi, yi + 1)
    let n11 = hash(xi + 1, yi + 1)

    let nx0 = n00 + u * (n10 - n00)
    let nx1 = n01 + u * (n11 - n01)
    return nx0 + v * (nx1 - nx0)
}

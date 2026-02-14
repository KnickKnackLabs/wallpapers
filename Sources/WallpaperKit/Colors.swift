import CoreGraphics

public func parseHexColor(_ hex: String) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hexString.hasPrefix("#") {
        hexString.removeFirst()
    }

    guard hexString.count == 6,
          let hexValue = UInt64(hexString, radix: 16) else {
        return nil
    }

    let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
    let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
    let b = CGFloat(hexValue & 0xFF) / 255.0

    return (r, g, b)
}

/// Perceived luminance (0 = dark, 1 = bright)
public func luminance(_ c: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
}

/// Returns a decoration color that contrasts with the background.
/// On dark backgrounds: lighten the bg. On bright backgrounds: darken it.
public func decorationColor(_ bg: (r: CGFloat, g: CGFloat, b: CGFloat)) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
    if luminance(bg) > 0.5 {
        return (r: bg.r * 0.4, g: bg.g * 0.4, b: bg.b * 0.4)
    } else {
        return (r: min(1, bg.r + 0.4), g: min(1, bg.g + 0.4), b: min(1, bg.b + 0.4))
    }
}

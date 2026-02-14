/// Detects if text contains RTL characters (Hebrew, Arabic, etc.)
public func isRTL(_ text: String) -> Bool {
    for scalar in text.unicodeScalars {
        let value = scalar.value
        if (0x0590...0x05FF).contains(value) ||  // Hebrew
           (0x0600...0x06FF).contains(value) ||  // Arabic
           (0x0750...0x077F).contains(value) ||  // Arabic Supplement
           (0x08A0...0x08FF).contains(value) ||  // Arabic Extended-A
           (0xFB50...0xFDFF).contains(value) ||  // Arabic Presentation Forms-A
           (0xFE70...0xFEFF).contains(value) {   // Arabic Presentation Forms-B
            return true
        }
    }
    return false
}

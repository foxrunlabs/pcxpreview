extension UInt32 {
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = UInt8.max) {
        self.init(UInt32(alpha) << 24 | UInt32(red) << 16 | UInt32(green) << 8 | UInt32(blue))
    }
}

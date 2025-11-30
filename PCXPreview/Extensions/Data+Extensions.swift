import Foundation

extension Data {
    func read<T>(at offset: inout Int) -> T where T: Numeric {
        let size = MemoryLayout<T>.size
        let value = self.subdata(in: offset..<offset + size).withUnsafeBytes {
            $0.load(as: T.self)
        }
        
        offset += size
        return value
    }
    
    func read(at offset: inout Int, count: Int) -> [UInt8] {
        let bytes = Array(self.subdata(in: offset..<offset + count))
        offset += count
        return bytes
    }
    
    mutating func append<T>(_ value: T) where T: Numeric {
        Swift.withUnsafeBytes(of: value) { append(contentsOf: $0) }
    }
}

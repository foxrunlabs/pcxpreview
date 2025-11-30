import CoreGraphics
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PCXFile: FileDocument {
    struct Header {
        enum HeaderError: LocalizedError {
            case headerSize(Int)
            case magicNumber
            case version
            case encoding
            case bytesPerLine(UInt16)
            case paletteType
            
            var failureReason: String? {
                switch self {
                case .headerSize(let size):
                    "Incorrect header size: \(size.formatted(.byteCount(style: .file)))."
                case .magicNumber:
                    "Invalid file identification byte."
                case .version:
                    "Unknown file version."
                case .encoding:
                    "Unknown image encoding."
                case .bytesPerLine(let bytes):
                    "Malformed bytes per line: \(bytes)."
                case .paletteType:
                    "Unknown palette type."
                }
            }
        }
        
        enum Version: UInt8, CustomStringConvertible {
            case v25 = 0
            case v28WithPalette = 2
            case v28WithoutPalette = 3
            case pcPaintbrushForWindows = 4
            case v30 = 5
            
            var description: String {
                switch self {
                case .v25:
                    "PC Paintbrush v2.5"
                case .v28WithPalette:
                    "PC Paintbrush v2.8 with palette"
                case .v28WithoutPalette:
                    "PC Paintbrush v2.8 with no palette"
                case .pcPaintbrushForWindows:
                    "PC Paintbrush for Windows"
                case .v30:
                    "PC Paintbrush v3.0+, PC Paintbrush Plus, Publisher's Paintbrush, and 24-bit images"
                }
            }
        }
        
        enum Encoding: UInt8, CustomStringConvertible {
            case uncompressed = 0
            case rle = 1
            
            var description: String {
                switch self {
                case .uncompressed:
                    "No encoding"
                case .rle:
                    "Run-length encoding (RLE)"
                }
            }
        }
        
        enum PaletteType: UInt16, CustomStringConvertible {
            case ignored = 0
            case colorOrMonochrome = 1
            case grayscale = 2
            
            var description: String {
                switch self {
                case .ignored:
                    "Ignored"
                case .colorOrMonochrome:
                    "Color or monochrome"
                case .grayscale:
                    "Grayscale"
                }
            }
        }
        
        enum ImageType: CustomStringConvertible {
            case unknown
            case egaPlanar
            case egaIndexed
            case vga
            case trueColor
            
            var description: String {
                switch self {
                case .unknown:
                    "Unknown"
                case .egaPlanar:
                    "EGA Planar"
                case .egaIndexed:
                    "EGA Indexed"
                case .vga:
                    "VGA Indexed"
                case .trueColor:
                    "24-bit True Color"
                }
            }
        }
        
        let id: UInt8 = magicNumber                     // 00: PCX ID number
        let version: Version                            // 01: Version number
        let encoding: Encoding                          // 02: Encoding format
        let bitsPerPixelPerPlane: UInt8                 // 03: Bits per pixel per plane
        let minX: UInt16                                // 04: Left of image
        let minY: UInt16                                // 06: Top of image
        let maxX: UInt16                                // 08: Right of image
        let maxY: UInt16                                // 10: Bottom of image
        let horizontalDPI: UInt16                       // 12: Horizontal resolution in DPI
        let verticalDPI: UInt16                         // 14: Vertical resolution in DPI
        let palette: [UInt8]                            // 16: 16-color EGA palette (RGB888)
        let reserved: UInt8 = reservedByte              // 64: Reserved (always 0)
        let numberOfPlanes: UInt8                       // 65: Number of color planes
        let bytesPerLine: UInt16                        // 66: Number of bytes per line per plane
        let paletteType: PaletteType                    // 68: Palette type
        let horizontalScreenSize: UInt16                // 70: Horizontal screen resolution
        let verticalScreenSize: UInt16                  // 72: Vertical screen resolution
        let padding = [UInt8](repeating: 0, count: 54)  // 74: Padding for 128-byte header length
        
        static let size = 128
        private static let magicNumber: UInt8 = 0x0A
        private static let reservedByte: UInt8 = 0
        
        var depth: Int {
            Int(bitsPerPixelPerPlane) * Int(numberOfPlanes)
        }
        
        var imageType: ImageType {
            switch bitsPerPixelPerPlane {
            case 1:
                switch numberOfPlanes {
                case 3, 4:
                    .egaPlanar
                default:
                    .unknown
                }
            case 4:
                numberOfPlanes == 1 ? .egaIndexed : .unknown
            case 8:
                switch numberOfPlanes {
                case 1:
                    .vga
                case 3 where version == .v30:
                    .trueColor
                default:
                    .unknown
                }
            default:
                .unknown
            }
        }
        
        var packedData: Data {
            var data = Data()
            
            data.append(id)
            data.append(version.rawValue)
            data.append(encoding.rawValue)
            data.append(bitsPerPixelPerPlane)
            data.append(minX.littleEndian)
            data.append(minY.littleEndian)
            data.append(maxX.littleEndian)
            data.append(maxY.littleEndian)
            data.append(horizontalDPI.littleEndian)
            data.append(verticalDPI.littleEndian)
            data.append(contentsOf: palette)
            data.append(reserved)
            data.append(numberOfPlanes)
            data.append(bytesPerLine.littleEndian)
            data.append(paletteType.rawValue.littleEndian)
            data.append(horizontalScreenSize.littleEndian)
            data.append(verticalScreenSize.littleEndian)
            data.append(contentsOf: padding)
            
            return data
        }
        
        init(
            version: Version,
            encoding: Encoding,
            bitsPerPixelPerPlane: UInt8,
            minX: UInt16,
            minY: UInt16,
            maxX: UInt16,
            maxY: UInt16,
            horizontalDPI: UInt16,
            verticalDPI: UInt16,
            palette: [UInt8],
            numberOfPlanes: UInt8,
            bytesPerLine: UInt16,
            paletteType: PaletteType,
            horizontalScreenSize: UInt16,
            verticalScreenSize: UInt16
        ) {
            self.version = version
            self.encoding = encoding
            self.bitsPerPixelPerPlane = bitsPerPixelPerPlane
            self.minX = minX
            self.minY = minY
            self.maxX = maxX
            self.maxY = maxY
            self.horizontalDPI = horizontalDPI
            self.verticalDPI = verticalDPI
            self.palette = palette
            self.numberOfPlanes = numberOfPlanes
            self.bytesPerLine = bytesPerLine
            self.paletteType = paletteType
            self.horizontalScreenSize = horizontalScreenSize
            self.verticalScreenSize = verticalScreenSize
        }
        
        init(data: Data) throws {
            guard data.count == Self.size else { throw HeaderError.headerSize(data.count) }
            var offset = 0
            
            let id: UInt8 = data.read(at: &offset)
            guard id == Self.magicNumber else { throw HeaderError.magicNumber }
            
            guard let version = Version(rawValue: data.read(at: &offset)) else {
                throw HeaderError.version
            }
            
            guard let encoding = Encoding(rawValue: data.read(at: &offset)) else {
                throw HeaderError.encoding
            }
            
            let bitsPerPixelPerPlane: UInt8 = data.read(at: &offset)
            let minX = UInt16(littleEndian: data.read(at: &offset))
            let minY = UInt16(littleEndian: data.read(at: &offset))
            let maxX = UInt16(littleEndian: data.read(at: &offset))
            let maxY = UInt16(littleEndian: data.read(at: &offset))
            let horizontalDPI = UInt16(littleEndian: data.read(at: &offset))
            let verticalDPI = UInt16(littleEndian: data.read(at: &offset))
            let palette: [UInt8] = data.read(at: &offset, count: 48)
            let _: UInt8 = data.read(at: &offset)               // reserved byte
            let numberOfPlanes: UInt8 = data.read(at: &offset)
            
            let bytesPerLine = UInt16(littleEndian: data.read(at: &offset))
            guard bytesPerLine.isMultiple(of: 2) else {
                throw HeaderError.bytesPerLine(bytesPerLine)
            }
            
            guard let paletteType = PaletteType(
                rawValue: UInt16(littleEndian: data.read(at: &offset))
            ) else {
                throw HeaderError.paletteType
            }
            
            let horizontalScreenSize = UInt16(littleEndian: data.read(at: &offset))
            let verticalScreenSize = UInt16(littleEndian: data.read(at: &offset))
            
            self.init(
                version: version,
                encoding: encoding,
                bitsPerPixelPerPlane: bitsPerPixelPerPlane,
                minX: minX,
                minY: minY,
                maxX: maxX,
                maxY: maxY,
                horizontalDPI: horizontalDPI,
                verticalDPI: verticalDPI,
                palette: palette,
                numberOfPlanes: numberOfPlanes,
                bytesPerLine: bytesPerLine,
                paletteType: paletteType,
                horizontalScreenSize: horizontalScreenSize,
                verticalScreenSize: verticalScreenSize
            )
        }
    }
    
    let header: Header
    let width: Int
    let height: Int
    
    private let palette: [UInt8]
    private let imageData: Data
    private var imageBytes: [UInt8] = []
    
    private static let paletteFlag: UInt8 = 0x0C
    private static let egaPalette: [UInt8] = [
        0x00, 0x00, 0x00,   // black
        0xAA, 0x00, 0x00,   // blue
        0x00, 0xAA, 0xAA,   // green
        0xAA, 0xAA, 0x00,   // cyan
        0x00, 0x00, 0xAA,   // red
        0xAA, 0x00, 0xAA,   // magenta
        0x00, 0x55, 0xAA,   // brown
        0xAA, 0xAA, 0xAA,   // light gray
        0x55, 0x55, 0x55,   // dark gray
        0xFF, 0x55, 0x55,   // light blue
        0x55, 0xFF, 0x55,   // light green
        0xFF, 0xFF, 0x55,   // light cyan
        0x55, 0x55, 0xFF,   // light red
        0xFF, 0x55, 0xFF,   // light magenta
        0x55, 0xFF, 0xFF,   // yellow
        0xFF, 0xFF, 0xFF,   // white
    ]
    
    init(data: Data) throws {
        self.header = try Header(data: data.prefix(Header.size))
        self.width = Int(header.maxX) - Int(header.minX) + 1
        self.height = Int(header.maxY) - Int(header.minY) + 1
        
        self.palette = switch header.version {
        case .v25, .v28WithoutPalette:
            Self.egaPalette                              // fixed EGA palette
        case .v28WithPalette:
            header.palette                               // modified EGA palette
        case .v30 where data[data.endIndex - 769] == Self.paletteFlag:
            data.suffix(768)                             // VGA 256-color palette
        case .v30 where header.imageType == .trueColor:
            []                                           // VGA 24-bit no palette
        default:
            throw Header.HeaderError.version
        }
        
        self.imageData = data.advanced(by: Header.size)
        guard imageData.count > 0 else { throw CocoaError(.fileReadCorruptFile) }
        self.imageBytes = decodeRLE(imageData)
    }
    
    private func decodeRLE(_ data: Data) -> [UInt8] {
        let encodedBytes = [UInt8](data)
        var decodedLines: [[UInt8]] = []
        
        let totalBytesPerLine = Int(header.bytesPerLine) * Int(header.numberOfPlanes)
        var offset = 0
        
        var lineBytes: [UInt8] = []
        lineBytes.reserveCapacity(totalBytesPerLine)
        
        // decode each line of RLE encoded bytes
        for _ in 0..<height {
            while lineBytes.count < totalBytesPerLine && offset < encodedBytes.count {
                let encodedByte = encodedBytes[offset]
                
                if encodedByte < 192 {
                    lineBytes.append(encodedByte)
                } else {
                    let count = Int(encodedByte & 0x3F)
                    offset += 1
                    let value = encodedBytes[offset]
                    lineBytes.append(contentsOf: [UInt8](repeating: value, count: count))
                }
                
                offset += 1
            }
            
            decodedLines.append(lineBytes)
            lineBytes.removeAll(keepingCapacity: true)
        }
        
        // separate the color planes from the decoded bytes
        let colorPlanes: [[UInt8]] = (0..<Int(header.numberOfPlanes)).map { plane in
            decodedLines.flatMap { line in
                let start = line.startIndex + plane * Int(header.bytesPerLine)
                let end = start + width
                return line[start..<end]
            }
        }
        
        return switch header.imageType {
        case .vga:
            colorPlanes[0]
        case .trueColor:
            // interleve the true-color color planes
            // planes are ordered red, green, blue
            zip(colorPlanes[0], zip(colorPlanes[1], colorPlanes[2])).map {
                ($0.1.1, $0.1.0, $0.0)  // (blue, green, red)
            }.flatMap { (blue, green, red) in
                [blue, green, red, UInt8.max]   // ARGB32, little endian
            }
        default:
            []
        }
    }
    
    var cgImage: CGImage? {
        guard let baseColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        
        let colorSpace: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        let bitsPerPixel: Int
        let bytesPerRow: Int
        
        if header.imageType == .trueColor {
            colorSpace = baseColorSpace
            bitmapInfo = CGBitmapInfo(rawValue: CGImageByteOrderInfo.order32Little.rawValue |
                                      CGImageAlphaInfo.premultipliedFirst.rawValue)
            bitsPerPixel = UInt32.bitWidth
            bytesPerRow = MemoryLayout<UInt32>.size * width
        } else {
            guard let indexedColorSpace = CGColorSpace(
                indexedBaseSpace: baseColorSpace,
                last: Int(UInt8.max),
                colorTable: [UInt8](palette)
            ) else {
                return nil
            }
            
            colorSpace = indexedColorSpace
            bitmapInfo = CGBitmapInfo(rawValue: CGImageByteOrderInfo.orderDefault.rawValue |
                                      CGImageAlphaInfo.none.rawValue)
            bitsPerPixel = Int(header.bitsPerPixelPerPlane) * Int(header.numberOfPlanes)
            bytesPerRow = width * bitsPerPixel / UInt8.bitWidth
        }
        
        guard let dataProvider = CGDataProvider(data: Data(imageBytes) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: Int(header.bitsPerPixelPerPlane),
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
    
    // MARK: - FileDocument
    static var readableContentTypes: [UTType] = [.pcx]
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        try self.init(data: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        data.append(header.packedData)
        data.append(imageData)
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Example
    static var example: Self {
        guard let url = Bundle.main.url(forResource: "example", withExtension: "pcx") else {
            fatalError("Could not find example file in bundle.")
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try Self(data: data)
        } catch {
            fatalError("Could not create FileDocument example: \(error.localizedDescription)")
        }
    }
}

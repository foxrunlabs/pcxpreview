import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PCXFile: FileDocument {
    typealias ARGB32 = UInt32
    
    let header: Header
    let width: Int
    let height: Int
    let depth: Int
    private let pcxData: Data
    private let palette: [ARGB32]
    private var bitmap: [ARGB32] = []
    
    init(data: Data) throws {
        self.pcxData = data
        
        let headerData = data.prefix(Header.size)
        self.header = try Header(data: headerData)
        self.width = header.maxX - header.minX + 1
        self.height = header.maxY - header.minY + 1
        self.depth = header.bitsPerPixelPerPlane * header.numberOfPlanes
        
        // get the BGR24 (LE) palette and convert to ARGB32 (LE)
        let paletteFlag: UInt8 = 0x0C
        let paletteFlagOffset = data.endIndex - 769
        let bgrPalette: [UInt8] = switch header.version {
        case .v25, .v28WithoutPalette:
            egaPalette                                   // fixed EGA palette
        case .v28WithPalette:
            header.palette                               // modified EGA palette
        case .v30 where data[paletteFlagOffset] == paletteFlag:
            data.suffix(768)                             // VGA 256-color palette
        case .v30 where header.imageType == .trueColor:
            []                                           // VGA 24-bit no palette
        default:
            throw Header.HeaderError.version
        }
        
        self.palette = stride(from: 0, to: bgrPalette.count, by: 3).map { n in
            ARGB32(red: bgrPalette[n], green: bgrPalette[n + 1], blue: bgrPalette[n + 2])
        }
        
        // decode image data
        let imageData = data.advanced(by: Header.size)
        guard imageData.count > 0 else { throw CocoaError(.fileReadCorruptFile) }
        self.bitmap = decodeImageData(imageData)
    }
    
    private func decodeImageData(_ data: Data) -> [ARGB32] {
        var output = [ARGB32](repeating: 0, count: width * height)
        let totalBytesPerLine = header.bytesPerLine * header.numberOfPlanes
        var scanline = [UInt8](repeating: 0, count: totalBytesPerLine)
        
        data.withUnsafeBytes { rawBuffer in
            let srcBuffer = rawBuffer.bindMemory(to: UInt8.self)
            guard let srcPtr = srcBuffer.baseAddress else { return }
            var srcOffset = 0
            
            @inline(__always)
            func decodeScanline(_ destPtr: UnsafeMutablePointer<UInt8>) {
                var destOffset = 0
                
                while destOffset < totalBytesPerLine && srcOffset < srcBuffer.count {
                    let byte = srcPtr[srcOffset]
                    srcOffset += 1
                    
                    if byte < 192 {
                        destPtr[destOffset] = byte
                        destOffset += 1
                    } else {
                        guard srcOffset < srcBuffer.count else { break }
                        let count = Int(byte & 0x3F)
                        let value = srcPtr[srcOffset]
                        srcOffset += 1
                        
                        if count > 0 {
                            let numBytes = min(count, totalBytesPerLine - destOffset)
                            destPtr.advanced(by: destOffset).update(repeating: value, count: numBytes)
                            destOffset += numBytes
                        }
                    }
                }
            }
            
            scanline.withUnsafeMutableBufferPointer { scanlineBuffer in
                guard let scanlinePtr = scanlineBuffer.baseAddress else { return }
                
                switch header.imageType {
                case .vga:
                    for y in 0..<height {
                        decodeScanline(scanlinePtr)
                        
                        for x in 0..<width {
                            let index = Int(scanlinePtr[x])
                            output[x + y * width] = palette[index]
                        }
                    }
                case .trueColor:
                    let redBase = 0
                    let greenBase = header.bytesPerLine
                    let blueBase = 2 * header.bytesPerLine
                    
                    for y in 0..<height {
                        decodeScanline(scanlinePtr)
                        
                        for x in 0..<width {
                            let red = scanlinePtr[redBase + x]
                            let green = scanlinePtr[greenBase + x]
                            let blue = scanlinePtr[blueBase + x]
                            
                            output[x + y * width] = ARGB32(red: red, green: green, blue: blue)
                        }
                    }
                default:
                    output.removeAll()
                }
            }
        }
        
        return output
    }
    
    var cgImage: CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageByteOrderInfo.order32Little.rawValue |
                                      CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        let bytes = bitmap.withUnsafeBufferPointer { Data(buffer: $0) }
        guard let dataProvider = CGDataProvider(data: bytes as CFData) else { return nil }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: header.bitsPerPixelPerPlane,
            bitsPerPixel: ARGB32.bitWidth,
            bytesPerRow: MemoryLayout<ARGB32>.size * width,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

// MARK: - Header
extension PCXFile {
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
        
        enum Version: Int, CustomStringConvertible {
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
        
        enum Encoding: Int, CustomStringConvertible {
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
        
        enum PaletteType: Int, CustomStringConvertible {
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
        
        enum ImageType: CustomStringConvertible, nonisolated Equatable {
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
        
        private static let magicNumber: UInt8 = 0x0A    // 00: PCX ID number
        let version: Version                            // 01: Version number
        let encoding: Encoding                          // 02: Encoding format
        let bitsPerPixelPerPlane: Int                   // 03: Bits per pixel per plane
        let minX: Int                                   // 04: Left of image
        let minY: Int                                   // 06: Top of image
        let maxX: Int                                   // 08: Right of image
        let maxY: Int                                   // 10: Bottom of image
        let horizontalDPI: Int                          // 12: Horizontal resolution in DPI
        let verticalDPI: Int                            // 14: Vertical resolution in DPI
        let palette: [UInt8]                            // 16: 16-color EGA palette (RGB888)
        private static let reservedByte: UInt8 = 0      // 64: Reserved (always 0)
        let numberOfPlanes: Int                         // 65: Number of color planes
        let bytesPerLine: Int                           // 66: Number of bytes per line per plane
        let paletteType: PaletteType                    // 68: Palette type
        let horizontalScreenSize: Int                   // 70: Horizontal screen resolution
        let verticalScreenSize: Int                     // 72: Vertical screen resolution
        
        static let size = 128                           // includes 54 bytes of padding
        
        init(
            version: Version,
            encoding: Encoding,
            bitsPerPixelPerPlane: Int,
            minX: Int,
            minY: Int,
            maxX: Int,
            maxY: Int,
            horizontalDPI: Int,
            verticalDPI: Int,
            palette: [UInt8],
            numberOfPlanes: Int,
            bytesPerLine: Int,
            paletteType: PaletteType,
            horizontalScreenSize: Int,
            verticalScreenSize: Int
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
            
            let versionByte: UInt8 = data.read(at: &offset)
            guard let version = Version(rawValue: Int(versionByte)) else {
                throw HeaderError.version
            }
            
            let encodingByte: UInt8 = data.read(at: &offset)
            guard let encoding = Encoding(rawValue: Int(encodingByte)) else {
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
            
            let paletteTypeBytes = UInt16(littleEndian: data.read(at: &offset))
            guard let paletteType = PaletteType(rawValue: Int(paletteTypeBytes)) else {
                throw HeaderError.paletteType
            }
            
            let horizontalScreenSize = UInt16(littleEndian: data.read(at: &offset))
            let verticalScreenSize = UInt16(littleEndian: data.read(at: &offset))
            
            self.init(
                version: version,
                encoding: encoding,
                bitsPerPixelPerPlane: Int(bitsPerPixelPerPlane),
                minX: Int(minX),
                minY: Int(minY),
                maxX: Int(maxX),
                maxY: Int(maxY),
                horizontalDPI: Int(horizontalDPI),
                verticalDPI: Int(verticalDPI),
                palette: palette,
                numberOfPlanes: Int(numberOfPlanes),
                bytesPerLine: Int(bytesPerLine),
                paletteType: paletteType,
                horizontalScreenSize: Int(horizontalScreenSize),
                verticalScreenSize: Int(verticalScreenSize)
            )
        }
        
        var imageType: ImageType {
            switch bitsPerPixelPerPlane {
            case 1 where numberOfPlanes == 3 || numberOfPlanes == 4:
                .egaPlanar
            case 4 where numberOfPlanes == 1:
                .egaIndexed
            case 8 where numberOfPlanes == 1:
                .vga
            case 8 where numberOfPlanes == 3 && version == .v30:
                .trueColor
            default:
                .unknown
            }
        }
        
        var packedData: Data {
            var data = Data()
            
            data.append(Self.magicNumber)
            data.append(UInt8(version.rawValue))
            data.append(UInt8(encoding.rawValue))
            data.append(UInt8(bitsPerPixelPerPlane))
            data.append(UInt16(minX).littleEndian)
            data.append(UInt16(minY).littleEndian)
            data.append(UInt16(maxX).littleEndian)
            data.append(UInt16(maxY).littleEndian)
            data.append(UInt16(horizontalDPI).littleEndian)
            data.append(UInt16(verticalDPI).littleEndian)
            data.append(contentsOf: palette)
            data.append(Self.reservedByte)
            data.append(UInt8(numberOfPlanes))
            data.append(UInt16(bytesPerLine).littleEndian)
            data.append(UInt16(paletteType.rawValue).littleEndian)
            data.append(UInt16(horizontalScreenSize).littleEndian)
            data.append(UInt16(verticalScreenSize).littleEndian)
            data.append(Data(count: 54))                            // padding
            
            return data
        }
    }
}

// MARK: - FileDocument
extension PCXFile {
    static var readableContentTypes: [UTType] = [.pcx]
    static var writableContentTypes: [UTType] = [.bmp, .jpeg, .pcx, .png]
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        try self.init(data: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let cgImage else { throw CocoaError(.fileWriteUnknown) }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        guard
            let data = switch configuration.contentType {
            case .bmp:
                bitmapRep.representation(using: .bmp, properties: [:])
            case .jpeg:
                bitmapRep.representation(using: .jpeg, properties: [:])
            case .pcx:
                pcxData
            case .png:
                bitmapRep.representation(using: .png, properties: [:])
            default:
                throw CocoaError(.fileWriteUnknown)
            }
        else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Example
extension PCXFile {
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

// MARK: - EGA Palette
fileprivate let egaPalette: [UInt8] = [
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

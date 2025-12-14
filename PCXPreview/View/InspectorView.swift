import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct InspectorView: View {
    let document: PCXFile
    let fileURL: URL?
    
    var body: some View {
        TabView {
            Tab("General Info", systemImage: "document") {
                GeneralInfoView(document: document, fileURL: fileURL)
            }
            
            Tab("More Info", systemImage: "info") {
                MoreInfoView(document: document)
            }
        }
    }
}

// MARK: - Inspector Tab Views
fileprivate struct GeneralInfoView: View {
    let document: PCXFile
    let fileURL: URL?
    private let resourceValues: URLResourceValues?
    
    init(document: PCXFile, fileURL: URL?) {
        self.document = document
        self.fileURL = fileURL
        self.resourceValues = try? fileURL?.resourceValues(
            forKeys: [.contentTypeKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey]
        )
    }
    
    private var dpi: String {
        if document.header.horizontalDPI == document.header.verticalDPI {
            "\(document.header.horizontalDPI) pixels/inch"
        } else {
            "\(document.header.horizontalDPI) x \(document.header.verticalDPI) pixels/inch"
        }
    }
    
    var body: some View {
        Form {
            Section {
                Group {
                    LabeledContent("File Name") {
                        Text(fileURL?.lastPathComponent ?? "Unknown")
                    }
                    
                    LabeledContent("Document Type") {
                        Text(resourceValues?.contentType?.localizedDescription ?? "Unknown")
                    }
                    
                    LabeledContent("File Size") {
                        Text(resourceValues?.fileSize?.formatted(
                                .byteCount(style: .file, includesActualByteCount: true)
                            ) ?? "Unknown"
                        )
                    }
                    
                    LabeledContent("Creation Date") {
                        Text(resourceValues?.creationDate?
                            .formatted(date: .abbreviated, time: .shortened) ?? "Unknown"
                        )
                    }
                    
                    LabeledContent("Modification Date") {
                        Text(resourceValues?.contentModificationDate?
                            .formatted(date: .abbreviated, time: .shortened) ?? "Unknown"
                        )
                    }
                }
                .font(.subheadline)
            }
            
            Section {
                Group {
                    LabeledContent("Image Size") {
                        Text("\(document.width) x \(document.height) pixels")
                    }
                    
                    LabeledContent("Image DPI") {
                        Text(dpi)
                    }
                }
                .font(.subheadline)
            }
        }
        .formStyle(.grouped)
    }
}

fileprivate struct MoreInfoView: View {
    let document: PCXFile
    @State private var isGeneralExpanded = true
    @State private var isPCXExpanded = false
    
    var body: some View {
        Form {
            Section("General", isExpanded: $isGeneralExpanded) {
                Group {
                    LabeledContent("Depth") {
                        Text("\(document.depth)")
                    }
                    
                    LabeledContent("DPI Height") {
                        Text("\(document.header.verticalDPI)")
                    }
                    
                    LabeledContent("DPI Width") {
                        Text("\(document.header.horizontalDPI)")
                    }
                    
                    LabeledContent("Pixel Height") {
                        Text("\(document.height)")
                    }
                    
                    LabeledContent("Pixel Width") {
                        Text("\(document.width)")
                    }
                }
                .font(.subheadline)
            }
            
            Section("PCX", isExpanded: $isPCXExpanded) {
                Group {
                    LabeledContent("Version") {
                        Text(String(describing: document.header.version))
                    }
                    
                    LabeledContent("Bits Per Pixel Per Plane") {
                        Text("\(document.header.bitsPerPixelPerPlane)")
                    }
                    
                    LabeledContent("Number of Planes") {
                        Text("\(document.header.numberOfPlanes)")
                    }
                    
                    LabeledContent("Encoding") {
                        Text(String(describing: document.header.encoding))
                    }
                    
                    LabeledContent("Palette Type") {
                        Text(String(describing: document.header.paletteType))
                    }
                }
                .font(.subheadline)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Preview
#Preview {
    InspectorView(document: .example, fileURL: nil)
}

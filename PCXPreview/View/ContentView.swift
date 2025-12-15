import CoreGraphics
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let document: PCXFile
    let fileURL: URL?
    private let cgImage: CGImage?
    
    @State private var zoomController = ZoomController()
    @State private var showInspector = false
    @State private var showExporter = false
    
    init(document: PCXFile, fileURL: URL?) {
        self.document = document
        self.fileURL = fileURL
        self.cgImage = document.cgImage
    }
    
    var body: some View {
        Group {
            if let cgImage {
                ScrollView([.horizontal, .vertical]) {
                    Image(decorative: cgImage, scale: 1.0)
                        .interpolation(.none)
                        .resizable()
                        .frame(
                            width: Double(cgImage.width) * zoomController.scale,
                            height: Double(cgImage.height) * zoomController.scale
                        )
                }
                .scrollBounceBehavior(.basedOnSize)
                .defaultScrollAnchor(.center, for: .sizeChanges)
                .onGeometryChange(for: CGSize.self, of: \.size) { _, newSize in
                    zoomController.fitScale = min(
                        newSize.width / Double(cgImage.width),
                        newSize.height / Double(cgImage.height)
                    )
                }
                .onAppear {
                    if document.width > 640 || document.height > 480 {
                        zoomController.zoom(.fit)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Image",
                    systemImage: "photo.trianglebadge.exclamationmark"
                )
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                    zoomController.zoom(.zoomOut)
                }
                .disabled(cgImage == nil)
                .help("Scale graphic down")
                
                Button("Actual Size", systemImage: "1.magnifyingglass") {
                    zoomController.zoom(.actualSize)
                }
                .help("Display at actual size")
                .disabled(cgImage == nil || zoomController.isActualSize)
                
                Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                    zoomController.zoom(.fit)
                }
                .disabled(cgImage == nil || zoomController.isZoomedToFit)
                .help("Scale graphic to window")
                
                Button("Zoom In", systemImage: "plus.magnifyingglass") {
                    zoomController.zoom(.zoomIn)
                }
                .disabled(cgImage == nil)
                .help("Scale graphic up")
            }
            
            ToolbarSpacer()
            
            ToolbarItemGroup {
                Toggle(isOn: $showInspector) { Image(systemName: "info") }
                    .toggleStyle(.button)
                    .help("Show the inspector")
            }
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(document: document, fileURL: fileURL)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: document,
            contentTypes: [.bmp, .jpeg, .png],
            defaultFilename: fileURL?.deletingPathExtension().lastPathComponent
        ) { result in
            
        }
        .focusedSceneValue(\.document, document)
        .focusedSceneValue(zoomController)
        .focusedSceneValue(\.showExporter, $showExporter)
    }
}

// MARK: - Preview
#Preview {
    ContentView(document: .example, fileURL: nil)
}

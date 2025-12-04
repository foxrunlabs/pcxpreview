import SwiftUI

struct FileCommands: Commands {
    @FocusedValue(\.document) private var document
    @FocusedBinding(\.showExporter) private var showExporter
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) { EmptyView() }
        
        CommandGroup(replacing: .importExport) {
            Button("Export As...", systemImage: "square.and.arrow.up") {
                showExporter?.toggle()
            }
            .disabled(document == nil)
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
    }
}

struct EditCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .undoRedo) { EmptyView() }
    }
}

struct ViewCommands: Commands {
    @FocusedValue(\.document) private var document
    @FocusedValue(ZoomController.self) private var zoomController
    
    var body: some Commands {
        ToolbarCommands()
        InspectorCommands()
        
        CommandGroup(after: .toolbar) {
            Group {
                Button("Actual Size", systemImage: "1.magnifyingglass") {
                    zoomController?.zoom(.actualSize)
                }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(zoomController?.isActualSize ?? false)
                
                Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                    zoomController?.zoom(.fit)
                }
                .keyboardShortcut("9", modifiers: .command)
                .disabled(zoomController?.isZoomedToFit ?? false)
                
                Button("Zoom In", systemImage: "plus.magnifyingglass") {
                    zoomController?.zoom(.zoomIn)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                    zoomController?.zoom(.zoomOut)
                }
                .keyboardShortcut("-", modifiers: .command)
            }
            .disabled(document == nil)
        }
    }
}

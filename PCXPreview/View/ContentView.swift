import Foundation
import SwiftUI

struct ContentView: View {
    let document: PCXFile
    let fileURL: URL?
    
    @State private var showInspector = false

    var body: some View {
        Group {
            if let cgImage = document.cgImage {
                Image(decorative: cgImage, scale: 1.0)
            } else {
                ContentUnavailableView("No Image", systemImage: "photo.trianglebadge.exclamationmark")
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $showInspector) { Image(systemName: "info") }
                    .toggleStyle(.button)
                    .help("Show the inspector")
            }
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(document: document, fileURL: fileURL)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView(document: .example, fileURL: nil)
}

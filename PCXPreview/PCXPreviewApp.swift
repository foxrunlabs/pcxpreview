import Foundation
import SwiftUI

@main
struct PCXPreviewApp: App {
    var body: some Scene {
        DocumentGroup(viewing: PCXFile.self) { file in
            ContentView(document: file.document, fileURL: file.fileURL)
                .frame(minWidth: 320, minHeight: 200)
        }
        .defaultSize(width: 640, height: 480)
        .commands {
            FileCommands()
            EditCommands()
            ViewCommands()
        }
    }
}

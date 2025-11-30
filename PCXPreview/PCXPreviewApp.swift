import Foundation
import SwiftUI

@main
struct PCXPreviewApp: App {
    var body: some Scene {
        DocumentGroup(viewing: PCXFile.self) { file in
            ContentView(document: file.document, fileURL: file.fileURL)
        }
        .commands {
            FileCommands()
            EditCommands()
            ViewCommands()
        }
    }
}

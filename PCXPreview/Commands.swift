import SwiftUI

struct FileCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) { EmptyView() }
    }
}

struct EditCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .undoRedo) { EmptyView() }
    }
}

struct ViewCommands: Commands {
    var body: some Commands {
        InspectorCommands()
    }
}

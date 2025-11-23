//
//  PCXPreviewApp.swift
//  PCXPreview
//
//  Created by Ryan Clarke on 11/23/25.
//

import SwiftUI

@main
struct PCXPreviewApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: PCXPreviewDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}

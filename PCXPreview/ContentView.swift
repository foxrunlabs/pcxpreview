//
//  ContentView.swift
//  PCXPreview
//
//  Created by Ryan Clarke on 11/23/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: PCXPreviewDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(PCXPreviewDocument()))
}

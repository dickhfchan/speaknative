//
//  ContentView.swift
//  speaknative
//
//  Created by Dick Chan on 15/9/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Narratives") { NarrativeView() }
                NavigationLink("Record") { RecordingView() }
            }
            .navigationTitle("SpeakNative")
        }
    }
}

#Preview {
    ContentView()
}

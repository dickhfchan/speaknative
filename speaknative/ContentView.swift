//
//  ContentView.swift
//  speaknative
//
//  Created by Dick Chan on 15/9/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            DiagnosticsView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Diagnostics")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}

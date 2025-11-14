//
//  App.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Demonstrates advanced spatial text input for visionOS
//

import SwiftUI

@main
struct SpatialTextLabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.2, height: 0.9, depth: 0.15)
        .windowResizability(.contentSize)
    }
}

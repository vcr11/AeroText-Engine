//
//  App.swift
//  AeroText-Engine
//
//  Created by Apple Vision Pro Engineer
//  Advanced spatial text input engine for visionOS
//

import SwiftUI

@main
struct AeroTextEngineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.2, height: 0.9, depth: 0.15)
        .windowResizability(.contentSize)
    }
}

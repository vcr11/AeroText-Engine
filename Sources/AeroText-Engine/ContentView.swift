//
//  ContentView.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Main spatial scene coordinator with RealityKit integration
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject private var textModel = TextModel()
    @StateObject private var keyboardModel = KeyboardModel()
    @StateObject private var cursorModel = CursorModel()
    @StateObject private var autocorrectEngine = AutocorrectEngine()
    @StateObject private var performanceLogger = PerformanceLogger()
    @StateObject private var gazeSmoother = GazeSmoother()

    @State private var keyboardPosition = SIMD3<Float>(0, -0.25, -0.6)
    @State private var keyboardScale: Float = 1.0
    @State private var showHandwritingCanvas = false

    var body: some View {
        ZStack {
            // Main RealityKit scene
            RealityView { content in
                setupRealityScene(content: content)
            } update: { content in
                updateRealityScene(content: content)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleSpatialTap(value)
                    }
            )
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        handleDrag(value)
                    }
            )
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        keyboardScale = Float(max(0.5, min(2.0, value.magnification)))
                    }
            )

            // SwiftUI overlays
            VStack {
                Spacer()
                TextEditorView(textModel: textModel, cursorModel: cursorModel)
                    .frame(width: 500, height: 250)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(radius: 8)

                if let suggestions = autocorrectEngine.suggestions {
                    AutocorrectBarView(suggestions: suggestions, textModel: textModel)
                        .padding(.top, 8)
                }

                Spacer()
            }

            // Performance overlay
            VStack {
                HStack {
                    Spacer()
                    PerformanceOverlayView(logger: performanceLogger)
                }
                Spacer()
            }

            // Handwriting canvas (when activated)
            if showHandwritingCanvas {
                HandwritingCanvasView(textModel: textModel)
                    .frame(width: 400, height: 300)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }
        }
        .onAppear {
            setupModels()
        }
    }

    private func setupRealityScene(content: RealityViewContent) {
        // Create main anchor for spatial content
        let anchor = AnchorEntity(.head)
        content.add(anchor)

        // Add spatial keyboard
        let keyboardEntity = keyboardModel.createKeyboardEntity()
        anchor.addChild(keyboardEntity)

        // Add floating cursor
        let cursorEntity = cursorModel.createCursorEntity()
        anchor.addChild(cursorEntity)

        // Position initial elements
        keyboardEntity.position = keyboardPosition
        cursorEntity.position = SIMD3<Float>(0, 0, -0.5)
    }

    private func updateRealityScene(content: RealityViewContent) {
        // Update keyboard position and scale
        if let keyboardEntity = content.entities.first(where: { $0.name == "keyboard" }) {
            keyboardEntity.position = keyboardPosition
            keyboardEntity.scale = SIMD3<Float>(repeating: keyboardScale)
        }

        // Update cursor position with smoothed gaze
        if let cursorEntity = content.entities.first(where: { $0.name == "cursor" }) {
            cursorEntity.position = gazeSmoother.smoothedPosition
        }

        // Update key highlights based on cursor proximity
        keyboardModel.updateHighlights(for: gazeSmoother.smoothedPosition)
    }

    private func handleSpatialTap(_ value: SpatialTapGesture.Value) {
        let startTime = Date()

        if value.entity.name.hasPrefix("key_") {
            keyboardModel.handleKeyTap(value.entity)
            performanceLogger.logInputLatency(Date().timeIntervalSince(startTime) * 1000)
        } else if value.entity.name == "cursor" {
            cursorModel.handleCursorTap(at: value.location3D)
        }

        performanceLogger.logInputEvent()
    }

    private func handleDrag(_ value: SpatialTapGesture.Value) {
        // Allow dragging the keyboard in 3D space
        let translation = value.gestureValue?.translation3D ?? .zero
        keyboardPosition += SIMD3<Float>(
            Float(translation.x) * 0.0005,
            Float(translation.y) * 0.0005,
            Float(translation.z) * 0.0005
        )
    }

    private func setupModels() {
        keyboardModel.setup(with: textModel, autocorrectEngine: autocorrectEngine)
        cursorModel.setup(with: textModel, keyboardModel: keyboardModel)
        autocorrectEngine.textModel = textModel
    }
}

// MARK: - Handwriting Canvas View
struct HandwritingCanvasView: View {
    @ObservedObject var textModel: TextModel
    @State private var currentStroke: [CGPoint] = []
    @State private var strokes: [[CGPoint]] = []

    var body: some View {
        VStack {
            Text("Draw characters here")
                .font(.headline)
                .padding(.top)

            Canvas { context, size in
                for stroke in strokes {
                    var path = Path()
                    if let firstPoint = stroke.first {
                        path.move(to: firstPoint)
                        for point in stroke.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(path, with: .color(.blue), lineWidth: 3)
                }

                // Current stroke
                if !currentStroke.isEmpty {
                    var path = Path()
                    path.move(to: currentStroke[0])
                    for point in currentStroke.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.red), lineWidth: 3)
                }
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentStroke.isEmpty {
                            strokes.append(currentStroke)
                            currentStroke = []
                            // TODO: Implement character recognition
                            textModel.insertCharacter("?") // Placeholder
                        }
                    }
            )

            HStack {
                Button("Clear") {
                    strokes = []
                    currentStroke = []
                }
                Spacer()
                Button("Done") {
                    // Close handwriting canvas
                }
            }
            .padding()
        }
    }
}

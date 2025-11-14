//
//  SpatialKeyboardView.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  SwiftUI wrapper for the RealityKit spatial keyboard
//

import SwiftUI
import RealityKit

struct SpatialKeyboardView: View {
    @ObservedObject var keyboardModel: KeyboardModel
    @ObservedObject var cursorModel: CursorModel

    @State private var keyboardScale: Float = 1.0
    @State private var keyboardPosition = SIMD3<Float>(0, -0.25, -0.6)

    var body: some View {
        RealityView { content in
            setupKeyboardScene(content: content)
        } update: { content in
            updateKeyboardScene(content: content)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    keyboardModel.handleKeyTap(value.entity)
                }
        )
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    keyboardScale = Float(max(0.5, min(2.0, value.magnification)))
                }
        )
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let translation = value.translation3D
                    keyboardPosition += SIMD3<Float>(
                        Float(translation.x) * 0.001,
                        Float(translation.y) * 0.001,
                        Float(translation.z) * 0.001
                    )
                }
        )
    }

    private func setupKeyboardScene(content: RealityViewContent) {
        // Create anchor for keyboard
        let anchor = AnchorEntity(.head)
        content.add(anchor)

        // Add keyboard entity
        let keyboardEntity = keyboardModel.createKeyboardEntity()
        anchor.addChild(keyboardEntity)

        // Position keyboard
        keyboardEntity.position = keyboardPosition
    }

    private func updateKeyboardScene(content: RealityViewContent) {
        // Update keyboard position and scale
        if let keyboardEntity = content.entities.first(where: { $0.name == "keyboard" }) {
            keyboardEntity.position = keyboardPosition
            keyboardEntity.scale = SIMD3<Float>(repeating: keyboardScale)
        }

        // Update key highlights based on cursor position
        keyboardModel.updateHighlights(for: cursorModel.position)
    }
}

// MARK: - Keyboard Layout Helper
extension SpatialKeyboardView {
    static func qwertyLayout() -> [[String]] {
        [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"],
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            ["Space", "Backspace", "Return"]
        ]
    }

    static func keySize(for label: String) -> SIMD3<Float> {
        switch label {
        case "Space":
            return SIMD3<Float>(0.32, 0.06, 0.02)
        case "Backspace", "Return":
            return SIMD3<Float>(0.12, 0.06, 0.02)
        default:
            return SIMD3<Float>(0.06, 0.06, 0.02)
        }
    }

    static func keyColor(for label: String, isHighlighted: Bool) -> UIColor {
        if isHighlighted {
            return .systemBlue
        }

        switch label {
        case "Space":
            return .systemGray4
        case "Backspace":
            return .systemRed
        case "Return":
            return .systemGreen
        default:
            return .systemGray
        }
    }
}

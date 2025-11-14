//
//  CursorModel.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Floating cursor system with gaze tracking and smooth interpolation
//

import Foundation
import RealityKit
import Combine

class CursorModel: ObservableObject {
    @Published var position: SIMD3<Float> = .zero
    @Published var isVisible: Bool = true
    @Published var targetKey: Key?

    private var textModel: TextModel?
    private var keyboardModel: KeyboardModel?

    // Cursor appearance
    private let cursorSize = SIMD3<Float>(0.01, 0.03, 0.005)
    private let cursorColor = UIColor.systemBlue
    private let highlightColor = UIColor.systemGreen

    // Animation properties
    private let smoothingFactor: Float = 0.1
    private var targetPosition: SIMD3<Float> = .zero
    private var displayLink: CADisplayLink?

    init() {
        setupDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
    }

    func setup(with textModel: TextModel, keyboardModel: KeyboardModel) {
        self.textModel = textModel
        self.keyboardModel = keyboardModel
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateCursor))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120)
        displayLink?.add(to: .main, forMode: .default)
    }

    func createCursorEntity() -> Entity {
        let cursorEntity = ModelEntity(
            mesh: .generateBox(size: cursorSize, cornerRadius: 0.001),
            materials: [SimpleMaterial(color: cursorColor, isMetallic: false)]
        )

        cursorEntity.name = "cursor"

        // Add subtle glow effect
        cursorEntity.components[OpacityComponent.self] = OpacityComponent(opacity: 0.8)

        return cursorEntity
    }

    func updateTargetPosition(_ newPosition: SIMD3<Float>) {
        targetPosition = newPosition

        // Update target key based on proximity to keyboard
        targetKey = keyboardModel?.keyAt(position: newPosition)
    }

    @objc private func updateCursor() {
        // Smooth interpolation towards target position
        let delta = targetPosition - position
        position += delta * smoothingFactor

        // Update visibility based on activity
        updateVisibility()
    }

    private func updateVisibility() {
        // Hide cursor if inactive for too long
        // This would be implemented with a timer in a full version
        isVisible = true
    }

    func handleCursorTap(at location: SIMD3<Float>) {
        // Handle cursor-specific interactions
        if let targetKey = targetKey {
            // Move cursor to key position for precise selection
            targetPosition = targetKey.position
        } else {
            // Handle text editor interaction
            handleTextEditorTap(at: location)
        }
    }

    private func handleTextEditorTap(at location: SIMD3<Float>) {
        // Convert 3D position to 2D text coordinates
        // This is a simplified implementation
        let textX = Float(location.x) * 100 // Rough conversion
        let textY = Float(location.y) * 100

        // Estimate character position (very simplified)
        let estimatedPosition = Int(textX / 10) // Assume ~10 pixels per character
        textModel?.moveCursor(to: estimatedPosition)
    }

    // MARK: - Cursor State Management

    func showCursor() {
        isVisible = true
    }

    func hideCursor() {
        isVisible = false
    }

    func setCursorColor(_ color: UIColor) {
        // Update cursor appearance
        // This would update the entity's material in a full implementation
    }

    func highlightCursor() {
        setCursorColor(highlightColor)
    }

    func unhighlightCursor() {
        setCursorColor(cursorColor)
    }

    // MARK: - Gaze Interaction

    func updateFromGaze(_ gazePosition: SIMD3<Float>) {
        updateTargetPosition(gazePosition)
    }

    func snapToNearestKey() {
        if let nearestKey = keyboardModel?.keyAt(position: position) {
            targetPosition = nearestKey.position
            targetKey = nearestKey
        }
    }

    func snapToTextPosition() {
        // Snap cursor to current text cursor position
        // This would convert text position to 3D coordinates
        // Implementation depends on text editor layout
    }

    // MARK: - Animation Helpers

    func animateToPosition(_ newPosition: SIMD3<Float>, duration: TimeInterval = 0.2) {
        targetPosition = newPosition

        // Smooth animation would be implemented here
        // For now, just set target position
    }

    func pulseAnimation() {
        // Subtle pulse effect for feedback
        // Implementation would scale the cursor briefly
    }

    func shakeAnimation() {
        // Shake effect for error feedback
        // Implementation would oscillate position briefly
    }
}

// MARK: - Cursor Extensions

extension CursorModel {
    var distanceToTarget: Float {
        distance(position, targetPosition)
    }

    var isAtTarget: Bool {
        distanceToTarget < 0.001
    }

    var movementSpeed: Float {
        // Calculate current movement speed
        // This could be used for adaptive smoothing
        distanceToTarget / Float(displayLink?.duration ?? 1.0/60.0)
    }
}

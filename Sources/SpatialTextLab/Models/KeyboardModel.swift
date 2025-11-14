//
//  KeyboardModel.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  RealityKit-based 3D keyboard with spatial interactions and animations
//

import Foundation
import RealityKit
import Combine

class KeyboardModel: ObservableObject {
    @Published var keys: [Key] = []
    @Published var highlightedKey: Key?

    private var textModel: TextModel?
    private var autocorrectEngine: AutocorrectEngine?

    // QWERTY keyboard layout
    private let qwertyLayout = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Space", "Backspace", "Return"]
    ]

    private let keySpacing: Float = 0.08
    private let rowSpacing: Float = 0.08
    private var keyEntities: [String: Entity] = [:]

    init() {
        setupKeys()
    }

    func setup(with textModel: TextModel, autocorrectEngine: AutocorrectEngine) {
        self.textModel = textModel
        self.autocorrectEngine = autocorrectEngine
    }

    private func setupKeys() {
        var keyIndex = 0

        for (rowIndex, row) in qwertyLayout.enumerated() {
            for (colIndex, keyLabel) in row.enumerated() {
                let keySize = keySize(for: keyLabel)
                let keyPosition = SIMD3<Float>(
                    Float(colIndex) * keySpacing - Float(row.count - 1) * keySpacing * 0.5,
                    -Float(rowIndex) * rowSpacing,
                    0
                )

                let key = Key(
                    id: keyIndex,
                    label: keyLabel,
                    position: keyPosition,
                    size: keySize
                )

                keys.append(key)
                keyIndex += 1
            }
        }
    }

    private func keySize(for label: String) -> SIMD3<Float> {
        switch label {
        case "Space":
            return SIMD3<Float>(0.32, 0.06, 0.02)
        case "Backspace", "Return":
            return SIMD3<Float>(0.12, 0.06, 0.02)
        default:
            return SIMD3<Float>(0.06, 0.06, 0.02)
        }
    }

    func createKeyboardEntity() -> Entity {
        let keyboardEntity = Entity()
        keyboardEntity.name = "keyboard"

        for key in keys {
            let keyEntity = createKeyEntity(for: key)
            keyboardEntity.addChild(keyEntity)
            keyEntities[key.label] = keyEntity
        }

        return keyboardEntity
    }

    private func createKeyEntity(for key: Key) -> Entity {
        let keyEntity = ModelEntity(
            mesh: .generateBox(size: key.size, cornerRadius: 0.005),
            materials: [createKeyMaterial(for: key, isHighlighted: false)]
        )

        keyEntity.position = key.position
        keyEntity.name = "key_\(key.id)"

        // Add text label using RealityKit text (visionOS 1.0+)
        if let textMesh = createTextMesh(for: key.label) {
            let textEntity = ModelEntity(mesh: textMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
            textEntity.position = SIMD3<Float>(0, 0, key.size.z * 0.6)
            textEntity.scale = SIMD3<Float>(repeating: 0.002)
            keyEntity.addChild(textEntity)
        }

        // Add collision component for interaction
        keyEntity.components[CollisionComponent.self] = CollisionComponent(
            shapes: [.generateBox(size: key.size)],
            mode: .trigger,
            filter: .default
        )

        return keyEntity
    }

    private func createTextMesh(for text: String) -> MeshResource? {
        // Create simple text mesh using available RealityKit APIs
        // In a full implementation, this would use more sophisticated text rendering
        do {
            // For now, create a placeholder mesh
            // In production, you'd use proper text mesh generation
            return try MeshResource.generateText(
                text,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.1),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
        } catch {
            // Fallback to simple box if text generation fails
            return try? MeshResource.generateBox(size: SIMD3<Float>(0.04, 0.04, 0.001))
        }
    }

    private func createKeyMaterial(for key: Key, isHighlighted: Bool) -> Material {
        let baseColor: UIColor = key.label == "Space" ? .systemGray4 :
                                key.label == "Backspace" ? .systemRed :
                                key.label == "Return" ? .systemGreen : .systemGray

        let highlightColor = isHighlighted ? UIColor.systemBlue : baseColor

        return SimpleMaterial(
            color: highlightColor,
            isMetallic: false,
            roughness: 0.3
        )
    }

    func handleKeyTap(_ entity: Entity) {
        guard let keyIdString = entity.name.split(separator: "_").last,
              let keyId = Int(keyIdString),
              let key = keys.first(where: { $0.id == keyId }) else { return }

        // Animate key press
        animateKeyPress(entity)

        // Handle key action
        processKeyAction(key)

        // Trigger autocorrect check
        if let currentWord = textModel?.currentWord() {
            autocorrectEngine?.generateSuggestions(for: currentWord.word)
        }
    }

    private func processKeyAction(_ key: Key) {
        switch key.label {
        case "Space":
            textModel?.insertSpace()
        case "Backspace":
            textModel?.deleteBackward()
        case "Return":
            textModel?.insertNewline()
        default:
            textModel?.insertCharacter(key.label.lowercased())
        }
    }

    func updateHighlights(for cursorPosition: SIMD3<Float>) {
        var closestKey: Key?
        var minDistance: Float = .infinity

        for key in keys {
            let distance = distance(cursorPosition, key.position)
            if distance < 0.05 && distance < minDistance { // 5cm threshold
                minDistance = distance
                closestKey = key
            }
        }

        // Update highlight state
        if highlightedKey != closestKey {
            // Remove old highlight
            if let oldKey = highlightedKey, let oldEntity = keyEntities[oldKey.label] {
                updateKeyMaterial(oldEntity, for: oldKey, highlighted: false)
            }

            // Add new highlight
            if let newKey = closestKey, let newEntity = keyEntities[newKey.label] {
                updateKeyMaterial(newEntity, for: newKey, highlighted: true)
            }

            highlightedKey = closestKey
        }
    }

    private func updateKeyMaterial(_ entity: Entity, for key: Key, highlighted: Bool) {
        if let modelEntity = entity as? ModelEntity {
            modelEntity.model?.materials = [createKeyMaterial(for: key, isHighlighted: highlighted)]
        }
    }

    private func animateKeyPress(_ entity: Entity) {
        let originalScale = entity.scale
        let pressedScale = originalScale * 0.9

        // Animate press down
        entity.scale = pressedScale

        // Animate back up after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            entity.scale = originalScale
        }
    }

    // MARK: - Key Proximity Detection

    func keyAt(position: SIMD3<Float>) -> Key? {
        keys.min(by: { distance($0.position, position) < distance($1.position, position) })
    }

    func isPositionOverKey(_ position: SIMD3<Float>, threshold: Float = 0.05) -> Bool {
        keys.contains { distance($0.position, position) < threshold }
    }
}

struct Key: Identifiable, Equatable, Hashable {
    let id: Int
    let label: String
    let position: SIMD3<Float>
    let size: SIMD3<Float>

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Key, rhs: Key) -> Bool {
        lhs.id == rhs.id
    }
}

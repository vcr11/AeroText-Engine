//
//  TextEditorView.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Spatial text editor with cursor positioning and gaze-based interaction
//

import SwiftUI

struct TextEditorView: View {
    @ObservedObject var textModel: TextModel
    @ObservedObject var cursorModel: CursorModel

    @State private var isEditing = false
    @State private var cursorBlinkTimer: Timer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Text display area
            ScrollView {
                Text(textModel.text.isEmpty ? "Start typing..." : textModel.text)
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
            }

            // Cursor indicator
            if isEditing && cursorModel.isVisible {
                CursorIndicator(cursorPosition: textModel.cursorPosition, text: textModel.text)
                    .offset(y: calculateCursorYOffset())
            }

            // Selection highlight (if any)
            if let selection = textModel.selectedRange {
                SelectionHighlight(range: selection, text: textModel.text)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    handleTap(at: value.location3D)
                }
        )
        .onAppear {
            startCursorBlinkTimer()
        }
        .onDisappear {
            cursorBlinkTimer?.invalidate()
        }
    }

    private func handleTap(at location: SIMD3<Float>) {
        // Convert 3D tap location to text position
        let textPosition = estimateTextPosition(from: location)
        textModel.moveCursor(to: textPosition)
        isEditing = true
        cursorModel.showCursor()
    }

    private func estimateTextPosition(from location: SIMD3<Float>) -> Int {
        // Simplified conversion from 3D space to text position
        // In a real implementation, this would use more sophisticated text layout calculations

        let lines = textModel.text.components(separatedBy: .newlines)
        let lineHeight: Float = 24 // Approximate line height
        let charWidth: Float = 10  // Approximate character width

        let y = location.y
        let x = location.x

        // Calculate line number
        let lineNumber = max(0, min(lines.count - 1, Int(-y / lineHeight)))

        // Calculate character position within line
        let lineText = lines[lineNumber]
        let charPosition = max(0, min(lineText.count, Int(x / charWidth)))

        // Calculate absolute position
        var absolutePosition = 0
        for i in 0..<lineNumber {
            absolutePosition += lines[i].count + 1 // +1 for newline
        }
        absolutePosition += charPosition

        return absolutePosition
    }

    private func calculateCursorYOffset() -> CGFloat {
        let lines = textModel.text.prefix(textModel.cursorPosition).components(separatedBy: .newlines)
        return CGFloat(lines.count - 1) * 24 // Approximate line height
    }

    private func startCursorBlinkTimer() {
        cursorBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // Cursor blinking is handled by CursorIndicator
        }
    }
}

struct CursorIndicator: View {
    let cursorPosition: Int
    let text: String

    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 2, height: 24)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                startBlinking()
            }
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            isVisible.toggle()
        }
    }
}

struct SelectionHighlight: View {
    let range: Range<String.Index>
    let text: String

    var body: some View {
        // Simplified selection highlight
        // In a full implementation, this would highlight the actual text range
        Rectangle()
            .fill(Color.blue.opacity(0.3))
            .frame(height: 24)
            .offset(y: calculateSelectionOffset())
    }

    private func calculateSelectionOffset() -> CGFloat {
        let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
        let lines = text.prefix(startIndex).components(separatedBy: .newlines)
        return CGFloat(lines.count - 1) * 24
    }
}

// MARK: - Text Layout Extensions
extension TextEditorView {
    func textSize(for text: String, font: Font) -> CGSize {
        // Simplified text size calculation
        let charWidth: CGFloat = 10
        let lineHeight: CGFloat = 24

        let lines = text.components(separatedBy: .newlines)
        let width = lines.map { $0.count }.max() ?? 0
        let height = lines.count

        return CGSize(width: CGFloat(width) * charWidth, height: CGFloat(height) * lineHeight)
    }

    func positionForCharacter(at index: Int, in text: String) -> CGPoint {
        // Simplified character position calculation
        let lines = text.prefix(index).components(separatedBy: .newlines)
        let lineNumber = lines.count - 1
        let charInLine = lines.last?.count ?? 0

        return CGPoint(x: CGFloat(charInLine) * 10, y: CGFloat(lineNumber) * 24)
    }
}

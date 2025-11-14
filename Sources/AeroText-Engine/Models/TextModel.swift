//
//  TextModel.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Core text state management with cursor positioning and editing operations
//

import Foundation
import Combine

class TextModel: ObservableObject {
    @Published var text: String = ""
    @Published var cursorPosition: Int = 0
    @Published var selectedRange: Range<String.Index>?

    private var undoStack: [(text: String, cursor: Int)] = []
    private var redoStack: [(text: String, cursor: Int)] = []
    private let maxUndoSteps = 50

    // MARK: - Text Modification Methods

    func insertCharacter(_ character: String) {
        saveToUndoStack()

        let index = text.index(text.startIndex, offsetBy: cursorPosition)
        text.insert(contentsOf: character, at: index)
        cursorPosition += character.count

        clearRedoStack()
    }

    func deleteBackward() {
        guard cursorPosition > 0 else { return }
        saveToUndoStack()

        let index = text.index(text.startIndex, offsetBy: cursorPosition - 1)
        text.remove(at: index)
        cursorPosition -= 1

        clearRedoStack()
    }

    func deleteForward() {
        guard cursorPosition < text.count else { return }
        saveToUndoStack()

        let index = text.index(text.startIndex, offsetBy: cursorPosition)
        text.remove(at: index)

        clearRedoStack()
    }

    func insertNewline() {
        insertCharacter("\n")
    }

    func insertSpace() {
        insertCharacter(" ")
    }

    // MARK: - Cursor Management

    func moveCursor(to position: Int) {
        cursorPosition = max(0, min(position, text.count))
    }

    func moveCursorLeft() {
        moveCursor(to: cursorPosition - 1)
    }

    func moveCursorRight() {
        moveCursor(to: cursorPosition + 1)
    }

    func moveCursorToBeginningOfLine() {
        let lines = text.components(separatedBy: .newlines)
        var currentPosition = 0
        var lineStart = 0

        for (index, line) in lines.enumerated() {
            let lineEnd = currentPosition + line.count
            if cursorPosition <= lineEnd {
                cursorPosition = lineStart
                break
            }
            lineStart = currentPosition + line.count + 1 // +1 for newline
            currentPosition = lineStart
        }
    }

    func moveCursorToEndOfLine() {
        let lines = text.components(separatedBy: .newlines)
        var currentPosition = 0

        for line in lines {
            let lineEnd = currentPosition + line.count
            if cursorPosition <= lineEnd {
                cursorPosition = lineEnd
                break
            }
            currentPosition = lineEnd + 1 // +1 for newline
        }
    }

    // MARK: - Selection Management

    func selectRange(_ range: Range<String.Index>) {
        selectedRange = range
    }

    func clearSelection() {
        selectedRange = nil
    }

    func selectWord(at position: Int) {
        // Find word boundaries
        let start = text.wordStartIndex(at: text.index(text.startIndex, offsetBy: position))
        let end = text.wordEndIndex(at: text.index(text.startIndex, offsetBy: position))
        selectedRange = start..<end
    }

    func deleteSelection() {
        guard let range = selectedRange else { return }
        saveToUndoStack()

        text.removeSubrange(range)
        cursorPosition = text.distance(from: text.startIndex, to: range.lowerBound)

        clearSelection()
        clearRedoStack()
    }

    // MARK: - Word Operations

    func currentWord() -> (word: String, range: Range<String.Index>)? {
        guard !text.isEmpty else { return nil }

        let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition)

        // Find word boundaries
        let start = text.wordStartIndex(at: cursorIndex)
        let end = text.wordEndIndex(at: cursorIndex)

        let word = String(text[start..<end])
        return word.isEmpty ? nil : (word, start..<end)
    }

    func replaceWord(at range: Range<String.Index>, with replacement: String) {
        saveToUndoStack()

        text.replaceSubrange(range, with: replacement)
        cursorPosition = text.distance(from: text.startIndex, to: range.lowerBound) + replacement.count

        clearRedoStack()
    }

    // MARK: - Undo/Redo

    func undo() {
        guard let previousState = undoStack.popLast() else { return }

        redoStack.append((text, cursorPosition))
        text = previousState.text
        cursorPosition = previousState.cursor
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        undoStack.append((text, cursorPosition))
        text = nextState.text
        cursorPosition = nextState.cursor
    }

    private func saveToUndoStack() {
        undoStack.append((text, cursorPosition))
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
    }

    private func clearRedoStack() {
        redoStack.removeAll()
    }

    // MARK: - Text Analysis

    func characterAtCursor() -> Character? {
        guard cursorPosition < text.count else { return nil }
        return text[text.index(text.startIndex, offsetBy: cursorPosition)]
    }

    func isAtBeginningOfText() -> Bool {
        cursorPosition == 0
    }

    func isAtEndOfText() -> Bool {
        cursorPosition >= text.count
    }

    func lineNumber(at position: Int) -> Int {
        let prefix = text.prefix(position)
        return prefix.components(separatedBy: .newlines).count
    }

    func columnNumber(at position: Int) -> Int {
        let lines = text.prefix(position).components(separatedBy: .newlines)
        return lines.last?.count ?? 0
    }
}

// MARK: - String Extensions for Word Boundaries
extension String {
    func wordStartIndex(at index: String.Index) -> String.Index {
        var current = index

        // Move backward to find word boundary
        while current > startIndex {
            let prev = self.index(before: current)
            if self[prev].isWhitespace || self[prev].isPunctuation {
                break
            }
            current = prev
        }

        return current
    }

    func wordEndIndex(at index: String.Index) -> String.Index {
        var current = index

        // Move forward to find word boundary
        while current < endIndex {
            if self[current].isWhitespace || self[current].isPunctuation {
                break
            }
            current = self.index(after: current)
        }

        return current
    }
}

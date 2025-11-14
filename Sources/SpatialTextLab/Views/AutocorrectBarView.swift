//
//  AutocorrectBarView.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Displays autocorrect suggestions with spatial interaction
//

import SwiftUI

struct AutocorrectBarView: View {
    let suggestions: [String]
    @ObservedObject var textModel: TextModel

    var body: some View {
        HStack(spacing: 12) {
            ForEach(suggestions.indices, id: \.self) { index in
                SuggestionButton(
                    suggestion: suggestions[index],
                    action: { applySuggestion(suggestions[index]) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func applySuggestion(_ suggestion: String) {
        if let currentWord = textModel.currentWord() {
            textModel.replaceWord(at: currentWord.range, with: suggestion)
        }
    }
}

struct SuggestionButton: View {
    let suggestion: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text(suggestion)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

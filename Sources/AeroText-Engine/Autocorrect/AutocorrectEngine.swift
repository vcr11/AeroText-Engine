//
//  AutocorrectEngine.swift
//  SpatialTextLab
//
//  Created by Apple Vision Pro Engineer
//  Advanced autocorrect engine with Levenshtein distance and contextual suggestions
//

import Foundation
import Combine

class AutocorrectEngine: ObservableObject {
    @Published var suggestions: [String]?

    weak var textModel: TextModel?

    // Common misspellings and their corrections
    private let correctionDictionary: [String: [String]] = [
        "teh": ["the"],
        "recieve": ["receive"],
        "seperate": ["separate"],
        "occured": ["occurred"],
        "wierd": ["weird"],
        "accomodate": ["accommodate"],
        "begining": ["beginning"],
        "beleive": ["believe"],
        "buisness": ["business"],
        "calender": ["calendar"],
        "commited": ["committed"],
        "exaggerate": ["exaggerate"],
        "exhilarate": ["exhilarate"],
        "fourty": ["forty"],
        "freind": ["friend"],
        "independant": ["independent"],
        "knowlege": ["knowledge"],
        "liason": ["liaison"],
        "occassion": ["occasion"],
        "priviledge": ["privilege"],
        "pronounciation": ["pronunciation"],
        "restaraunt": ["restaurant"],
        "rythm": ["rhythm"],
        "tommorow": ["tomorrow"],
        "vaccuum": ["vacuum"],
        "wich": ["which"],
        "reccomend": ["recommend"],
        "seperated": ["separated"],
        "comparision": ["comparison"],
        "concious": ["conscious"],
        "dissapear": ["disappear"],
        "existant": ["existent"],
        "foriegn": ["foreign"],
        "goverment": ["government"],
        "hieght": ["height"],
        "immediatly": ["immediately"],
        "judgement": ["judgment"],
        "knowlege": ["knowledge"],
        "lenght": ["length"],
        "maintainance": ["maintenance"],
        "neccessary": ["necessary"],
        "noticable": ["noticeable"],
        "occured": ["occurred"],
        "persue": ["pursue"],
        "posession": ["possession"],
        "prefered": ["preferred"],
        "reccommend": ["recommend"],
        "recieve": ["receive"],
        "rythm": ["rhythm"],
        "seperate": ["separate"],
        "succesful": ["successful"],
        "tommorrow": ["tomorrow"],
        "tounge": ["tongue"],
        "truely": ["truly"],
        "untill": ["until"],
        "vaccuum": ["vacuum"],
        "wich": ["which"]
    ]

    // Common English words for suggestions
    private let commonWords = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "has", "let", "put", "say", "she", "too", "use",
        "about", "after", "again", "air", "also", "America", "animal", "another", "answer", "any", "around", "ask", "away", "back", "because", "before", "big", "boy", "came", "change", "different", "does", "end", "even", "follow", "form", "found", "give", "good", "great", "hand", "help", "here", "home", "house", "just", "kind", "know", "land", "large", "last", "left", "life", "light", "little", "live", "man", "me", "means", "men", "most", "mother", "move", "much", "must", "name", "need", "new", "next", "only", "other", "our", "over", "part", "people", "place", "play", "put", "right", "run", "said", "same", "saw", "school", "seem", "show", "small", "sound", "still", "such", "take", "tell", "that", "their", "them", "then", "there", "these", "they", "thing", "think", "this", "time", "under", "very", "want", "water", "way", "well", "went", "were", "what", "when", "where", "which", "while", "will", "with", "word", "work", "world", "would", "write", "year", "your"
    ]

    // Cached results for performance
    private var suggestionCache = [String: [String]]()
    private let maxCacheSize = 100

    func generateSuggestions(for word: String) {
        let lowercasedWord = word.lowercased()

        // Check cache first
        if let cached = suggestionCache[lowercasedWord] {
            suggestions = cached
            return
        }

        var allSuggestions = [String]()

        // 1. Check for exact corrections
        if let corrections = correctionDictionary[lowercasedWord] {
            allSuggestions.append(contentsOf: corrections)
        }

        // 2. Generate fuzzy matches using Levenshtein distance
        let fuzzyMatches = findSimilarWords(to: lowercasedWord, maxDistance: 2)
        allSuggestions.append(contentsOf: fuzzyMatches)

        // 3. Remove duplicates and limit to top 3
        let uniqueSuggestions = Array(Set(allSuggestions)).prefix(3).map { $0 }

        // Cache the result
        suggestionCache[lowercasedWord] = uniqueSuggestions
        if suggestionCache.count > maxCacheSize {
            suggestionCache.removeValue(forKey: suggestionCache.keys.first!)
        }

        suggestions = uniqueSuggestions.isEmpty ? nil : uniqueSuggestions
    }

    func applySuggestion(_ suggestion: String) {
        guard let textModel = textModel,
              let currentWord = textModel.currentWord() else { return }

        textModel.replaceWord(at: currentWord.range, with: suggestion)
        suggestions = nil
    }

    func clearSuggestions() {
        suggestions = nil
    }

    private func findSimilarWords(to word: String, maxDistance: Int) -> [String] {
        var similarWords: [(word: String, distance: Int)] = []

        // Check common words
        for commonWord in commonWords {
            let distance = levenshteinDistance(word, commonWord)
            if distance <= maxDistance && distance > 0 {
                similarWords.append((commonWord, distance))
            }
        }

        // Check correction dictionary keys (other misspellings)
        for (misspelling, _) in correctionDictionary {
            let distance = levenshteinDistance(word, misspelling)
            if distance <= maxDistance && distance > 0 {
                similarWords.append((misspelling, distance))
            }
        }

        // Sort by distance, then alphabetically
        return similarWords
            .sorted { $0.distance < $1.distance || ($0.distance == $1.distance && $0.word < $1.word) }
            .map { $0.word }
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)

        if s1.isEmpty { return s2.count }
        if s2.isEmpty { return s1.count }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            matrix[i][0] = i
        }

        for j in 0...s2.count {
            matrix[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1

                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[s1.count][s2.count]
    }

    // MARK: - Advanced Features

    func getContextualSuggestions(for word: String, previousWords: [String] = []) -> [String] {
        // Basic contextual suggestion - can be expanded with NLP
        var contextualSuggestions = [String]()

        // Simple bigram analysis (can be enhanced with actual language model)
        if previousWords.last == "the" {
            contextualSuggestions.append(contentsOf: ["quick", "big", "small", "best"])
        } else if previousWords.last == "I" {
            contextualSuggestions.append(contentsOf: ["am", "have", "think", "want"])
        }

        return contextualSuggestions
    }

    func learnFromCorrection(original: String, correction: String) {
        // Add to correction dictionary for future suggestions
        var corrections = correctionDictionary[original.lowercased()] ?? []
        if !corrections.contains(correction.lowercased()) {
            corrections.append(correction.lowercased())
            // In a real implementation, this would persist the learning
        }
    }

    func getSuggestionConfidence(_ suggestion: String, for word: String) -> Double {
        let distance = levenshteinDistance(word.lowercased(), suggestion.lowercased())
        let maxLength = max(word.count, suggestion.count)

        // Simple confidence calculation based on edit distance
        return 1.0 - Double(distance) / Double(maxLength)
    }
}

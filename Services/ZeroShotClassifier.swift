//
//  ZeroShotClassifier.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 9/18/25.
//
import SwiftUI
import NaturalLanguage

class ZeroShotClassifier {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)!
    private let candidateLabels: [String] = ["sports", "fight", "boxing", "mma", "football", "disease", "health", "pandemic", "virus", "covid19", "traffic", "accident", "emergency", "weather", "breakingnews", "politics", "protest", "crime", "disaster", "technology"]
    
    /// Compute cosine similarity between two text strings
    private func similarity(_ text1: String, _ text2: String) -> Double {
        guard
            let vector1 = embedding.vector(for: text1),
            let vector2 = embedding.vector(for: text2)
        else { return -1 }
        
        // Cosine similarity = dot(v1, v2) / (||v1|| * ||v2||)
        let dot = zip(vector1, vector2).map(*).reduce(0, +)
        let norm1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let norm2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        
        return dot / (norm1 * norm2)
    }
    
    /// Classify text against candidate labels
    func classify(text: String) -> String? {
        var bestLabel: String?
        var bestScore = -Double.infinity
        
        for label in candidateLabels {
            let score = similarity(text, label)
            if score > bestScore {
                bestScore = score
                bestLabel = label
            }
        }
        
        return bestLabel
    }
}

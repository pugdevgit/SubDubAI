import Foundation

/// Result of audio transcription
struct TranscriptionResult: Sendable, Codable {
    let text: String           // Full transcription text
    let words: [Word]          // Array of words with timestamps
    let language: String?      // Detected or specified language
    let duration: Double?      // Total audio duration
    
    /// Number of words transcribed
    var wordCount: Int {
        return words.count
    }
    
    /// Get text for a specific time range
    func text(from startTime: Double, to endTime: Double) -> String {
        let filteredWords = words.filter { word in
            word.start >= startTime && word.end <= endTime
        }
        return filteredWords.map { $0.text }.joined(separator: " ")
    }
}

import Foundation

/// Represents a segment of text (usually a sentence) with timing information
struct Segment: Sendable, Codable {
    /// The text content of this segment
    let text: String
    
    /// Words that make up this segment
    let words: [Word]
    
    /// Start time in seconds
    let startTime: Double
    
    /// End time in seconds
    let endTime: Double
    
    /// Duration in seconds
    var duration: Double {
        endTime - startTime
    }
    
    /// Number of words in this segment
    var wordCount: Int {
        words.count
    }
}

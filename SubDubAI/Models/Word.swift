import Foundation

/// Represents a single word with timing information
struct Word: Sendable, Codable {
    let text: String
    let start: Double  // Start time in seconds
    let end: Double    // End time in seconds
    
    /// Duration of the word
    var duration: Double {
        return end - start
    }
}

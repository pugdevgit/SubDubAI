import Foundation

/// Represents a segment with both original and translated text
struct BilingualSegment: Sendable, Codable {
    /// Original text (e.g., English)
    let original: String
    
    /// Translated text (e.g., Russian)
    let translated: String
    
    /// Start time in seconds
    let startTime: Double
    
    /// End time in seconds
    let endTime: Double
    
    /// Duration in seconds
    var duration: Double {
        endTime - startTime
    }
    
    /// Format start time for SRT
    var formattedStartTime: String {
        formatSRTTime(startTime)
    }
    
    /// Format end time for SRT
    var formattedEndTime: String {
        formatSRTTime(endTime)
    }
    
    /// Format time in SRT format: HH:MM:SS,mmm
    private func formatSRTTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, millis)
    }
}

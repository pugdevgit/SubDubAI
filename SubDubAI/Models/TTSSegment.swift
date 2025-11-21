import Foundation

/// Represents a TTS audio segment with timing information
struct TTSSegment: Sendable, Codable {
    /// Segment index (for ordering)
    let index: Int
    
    /// Text to synthesize
    let text: String
    
    /// Start time in seconds (when this should play in the final video)
    let startTime: Double
    
    /// End time in seconds
    let endTime: Double
    
    /// Path to the generated audio file
    var audioPath: String?
    
    /// Duration of this segment
    var duration: Double {
        endTime - startTime
    }
    
    /// Expected output filename
    var expectedFilename: String {
        String(format: "segment_%03d.mp3", index)
    }
}

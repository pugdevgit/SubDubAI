import Foundation

/// Hardcoded configuration for the video translation pipeline
struct Configuration {
    
    // MARK: - File Paths
    
    /// Base directory (project root)
    static let baseDirectory: String = {
        // Try to find project root by looking for Input directory
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        
        // Check if we're already in the right directory
        if fileManager.fileExists(atPath: "\(currentPath)/Input") {
            return currentPath
        }
        
        // Otherwise use a hardcoded path (adjust as needed)
        return "/Users/oleg/Documents/SwiftSources/SubDubAI"
    }()
    
    /// Input directory
    static let inputDir = "\(baseDirectory)/Input"
    
    /// Output directory
    static let outputDir = "\(baseDirectory)/Output"
    
    /// Work directory for temporary files
    static let workDir = "\(baseDirectory)/Output/work"
    
    /// Input video file
    static let inputVideo = "\(inputDir)/test_video.mp4"
    
    /// Output audio file
    static let outputAudio = "\(outputDir)/audio.mp3"
    
    /// Output transcription JSON file
    static let outputTranscription = "\(outputDir)/transcription.json"
    
    /// Output English subtitles file
    static let outputEnglishSubtitles = "\(outputDir)/english_subtitles.srt"
    
    /// Output Russian subtitles file
    static let outputRussianSubtitles = "\(outputDir)/russian_subtitles.srt"
    
    /// Output TTS segments directory
    static let outputTTSSegments = "\(outputDir)/tts_segments"
    
    /// Output dubbed audio file (assembled TTS)
    static let outputDubbedAudio = "\(outputDir)/dubbed_audio.mp3"
    
    /// Output final video file (with dubbed audio)
    static let outputFinalVideo = "\(outputDir)/final_video.mp4"
    
    // MARK: - Model Configuration
    
    /// WhisperKit model name (will be downloaded automatically)
    /// Available: tiny, base, small, medium, large-v2, large-v3
    static let whisperModel = "base"
    
    /// Marian translation model path (for future use)
    static let marianModelPath = "\(baseDirectory)/models/marian"
    
    // MARK: - Language Settings
    
    /// Source language (video audio language)
    static let sourceLanguage = "en"
    
    /// Target language (translation target)
    static let targetLanguage = "ru"
    
    // MARK: - TTS Settings
    
    /// Edge TTS voice for Russian
    /// Available voices: ru-RU-DmitryNeural (male), ru-RU-SvetlanaNeural (female)
    static let ttsVoice = "ru-RU-DmitryNeural"
    
    /// TTS audio quality/rate
    static let ttsRate = "+0%" // Speed adjustment: -50% to +100%
    
    /// Enable automatic speed adjustment for TTS synchronization
    /// When true, TTS audio will be adjusted to match original segment duration
    /// When false, TTS audio will use natural speech rate (may be longer/shorter)
    static var enableSpeedSync = true
    
    // MARK: - Processing Parameters
    
    /// Segment duration in seconds (5 minutes)
    static let segmentDuration = 100
    
    /// Maximum concurrent transcriptions
    static let maxConcurrentTranscriptions = 2
    
    /// Maximum concurrent translations
    static let maxConcurrentTranslations = 3
    
    // MARK: - Helper Methods
    
    /// Ensure all required directories exist
    static func createDirectories() throws {
        let directories = [outputDir, workDir]
        let fileManager = FileManager.default
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(
                    atPath: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }
    
    /// Check if input video exists
    static func inputVideoExists() -> Bool {
        return FileManager.default.fileExists(atPath: inputVideo)
    }
}

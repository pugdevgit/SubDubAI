//
//  ProcessingConfiguration.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

// MARK: - Subtitle Format

enum SubtitleFormat: String, Sendable, Codable, CaseIterable, Equatable {
    case srt
    case vtt
    case ass
    
    var displayName: String {
        switch self {
        case .srt: return "SRT (SubRip)"
        case .vtt: return "VTT (WebVTT)"
        case .ass: return "ASS (SubStation Alpha)"
        }
    }
    
    var fileExtension: String { rawValue }
}

/// Configuration for video processing
struct ProcessingConfiguration: Sendable, Codable, Equatable {
    /// Processing mode
    var mode: ProcessingMode
    
    /// Source language code (e.g., "en", "ru", "uk")
    var sourceLanguage: String
    
    /// Target language code (e.g., "en", "ru", "uk")
    var targetLanguage: String
    
    /// Whisper model to use (tiny, base, small, medium)
    var whisperModel: String
    
    /// TTS voice name (e.g., "ru-RU-DmitryNeural")
    var ttsVoice: String
    
    /// Enable speed synchronization for TTS
    var enableSpeedSync: Bool
    
    /// Use fixed segment duration instead of dynamic segmentation
    var useFixedSegmentDuration: Bool
    
    /// Fixed segment duration in seconds (used when useFixedSegmentDuration = true)
    var fixedSegmentDuration: Double
    
    /// Custom output directory (nil = save next to source)
    var outputDirectory: URL?
    
    /// Delete temporary files after completion
    var cleanupTempFiles: Bool
    
    /// Subtitle file format to export
    var subtitleFormat: SubtitleFormat
    
    init(
        mode: ProcessingMode = .fullPipeline,
        sourceLanguage: String = "en",
        targetLanguage: String = "ru",
        whisperModel: String = "base",
        ttsVoice: String = "ru-RU-DmitryNeural",
        enableSpeedSync: Bool = true,
        useFixedSegmentDuration: Bool = false,
        fixedSegmentDuration: Double = 7.0,
        outputDirectory: URL? = nil,
        cleanupTempFiles: Bool = true,
        subtitleFormat: SubtitleFormat = .srt
    ) {
        self.mode = mode
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.whisperModel = whisperModel
        self.ttsVoice = ttsVoice
        self.enableSpeedSync = enableSpeedSync
        self.useFixedSegmentDuration = useFixedSegmentDuration
        self.fixedSegmentDuration = fixedSegmentDuration
        self.outputDirectory = outputDirectory
        self.cleanupTempFiles = cleanupTempFiles
        self.subtitleFormat = subtitleFormat
    }
    
    /// Default configuration
    static var `default`: ProcessingConfiguration {
        ProcessingConfiguration()
    }
    
    /// Validate configuration
    func validate() throws {
        guard sourceLanguage != targetLanguage else {
            throw ConfigurationError.sameSourceAndTarget
        }
        
        guard ["en", "ru", "uk"].contains(sourceLanguage) else {
            throw ConfigurationError.unsupportedLanguage(sourceLanguage)
        }
        
        guard ["en", "ru", "uk"].contains(targetLanguage) else {
            throw ConfigurationError.unsupportedLanguage(targetLanguage)
        }
        
        guard ["tiny", "base", "small", "medium"].contains(whisperModel) else {
            throw ConfigurationError.unsupportedModel(whisperModel)
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case sameSourceAndTarget
    case unsupportedLanguage(String)
    case unsupportedModel(String)
    
    var errorDescription: String? {
        switch self {
        case .sameSourceAndTarget:
            return "Source and target languages must be different"
        case .unsupportedLanguage(let lang):
            return "Unsupported language: \(lang)"
        case .unsupportedModel(let model):
            return "Unsupported Whisper model: \(model)"
        }
    }
}

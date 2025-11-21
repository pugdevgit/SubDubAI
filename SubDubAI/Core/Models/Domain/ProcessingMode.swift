//
//  ProcessingMode.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// Processing mode determining which steps to execute
enum ProcessingMode: String, Sendable, Codable, CaseIterable {
    case subtitlesOnly = "subtitles_only"
    case subtitlesWithTranslation = "subtitles_translation"
    case dubbedVideoOnly = "dubbed_video_only"
    case fullPipeline = "full_pipeline"
    
    var displayName: String {
        switch self {
        case .subtitlesOnly: return "Subtitles Only"
        case .subtitlesWithTranslation: return "Subtitles + Translation"
        case .dubbedVideoOnly: return "Dubbed Video Only"
        case .fullPipeline: return "Full Pipeline"
        }
    }
    
    var description: String {
        switch self {
        case .subtitlesOnly:
            return "Generate subtitles in source language only"
        case .subtitlesWithTranslation:
            return "Generate subtitles in source and target languages"
        case .dubbedVideoOnly:
            return "Create video with translated audio (no subtitle files)"
        case .fullPipeline:
            return "Generate subtitles and dubbed video"
        }
    }
    
    /// Steps required for this processing mode
    var steps: [ProcessingStep] {
        switch self {
        case .subtitlesOnly:
            return [
                .extractingAudio,
                .transcribing,
                .generatingSubtitles
            ]
            
        case .subtitlesWithTranslation:
            return [
                .extractingAudio,
                .transcribing,
                .translating,
                .generatingSubtitles
            ]
            
        case .dubbedVideoOnly:
            return [
                .extractingAudio,
                .transcribing,
                .translating,
                .generatingTTS,
                .assemblingAudio,
                .composingVideo
            ]
            
        case .fullPipeline:
            return [
                .extractingAudio,
                .transcribing,
                .translating,
                .generatingSubtitles,
                .generatingTTS,
                .assemblingAudio,
                .composingVideo
            ]
        }
    }
    
    var requiresTranslation: Bool {
        self != .subtitlesOnly
    }
    
    var generatesSubtitles: Bool {
        self == .subtitlesOnly || self == .subtitlesWithTranslation || self == .fullPipeline
    }
    
    var generatesVideo: Bool {
        self == .dubbedVideoOnly || self == .fullPipeline
    }
}

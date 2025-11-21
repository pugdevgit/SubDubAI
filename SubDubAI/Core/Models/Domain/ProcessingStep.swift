//
//  ProcessingStep.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// Steps in the video processing pipeline
enum ProcessingStep: Int, Sendable, Codable, CaseIterable {
    case idle = 0
    case extractingAudio = 1
    case transcribing = 2
    case translating = 3
    case generatingSubtitles = 4
    case generatingTTS = 5
    case assemblingAudio = 6
    case composingVideo = 7
    case completed = 8
    
    var title: String {
        switch self {
        case .idle: return "Idle"
        case .extractingAudio: return "Extracting Audio"
        case .transcribing: return "Transcribing"
        case .translating: return "Translating"
        case .generatingSubtitles: return "Generating Subtitles"
        case .generatingTTS: return "Generating TTS"
        case .assemblingAudio: return "Assembling Audio"
        case .composingVideo: return "Composing Video"
        case .completed: return "Completed"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .extractingAudio: return "waveform"
        case .transcribing: return "text.bubble"
        case .translating: return "globe"
        case .generatingSubtitles: return "doc.text"
        case .generatingTTS: return "speaker.wave.3"
        case .assemblingAudio: return "waveform.circle"
        case .composingVideo: return "film"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var progressWeight: Double {
        switch self {
        case .idle: return 0.0
        case .extractingAudio: return 0.10
        case .transcribing: return 0.25
        case .translating: return 0.15
        case .generatingSubtitles: return 0.10
        case .generatingTTS: return 0.20
        case .assemblingAudio: return 0.10
        case .composingVideo: return 0.10
        case .completed: return 1.0
        }
    }
}

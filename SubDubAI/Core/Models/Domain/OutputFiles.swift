//
//  OutputFiles.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// Output files created during processing
struct OutputFiles: Sendable, Codable, Equatable {
    /// Original language subtitles
    var originalSubtitles: URL?
    
    /// Translated subtitles
    var translatedSubtitles: URL?
    
    /// Dubbed video file
    var dubbedVideo: URL?
    
    /// Extracted audio (temporary)
    var extractedAudio: URL?
    
    /// Transcription JSON (temporary)
    var transcription: URL?
    
    init(
        originalSubtitles: URL? = nil,
        translatedSubtitles: URL? = nil,
        dubbedVideo: URL? = nil,
        extractedAudio: URL? = nil,
        transcription: URL? = nil
    ) {
        self.originalSubtitles = originalSubtitles
        self.translatedSubtitles = translatedSubtitles
        self.dubbedVideo = dubbedVideo
        self.extractedAudio = extractedAudio
        self.transcription = transcription
    }
    
    var hasAnyOutput: Bool {
        originalSubtitles != nil || translatedSubtitles != nil || dubbedVideo != nil
    }
    
    var outputFileCount: Int {
        var count = 0
        if originalSubtitles != nil { count += 1 }
        if translatedSubtitles != nil { count += 1 }
        if dubbedVideo != nil { count += 1 }
        return count
    }
}

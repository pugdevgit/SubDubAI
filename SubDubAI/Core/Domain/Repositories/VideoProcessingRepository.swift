//
//  VideoProcessingRepository.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol VideoProcessingRepositoryProtocol: Sendable {
    func extractAudio(from videoURL: URL, to audioURL: URL) async throws
    
    func transcribe(
        audioURL: URL,
        language: String,
        model: String,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws -> TranscriptionResult
    
    func segmentWords(
        from result: TranscriptionResult,
        useFixedSegmentDuration: Bool,
        fixedSegmentDuration: Double
    ) async throws -> [Segment]
    
    func translate(
        segments: [Segment],
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> [BilingualSegment]
    
    func generateSubtitles(
        segments: [BilingualSegment],
        originalPath: URL,
        translatedPath: URL?,
        format: SubtitleFormat
    ) async throws
    
    func generateTTS(
        segments: [BilingualSegment],
        outputDir: URL,
        voice: String,
        enableSpeedSync: Bool,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws -> [TTSSegment]
    
    func assembleAudio(
        segments: [TTSSegment],
        outputPath: URL,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws
    
    func composeVideo(
        inputVideo: URL,
        audio: URL,
        subtitles: URL?,
        output: URL
    ) async throws
}

private actor InitState {
    private var initialized = false
    func isInitialized() -> Bool { initialized }
    func markInitialized() { initialized = true }
}

final class VideoProcessingRepository: VideoProcessingRepositoryProtocol {
    private let audioService: AudioService
    private let transcriptionService: TranscriptionService
    private let segmentationService: SentenceSegmentationService
    private let translationService: TranslationService
    private let subtitleService: SubtitleGeneratorService
    private let ttsService: TTSService
    private let audioAssemblyService: AudioAssemblyService
    private let videoCompositionService: VideoCompositionService
    
    private let initState = InitState()
    
    init(
        audioService: AudioService,
        transcriptionService: TranscriptionService,
        segmentationService: SentenceSegmentationService,
        translationService: TranslationService,
        subtitleService: SubtitleGeneratorService,
        ttsService: TTSService,
        audioAssemblyService: AudioAssemblyService,
        videoCompositionService: VideoCompositionService
    ) {
        self.audioService = audioService
        self.transcriptionService = transcriptionService
        self.segmentationService = segmentationService
        self.translationService = translationService
        self.subtitleService = subtitleService
        self.ttsService = ttsService
        self.audioAssemblyService = audioAssemblyService
        self.videoCompositionService = videoCompositionService
    }
    
    private func ensureWhisperInitialized() async throws {
        // Async-safe check
        if await initState.isInitialized() { return }

        print("🔧 Initializing WhisperKit...")
        let success = await transcriptionService.initialize { @Sendable message in
            print("   \(message)")
        }

        if !success {
            throw RepositoryError.transcriptionFailed
        }

        await initState.markInitialized()
        print("✅ WhisperKit ready")
    }
    
    func extractAudio(from videoURL: URL, to audioURL: URL) async throws {
        let success = await audioService.extractAudio(
            from: videoURL.path,
            to: audioURL.path,
            onProgress: { _ in }
        )
        
        if !success {
            throw RepositoryError.audioExtractionFailed
        }
    }
    
    func transcribe(
        audioURL: URL,
        language: String,
        model: String,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws -> TranscriptionResult {
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        // Initialize WhisperKit if not already done
        try await ensureWhisperInitialized()
        
        // Check for cancellation after initialization
        try Task.checkCancellation()
        
        guard let result = await transcriptionService.transcribe(
            audioPath: audioURL.path,
            language: language,
            onProgress: { _ in }
        ) else {
            throw RepositoryError.transcriptionFailed
        }
        
        return result
    }
    
    func segmentWords(
        from result: TranscriptionResult,
        useFixedSegmentDuration: Bool,
        fixedSegmentDuration: Double
    ) async throws -> [Segment] {
        let segments = segmentationService.segment(
            words: result.words,
            useFixedDuration: useFixedSegmentDuration,
            fixedDuration: fixedSegmentDuration,
            onProgress: { _ in }
        )
        
        if segments.isEmpty {
            throw RepositoryError.segmentationFailed
        }
        
        return segments
    }
    
    func translate(
        segments: [Segment],
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> [BilingualSegment] {
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        let result = await translationService.translate(
            segments: segments,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            onProgress: { _ in }
        )
        
        // Check for cancellation after translation
        try Task.checkCancellation()
        
        if result.isEmpty {
            throw RepositoryError.translationFailed
        }
        
        return result
    }
    
    func generateSubtitles(
        segments: [BilingualSegment],
        originalPath: URL,
        translatedPath: URL?,
        format: SubtitleFormat
    ) async throws {
        print("📝 Generating subtitles...")
        print("   Original path: \(originalPath.path)")
        print("   Translated path: \(translatedPath?.path ?? "nil")")
        print("   Segments count: \(segments.count)")
        
        // If translatedPath is nil, only generate original subtitles
        if let translatedPath = translatedPath {
            print("   Mode: Both files (original + translated)")
            let success = subtitleService.generateBoth(
                format: format,
                segments: segments,
                originalPath: originalPath.path,
                translatedPath: translatedPath.path,
                onProgress: { message in print("   \(message)") }
            )
            
            if !success {
                print("❌ Subtitle generation failed!")
                throw RepositoryError.subtitleGenerationFailed
            }
            print("✅ Both subtitle files generated")
        } else {
            print("   Mode: Original only")
            let ok = subtitleService.generateSingle(
                format: format,
                segments: segments,
                path: originalPath.path,
                useTranslated: false,
                onProgress: { message in print("   \(message)") }
            )
            if !ok {
                print("❌ Failed to save original subtitle")
                throw RepositoryError.subtitleGenerationFailed
            }
            print("✅ Original subtitle generated")
        }
    }
    
    func generateTTS(
        segments: [BilingualSegment],
        outputDir: URL,
        voice: String,
        enableSpeedSync: Bool,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws -> [TTSSegment] {
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        let result = await ttsService.generateTTS(
            segments: segments,
            outputDir: outputDir.path,
            voice: voice,
            enableSpeedSync: enableSpeedSync,
            onProgress: { _ in }
        )
        
        // Check for cancellation after TTS generation
        try Task.checkCancellation()
        
        if result.isEmpty {
            throw RepositoryError.ttsFailed
        }
        
        return result
    }
    
    func assembleAudio(
        segments: [TTSSegment], 
        outputPath: URL,
        onProgress: @escaping @Sendable @MainActor (Double) async -> Void
    ) async throws {
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        print("🎵 Assembling audio...")
        print("   Segments count: \(segments.count)")
        print("   Output path: \(outputPath.path)")
        
        let success = await audioAssemblyService.assembleAudio(
            ttsSegments: segments,
            outputPath: outputPath.path,
            onProgress: { message, progress in
                print("   \(message)")
                Task { @MainActor in
                    await onProgress(progress) // Use actual progress from service
                }
            }
        )
        
        if !success {
            print("❌ Audio assembly failed!")
            throw RepositoryError.audioAssemblyFailed
        }
        
        print("✅ Audio assembly completed")
    }
    
    func composeVideo(
        inputVideo: URL,
        audio: URL,
        subtitles: URL?,
        output: URL
    ) async throws {
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        let success = await videoCompositionService.composeVideo(
            inputVideo: inputVideo.path,
            dubbedAudio: audio.path,
            subtitlePath: subtitles?.path,
            outputVideo: output.path,
            onProgress: { _ in }
        )
        
        if !success {
            throw RepositoryError.videoCompositionFailed
        }
    }
}

enum RepositoryError: LocalizedError {
    case audioExtractionFailed
    case transcriptionFailed
    case segmentationFailed
    case translationFailed
    case subtitleGenerationFailed
    case ttsFailed
    case audioAssemblyFailed
    case videoCompositionFailed
    
    var errorDescription: String? {
        switch self {
        case .audioExtractionFailed: return "Audio extraction failed"
        case .transcriptionFailed: return "Transcription failed"
        case .segmentationFailed: return "Segmentation failed"
        case .translationFailed: return "Translation failed"
        case .subtitleGenerationFailed: return "Subtitle generation failed"
        case .ttsFailed: return "TTS generation failed"
        case .audioAssemblyFailed: return "Audio assembly failed"
        case .videoCompositionFailed: return "Video composition failed"
        }
    }
}

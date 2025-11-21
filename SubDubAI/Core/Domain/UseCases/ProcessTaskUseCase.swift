//
//  ProcessTaskUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol ProcessTaskUseCaseProtocol: Sendable {
    func execute(
        task: ProcessingTask,
        onProgress: @escaping @Sendable @MainActor (ProcessingProgress) async -> Void
    ) async throws -> ProcessingTask
}

final class ProcessTaskUseCase: ProcessTaskUseCaseProtocol {
    private let repository: VideoProcessingRepositoryProtocol
    
    init(repository: VideoProcessingRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(
        task: ProcessingTask,
        onProgress: @escaping @Sendable @MainActor (ProcessingProgress) async -> Void
    ) async throws -> ProcessingTask {
        // Log start
        print("🎬 ProcessTaskUseCase START:")
        print("   Task: \(task.fileName)")
        print("   Mode: \(task.config.mode)")
        print("   Steps: \(task.config.mode.steps.count)")
        
        var updatedTask = task
        updatedTask.status = .processing
        updatedTask.startedAt = Date()
        
        let steps = task.config.mode.steps
        var outputFiles = OutputFiles()
        
        // Setup paths
        let videoDir = task.videoURL.deletingLastPathComponent()
        let tempDir = videoDir.appendingPathComponent(".subdubai/\(task.id.uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Ensure cleanup happens even if task fails
        defer {
            if task.config.cleanupTempFiles {
                try? FileManager.default.removeItem(at: tempDir)
                
                // Also remove parent .subdubai folder if it's empty
                let parentDir = tempDir.deletingLastPathComponent()
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: parentDir.path),
                   contents.isEmpty {
                    try? FileManager.default.removeItem(at: parentDir)
                }
            }
        }
        
        let audioURL = tempDir.appendingPathComponent("audio.mp3")
        let subtitleExt = task.config.subtitleFormat.fileExtension
        let originalSubtitlesURL = videoDir.appendingPathComponent("\(task.fileNameWithoutExtension)_\(task.config.sourceLanguage).\(subtitleExt)")
        let translatedSubtitlesURL = videoDir.appendingPathComponent("\(task.fileNameWithoutExtension)_\(task.config.targetLanguage).\(subtitleExt)")
        let dubbedVideoURL = videoDir.appendingPathComponent("\(task.fileNameWithoutExtension)_\(task.config.targetLanguage).mp4")
        
        do {
            // Execute steps based on mode
            var transcriptionResult: TranscriptionResult?
            var segments: [Segment]?
            var bilingualSegments: [BilingualSegment]?
            var ttsSegments: [TTSSegment]?
            
            for (index, step) in steps.enumerated() {
                // Check for cancellation before each step
                try Task.checkCancellation()
                
                updatedTask.currentStep = step
                let stepProgress = Double(index) / Double(steps.count)
                
                await onProgress(ProcessingProgress(
                    step: step,
                    stepProgress: 0.0,
                    overallProgress: stepProgress,
                    message: step.title
                ))
                
                switch step {
                case .extractingAudio:
                    try await repository.extractAudio(from: task.videoURL, to: audioURL)
                    outputFiles.extractedAudio = audioURL
                    
                case .transcribing:
                    transcriptionResult = try await repository.transcribe(
                        audioURL: audioURL,
                        language: task.config.sourceLanguage,
                        model: task.config.whisperModel,
                        onProgress: { progress in
                            await onProgress(ProcessingProgress(
                                step: step,
                                stepProgress: progress,
                                overallProgress: stepProgress + (progress * step.progressWeight),
                                message: "Transcribing... \(Int(progress * 100))%"
                            ))
                        }
                    )
                    
                    if let result = transcriptionResult {
                        segments = try await repository.segmentWords(
                            from: result,
                            useFixedSegmentDuration: task.config.useFixedSegmentDuration,
                            fixedSegmentDuration: task.config.fixedSegmentDuration
                        )
                    }
                    
                case .translating:
                    guard let segs = segments else { throw ProcessingError.missingSegments }
                    bilingualSegments = try await repository.translate(
                        segments: segs,
                        from: task.config.sourceLanguage,
                        to: task.config.targetLanguage
                    )
                    
                case .generatingSubtitles:
                    // For subtitlesOnly mode, convert Segments to BilingualSegments without translation
                    if task.config.mode == .subtitlesOnly {
                        guard let segs = segments else { throw ProcessingError.missingSegments }
                        
                        // Convert to BilingualSegments with same text for both languages
                        let biSegs = segs.map { segment in
                            BilingualSegment(
                                original: segment.text,
                                translated: segment.text,
                                startTime: segment.startTime,
                                endTime: segment.endTime
                            )
                        }
                        
                        try await repository.generateSubtitles(
                            segments: biSegs,
                            originalPath: originalSubtitlesURL,
                            translatedPath: nil,
                            format: task.config.subtitleFormat
                        )
                        outputFiles.originalSubtitles = originalSubtitlesURL
                    } else {
                        // For other modes, use translated BilingualSegments
                        guard let biSegs = bilingualSegments else { throw ProcessingError.missingBilingualSegments }
                        
                        try await repository.generateSubtitles(
                            segments: biSegs,
                            originalPath: originalSubtitlesURL,
                            translatedPath: translatedSubtitlesURL,
                            format: task.config.subtitleFormat
                        )
                        outputFiles.originalSubtitles = originalSubtitlesURL
                        outputFiles.translatedSubtitles = translatedSubtitlesURL
                    }
                    
                case .generatingTTS:
                    guard let biSegs = bilingualSegments else { throw ProcessingError.missingBilingualSegments }
                    let ttsDir = tempDir.appendingPathComponent("tts")
                    try FileManager.default.createDirectory(at: ttsDir, withIntermediateDirectories: true)
                    
                    ttsSegments = try await repository.generateTTS(
                        segments: biSegs,
                        outputDir: ttsDir,
                        voice: task.config.ttsVoice,
                        enableSpeedSync: task.config.enableSpeedSync,
                        onProgress: { progress in
                            await onProgress(ProcessingProgress(
                                step: step,
                                stepProgress: progress,
                                overallProgress: stepProgress + (progress * step.progressWeight),
                                message: "Generating TTS... \(Int(progress * 100))%"
                            ))
                        }
                    )
                    
                case .assemblingAudio:
                    guard let ttsSegs = ttsSegments else { throw ProcessingError.missingTTSSegments }
                    let dubbedAudioURL = tempDir.appendingPathComponent("dubbed_audio.mp3")
                    try await repository.assembleAudio(
                        segments: ttsSegs, 
                        outputPath: dubbedAudioURL,
                        onProgress: { progress in
                            await onProgress(ProcessingProgress(
                                step: step,
                                stepProgress: progress,
                                overallProgress: stepProgress + (progress * step.progressWeight),
                                message: "Assembling audio... \(Int(progress * 100))%"
                            ))
                        }
                    )
                    
                case .composingVideo:
                    let dubbedAudioURL = tempDir.appendingPathComponent("dubbed_audio.mp3")
                    let subtitlePath = task.config.mode == .fullPipeline ? translatedSubtitlesURL : nil
                    
                    try await repository.composeVideo(
                        inputVideo: task.videoURL,
                        audio: dubbedAudioURL,
                        subtitles: subtitlePath,
                        output: dubbedVideoURL
                    )
                    outputFiles.dubbedVideo = dubbedVideoURL
                    
                default:
                    break
                }
            }
            
            // Success
            updatedTask.status = .completed
            updatedTask.currentStep = .completed
            updatedTask.progress = 1.0
            updatedTask.completedAt = Date()
            updatedTask.outputFiles = outputFiles
            
            await onProgress(ProcessingProgress(
                step: .completed,
                stepProgress: 1.0,
                overallProgress: 1.0,
                message: "Processing complete!"
            ))
            
            return updatedTask
            
        } catch {
            // Log error to console
            print("❌ ProcessTaskUseCase ERROR:")
            print("   Task: \(task.fileName)")
            print("   Step: \(updatedTask.currentStep.title)")
            print("   Error: \(error.localizedDescription)")
            if let error = error as NSError? {
                print("   Details: \(error.debugDescription)")
            }
            
            updatedTask.status = .failed
            updatedTask.error = error.localizedDescription
            updatedTask.completedAt = Date()
            throw error
        }
    }
}

enum ProcessingError: LocalizedError {
    case missingSegments
    case missingBilingualSegments
    case missingTTSSegments
    
    var errorDescription: String? {
        switch self {
        case .missingSegments: return "Segments not available"
        case .missingBilingualSegments: return "Bilingual segments not available"
        case .missingTTSSegments: return "TTS segments not available"
        }
    }
}

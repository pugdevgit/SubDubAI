//
//  ProcessingTask.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// A video processing task
struct ProcessingTask: Sendable, Identifiable, Codable, Equatable {
    /// Unique identifier
    let id: UUID
    
    /// URL to the source video file
    var videoURL: URL
    
    /// Current status
    var status: TaskStatus
    
    /// Current processing step
    var currentStep: ProcessingStep
    
    /// Overall progress (0.0 - 1.0)
    var progress: Double
    
    /// Processing configuration
    var config: ProcessingConfiguration
    
    /// Created timestamp
    var createdAt: Date
    
    /// Started timestamp
    var startedAt: Date?
    
    /// Completed timestamp
    var completedAt: Date?
    
    /// Output files
    var outputFiles: OutputFiles?
    
    /// Error message if failed
    var error: String?
    
    /// File size in bytes
    var fileSize: Int64?
    
    init(
        id: UUID = UUID(),
        videoURL: URL,
        status: TaskStatus = .pending,
        currentStep: ProcessingStep = .idle,
        progress: Double = 0.0,
        config: ProcessingConfiguration,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        outputFiles: OutputFiles? = nil,
        error: String? = nil,
        fileSize: Int64? = nil
    ) {
        self.id = id
        self.videoURL = videoURL
        self.status = status
        self.currentStep = currentStep
        self.progress = progress
        self.config = config
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.outputFiles = outputFiles
        self.error = error
        self.fileSize = fileSize
    }
}

// MARK: - Computed Properties

extension ProcessingTask {
    /// Video file name
    var fileName: String {
        videoURL.lastPathComponent
    }
    
    /// Video file name without extension
    var fileNameWithoutExtension: String {
        videoURL.deletingPathExtension().lastPathComponent
    }
    
    /// Formatted file size
    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    /// Duration since task was created
    var elapsedTime: TimeInterval? {
        guard let started = startedAt else { return nil }
        let end = completedAt ?? Date()
        return end.timeIntervalSince(started)
    }
    
    /// Formatted elapsed time
    var formattedElapsedTime: String? {
        guard let elapsed = elapsedTime else { return nil }
        
        let hours = Int(elapsed / 3600)
        let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(elapsed.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Steps required for this task's processing mode
    var requiredSteps: [ProcessingStep] {
        config.mode.steps
    }
    
    /// Current step index (0-based)
    var currentStepIndex: Int? {
        requiredSteps.firstIndex(of: currentStep)
    }
    
    /// Total number of steps
    var totalSteps: Int {
        requiredSteps.count
    }
    
    /// Is task currently processing
    var isProcessing: Bool {
        status == .processing
    }
    
    /// Is task completed (success, failed, or cancelled)
    var isCompleted: Bool {
        status.isCompleted
    }
    
    /// Can task be started
    var canStart: Bool {
        status == .pending
    }
    
    /// Can task be cancelled
    var canCancel: Bool {
        status == .processing
    }
    
    /// Can task be retried
    var canRetry: Bool {
        status == .failed
    }
}

// MARK: - Factory Methods

extension ProcessingTask {
    /// Create task from video URL with default configuration
    static func from(videoURL: URL, config: ProcessingConfiguration = .default) -> ProcessingTask {
        ProcessingTask(videoURL: videoURL, config: config)
    }
    
    /// Create multiple tasks from video URLs
    static func from(videoURLs: [URL], config: ProcessingConfiguration = .default) -> [ProcessingTask] {
        videoURLs.map { ProcessingTask(videoURL: $0, config: config) }
    }
}

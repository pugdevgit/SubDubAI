//
//  ProcessingProgress.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// Progress information for a processing task
struct ProcessingProgress: Sendable, Equatable {
    /// Current processing step
    let step: ProcessingStep
    
    /// Progress within current step (0.0 - 1.0)
    let stepProgress: Double
    
    /// Overall progress (0.0 - 1.0)
    let overallProgress: Double
    
    /// Current status message
    let message: String?
    
    /// Estimated time remaining in seconds
    let estimatedTimeRemaining: TimeInterval?
    
    init(
        step: ProcessingStep,
        stepProgress: Double = 0.0,
        overallProgress: Double = 0.0,
        message: String? = nil,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.step = step
        self.stepProgress = max(0.0, min(1.0, stepProgress))
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.message = message
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
    
    /// Format ETA as human-readable string
    var formattedETA: String? {
        guard let time = estimatedTimeRemaining else { return nil }
        
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

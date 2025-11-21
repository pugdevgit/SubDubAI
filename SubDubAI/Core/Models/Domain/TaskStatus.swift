//
//  TaskStatus.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

/// Status of a processing task
enum TaskStatus: String, Sendable, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "play.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .cancelled: return "stop.circle"
        }
    }
    
    var isActive: Bool {
        self == .processing
    }
    
    var isCompleted: Bool {
        self == .completed || self == .failed || self == .cancelled
    }
}

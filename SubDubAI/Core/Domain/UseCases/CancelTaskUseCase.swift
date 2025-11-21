//
//  CancelTaskUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol CancelTaskUseCaseProtocol: Sendable {
    func execute(task: ProcessingTask) -> ProcessingTask
}

final class CancelTaskUseCase: CancelTaskUseCaseProtocol {
    func execute(task: ProcessingTask) -> ProcessingTask {
        var updatedTask = task
        updatedTask.status = .cancelled
        updatedTask.completedAt = Date()
        return updatedTask
    }
}

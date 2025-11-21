//
//  RemoveTaskUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol RemoveTaskUseCaseProtocol: Sendable {
    func execute(taskId: UUID, from tasks: [ProcessingTask]) -> [ProcessingTask]
}

final class RemoveTaskUseCase: RemoveTaskUseCaseProtocol {
    func execute(taskId: UUID, from tasks: [ProcessingTask]) -> [ProcessingTask] {
        tasks.filter { $0.id != taskId }
    }
}

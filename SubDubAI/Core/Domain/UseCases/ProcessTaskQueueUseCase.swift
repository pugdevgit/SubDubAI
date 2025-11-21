//
//  ProcessTaskQueueUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol ProcessTaskQueueUseCaseProtocol: Sendable {
    func execute(
        tasks: [ProcessingTask],
        maxConcurrent: Int,
        onTaskUpdate: @escaping @Sendable @MainActor (ProcessingTask) async -> Void
    ) async
}

final class ProcessTaskQueueUseCase: ProcessTaskQueueUseCaseProtocol {
    private let processTaskUseCase: ProcessTaskUseCaseProtocol
    
    init(processTaskUseCase: ProcessTaskUseCaseProtocol) {
        self.processTaskUseCase = processTaskUseCase
    }
    
    func execute(
        tasks: [ProcessingTask],
        maxConcurrent: Int,
        onTaskUpdate: @escaping @Sendable @MainActor (ProcessingTask) async -> Void
    ) async {
        // Filter only pending tasks
        let pendingTasks = tasks.filter { $0.status == .pending }
        
        guard !pendingTasks.isEmpty else { return }
        
        await withTaskGroup(of: Void.self) { group in
            var iterator = pendingTasks.makeIterator()
            var activeTasks = 0
            
            // Start initial batch
            while activeTasks < maxConcurrent, let task = iterator.next() {
                group.addTask {
                    await self.processTask(task, onTaskUpdate: onTaskUpdate)
                }
                activeTasks += 1
            }
            
            // As tasks complete, start new ones
            for await _ in group {
                activeTasks -= 1
                
                if let nextTask = iterator.next() {
                    group.addTask {
                        await self.processTask(nextTask, onTaskUpdate: onTaskUpdate)
                    }
                    activeTasks += 1
                }
            }
        }
    }
    
    private func processTask(
        _ task: ProcessingTask,
        onTaskUpdate: @escaping @Sendable @MainActor (ProcessingTask) async -> Void
    ) async {
        // Update task as processing
        var processingTask = task
        processingTask.status = .processing
        await onTaskUpdate(processingTask)
        
        do {
            let completedTask = try await processTaskUseCase.execute(
                task: task,
                onProgress: { @MainActor progress in
                    var updatedTask = task
                    updatedTask.status = .processing
                    updatedTask.currentStep = progress.step
                    updatedTask.progress = progress.overallProgress
                    await onTaskUpdate(updatedTask)
                }
            )
            
            await onTaskUpdate(completedTask)
            
        } catch {
            var failedTask = task
            failedTask.status = .failed
            failedTask.error = error.localizedDescription
            failedTask.completedAt = Date()
            await onTaskUpdate(failedTask)
        }
    }
}

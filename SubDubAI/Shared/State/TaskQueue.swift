//
//  TaskQueue.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TaskQueue: ObservableObject {
    @Published private(set) var tasks: [ProcessingTask] = []
    @Published var isProcessing = false
    
    // Track active processing tasks for cancellation
    private var activeTaskHandles: [UUID: Task<Void?, Never>] = [:]
    private var maxConcurrentTasks: Int = 3
    private var pendingTaskQueue: [ProcessingTask] = []
    
    private let addTasksUseCase: AddTasksUseCaseProtocol
    private let addTasksFromFolderUseCase: AddTasksFromFolderUseCaseProtocol
    private let processTaskQueueUseCase: ProcessTaskQueueUseCaseProtocol
    private let processTaskUseCase: ProcessTaskUseCaseProtocol
    private let cancelTaskUseCase: CancelTaskUseCaseProtocol
    private let removeTaskUseCase: RemoveTaskUseCaseProtocol
    
    init(
        addTasksUseCase: AddTasksUseCaseProtocol,
        addTasksFromFolderUseCase: AddTasksFromFolderUseCaseProtocol,
        processTaskQueueUseCase: ProcessTaskQueueUseCaseProtocol,
        processTaskUseCase: ProcessTaskUseCaseProtocol,
        cancelTaskUseCase: CancelTaskUseCaseProtocol,
        removeTaskUseCase: RemoveTaskUseCaseProtocol
    ) {
        self.addTasksUseCase = addTasksUseCase
        self.addTasksFromFolderUseCase = addTasksFromFolderUseCase
        self.processTaskQueueUseCase = processTaskQueueUseCase
        self.processTaskUseCase = processTaskUseCase
        self.cancelTaskUseCase = cancelTaskUseCase
        self.removeTaskUseCase = removeTaskUseCase
    }
}

// MARK: - CRUD Operations

extension TaskQueue {
    /// Add tasks from video URLs
    func addTasks(videoURLs: [URL], config: ProcessingConfiguration) {
        let newTasks = addTasksUseCase.execute(videoURLs: videoURLs, config: config)
        tasks.append(contentsOf: newTasks)
    }
    
    /// Add tasks from folder
    func addTasksFromFolder(folderURL: URL, config: ProcessingConfiguration) {
        let newTasks = addTasksFromFolderUseCase.execute(folderURL: folderURL, config: config)
        tasks.append(contentsOf: newTasks)
    }
    
    /// Update task
    func updateTask(_ task: ProcessingTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    /// Remove task
    func removeTask(id: UUID) {
        tasks = removeTaskUseCase.execute(taskId: id, from: tasks)
    }
    
    /// Remove all tasks (cancels active tasks first)
    func removeAllTasks() {
        // First cancel all active/processing tasks
        let activeTasks = tasks.filter { $0.status == .processing }
        for task in activeTasks {
            cancelTask(id: task.id)
        }
        
        // Clear pending queue
        pendingTaskQueue.removeAll()
        
        // Then remove all tasks
        tasks.removeAll()
        
        // Stop processing
        isProcessing = false
    }
    
    /// Remove completed tasks
    func removeCompletedTasks() {
        tasks.removeAll { $0.isCompleted }
    }
    
    /// Cancel task
    func cancelTask(id: UUID) {
        // Cancel the actual Swift Task if it's running
        if let taskHandle = activeTaskHandles[id] {
            taskHandle.cancel()
            activeTaskHandles.removeValue(forKey: id)
        }
        
        // Update task status
        if let task = tasks.first(where: { $0.id == id }) {
            let cancelledTask = cancelTaskUseCase.execute(task: task)
            updateTask(cancelledTask)
        }
    }
    
    /// Update config for all pending tasks
    func updatePendingTasksConfig(_ newConfig: ProcessingConfiguration) {
        for (index, task) in tasks.enumerated() {
            if task.status == .pending {
                tasks[index].config = newConfig
            }
        }
    }
}

// MARK: - Processing

extension TaskQueue {
    /// Start processing all pending tasks
    func startProcessing(maxConcurrent: Int = 3) {
        isProcessing = true
        maxConcurrentTasks = maxConcurrent
        
        // Get all pending tasks and add to queue
        pendingTaskQueue = tasks.filter { $0.status == .pending }
        
        print("📋 TaskQueue: \(pendingTaskQueue.count) pending tasks, maxConcurrent: \(maxConcurrent)")
        
        // Start initial batch of tasks (up to maxConcurrent)
        startNextBatch()
        
        // Notify that task queue changed
        NotificationCenter.default.post(name: .taskQueueDidChange, object: nil)
    }
    
    /// Start next batch of tasks respecting concurrency limit
    private func startNextBatch() {
        let currentActive = activeTaskHandles.count
        let canStart = maxConcurrentTasks - currentActive
        
        guard canStart > 0, !pendingTaskQueue.isEmpty else { return }
        
        let willStart = min(canStart, pendingTaskQueue.count)
        print("⚡ Starting \(willStart) tasks (active: \(currentActive), max: \(maxConcurrentTasks))")
        
        // Start up to 'canStart' tasks
        for _ in 0..<willStart {
            let task = pendingTaskQueue.removeFirst()
            startSingleTask(task)
        }
    }
    
    /// Start a single task
    private func startSingleTask(_ task: ProcessingTask) {
        let taskHandle = Task { [weak self] in
            await self?.processIndividualTask(task)
        }
        activeTaskHandles[task.id] = taskHandle
    }
    
    /// Process a single task (can be cancelled)
    private func processIndividualTask(_ task: ProcessingTask) async {
        do {
            // Check if task was cancelled before starting
            try Task.checkCancellation()
            
            // Use the injected ProcessTaskUseCase for actual processing
            let _ = try await processTaskUseCase.execute(
                task: task,
                onProgress: { [weak self] progress in
                    // Update task with progress
                    var updatedTask = task
                    updatedTask.status = .processing
                    updatedTask.progress = progress.overallProgress
                    self?.updateTask(updatedTask)
                }
            )
            
            // Task completed successfully
            var completedTask = task
            completedTask.status = .completed
            completedTask.progress = 1.0  // Ensure completed task shows 100%
            completedTask.completedAt = Date()
            updateTask(completedTask)
            
        } catch is CancellationError {
            // Task was cancelled
            var cancelledTask = task
            cancelledTask.status = .cancelled
            cancelledTask.completedAt = Date()
            updateTask(cancelledTask)
        } catch {
            // Task failed
            var failedTask = task
            failedTask.status = .failed
            failedTask.error = error.localizedDescription
            failedTask.completedAt = Date()
            updateTask(failedTask)
        }
        
        // Remove from active tasks and start next batch
        await MainActor.run {
            activeTaskHandles.removeValue(forKey: task.id)
            
            // Start next tasks from queue
            startNextBatch()
            
            // Check if all tasks are done
            if activeTaskHandles.isEmpty && pendingTaskQueue.isEmpty {
                isProcessing = false
                // Notify that processing finished
                NotificationCenter.default.post(name: .taskQueueDidChange, object: nil)
            }
        }
    }
    
    /// Stop processing (cancel all active tasks)
    func stopProcessing() {
        // Cancel active tasks
        for taskId in activeTaskHandles.keys {
            cancelTask(id: taskId)
        }
        
        // Clear pending queue
        pendingTaskQueue.removeAll()
        isProcessing = false
        
        // Notify that task queue changed
        NotificationCenter.default.post(name: .taskQueueDidChange, object: nil)
    }
    
    /// Check if there are active (processing) tasks
    var hasActiveTasks: Bool {
        !activeTasks.isEmpty
    }
}

// MARK: - Computed Properties

extension TaskQueue {
    /// Total number of tasks
    var totalCount: Int {
        tasks.count
    }
    
    /// Pending tasks
    var pendingTasks: [ProcessingTask] {
        tasks.filter { $0.status == .pending }
    }
    
    /// Processing tasks
    var activeTasks: [ProcessingTask] {
        tasks.filter { $0.status == .processing }
    }
    
    /// Completed tasks
    var completedTasks: [ProcessingTask] {
        tasks.filter { $0.status == .completed }
    }
    
    /// Failed tasks
    var failedTasks: [ProcessingTask] {
        tasks.filter { $0.status == .failed }
    }
    
    /// Cancelled tasks
    var cancelledTasks: [ProcessingTask] {
        tasks.filter { $0.status == .cancelled }
    }
    
    /// All finished tasks (completed + failed + cancelled)
    var finishedTasks: [ProcessingTask] {
        tasks.filter { $0.isCompleted }
    }
    
    /// Count of pending tasks
    var pendingCount: Int {
        pendingTasks.count
    }
    
    /// Count of processing tasks
    var activeCount: Int {
        activeTasks.count
    }
    
    /// Count of completed tasks
    var completedCount: Int {
        completedTasks.count
    }
    
    /// Count of failed tasks
    var failedCount: Int {
        failedTasks.count
    }
    
    /// Count of cancelled tasks
    var cancelledCount: Int {
        cancelledTasks.count
    }
    
    /// Is queue empty
    var isEmpty: Bool {
        tasks.isEmpty
    }
    
    
    /// Overall progress (0.0 - 1.0)
    var overallProgress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        
        let totalProgress = tasks.reduce(0.0) { sum, task in
            switch task.status {
            case .completed, .failed, .cancelled:
                return sum + 1.0  // Finished tasks = 100%
            case .processing:
                return sum + task.progress  // Use actual progress
            case .pending:
                return sum + 0.0  // Pending tasks = 0%
            }
        }
        
        let result = totalProgress / Double(tasks.count)
        
        // Debug logging
        let completed = tasks.filter { $0.status == .completed }.count
        let processing = tasks.filter { $0.status == .processing }.count
        let pending = tasks.filter { $0.status == .pending }.count
        print("📊 Progress: \(Int(result * 100))% (completed: \(completed), processing: \(processing), pending: \(pending), total: \(tasks.count))")
        
        return result
    }
    
    /// Success rate (0.0 - 1.0)
    var successRate: Double {
        let finished = finishedTasks.count
        guard finished > 0 else { return 0.0 }
        return Double(completedCount) / Double(finished)
    }
}

// MARK: - Task Retrieval

extension TaskQueue {
    /// Get task by ID
    func task(id: UUID) -> ProcessingTask? {
        tasks.first { $0.id == id }
    }
    
    /// Get tasks by status
    func tasks(with status: TaskStatus) -> [ProcessingTask] {
        tasks.filter { $0.status == status }
    }
    
    /// Get tasks by mode
    func tasks(with mode: ProcessingMode) -> [ProcessingTask] {
        tasks.filter { $0.config.mode == mode }
    }
}

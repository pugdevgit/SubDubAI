//
//  QueueViewModel.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class QueueViewModel: ObservableObject {
    @Published var selectedTaskId: UUID?
    @Published var sortOrder: SortOrder = .createdDate
    @Published var filterStatus: TaskStatus?
    @Published var searchText = ""
    @Published var showingClearAllConfirmation = false
    
    private let taskQueue: TaskQueue
    
    init(taskQueue: TaskQueue) {
        self.taskQueue = taskQueue
    }
    
    enum SortOrder {
        case createdDate
        case fileName
        case status
        case progress
    }
    
    // MARK: - Task Management
    
    func startProcessing() {
        // Load maxConcurrent from settings
        let maxConcurrent = UserDefaults.standard.integer(forKey: "maxConcurrentTasks")
        let actualMaxConcurrent = maxConcurrent == 0 ? 3 : maxConcurrent
        
        print("🚀 Starting processing with maxConcurrent: \(actualMaxConcurrent)")
        taskQueue.startProcessing(maxConcurrent: actualMaxConcurrent)
    }
    
    func stopProcessing() {
        taskQueue.stopProcessing()
    }
    
    func removeTask(id: UUID) {
        taskQueue.removeTask(id: id)
        if selectedTaskId == id {
            selectedTaskId = nil
        }
    }
    
    func removeCompletedTasks() {
        taskQueue.removeCompletedTasks()
        selectedTaskId = nil
    }
    
    func requestClearAll() {
        showingClearAllConfirmation = true
    }
    
    func confirmRemoveAllTasks() {
        taskQueue.removeAllTasks()
        selectedTaskId = nil
        showingClearAllConfirmation = false
    }
    
    func cancelTask(id: UUID) {
        taskQueue.cancelTask(id: id)
    }
    
    func selectTask(id: UUID) {
        selectedTaskId = id
    }
    
    // MARK: - Computed Properties
    
    var tasks: [ProcessingTask] {
        taskQueue.tasks
    }
    
    var filteredTasks: [ProcessingTask] {
        var result = tasks
        
        // Apply status filter
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { task in
                task.fileName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        result = sortedTasks(result, by: sortOrder)
        
        return result
    }
    
    var selectedTask: ProcessingTask? {
        guard let id = selectedTaskId else { return nil }
        return taskQueue.task(id: id)
    }
    
    var isProcessing: Bool {
        taskQueue.isProcessing
    }
    
    var isEmpty: Bool {
        taskQueue.isEmpty
    }
    
    var totalCount: Int {
        taskQueue.totalCount
    }
    
    var pendingCount: Int {
        taskQueue.pendingCount
    }
    
    var activeCount: Int {
        taskQueue.activeCount
    }
    
    var completedCount: Int {
        taskQueue.completedCount
    }
    
    var failedCount: Int {
        taskQueue.failedCount
    }
    
    var overallProgress: Double {
        taskQueue.overallProgress
    }
    
    var successRate: Double {
        taskQueue.successRate
    }
    
    var canStart: Bool {
        !taskQueue.pendingTasks.isEmpty && !isProcessing
    }
    
    var canStop: Bool {
        isProcessing
    }
    
    var canClearCompleted: Bool {
        !taskQueue.completedTasks.isEmpty
    }
    
    // MARK: - Helpers
    
    private func sortedTasks(_ tasks: [ProcessingTask], by order: SortOrder) -> [ProcessingTask] {
        switch order {
        case .createdDate:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .fileName:
            return tasks.sorted { $0.fileName < $1.fileName }
        case .status:
            return tasks.sorted { $0.status.rawValue < $1.status.rawValue }
        case .progress:
            return tasks.sorted { $0.progress > $1.progress }
        }
    }
}

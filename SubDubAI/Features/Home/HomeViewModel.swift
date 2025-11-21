//
//  HomeViewModel.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

enum PickerType {
    case files
    case folder
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var config: ProcessingConfiguration
    @Published var isShowingFilePicker = false
    @Published var pickerType: PickerType = .files
    @Published var isDragging = false
    
    private let taskQueue: TaskQueue
    private var cancellables = Set<AnyCancellable>()
    
    init(taskQueue: TaskQueue) {
        self.taskQueue = taskQueue
        // Load config from UserDefaults (same as Settings)
        self.config = SettingsViewModel.loadDefaultConfig()
        
        // Listen for settings changes from Settings window
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.reloadConfig()
                }
            }
            .store(in: &cancellables)
    }
    
    private func reloadConfig() {
        let newConfig = SettingsViewModel.loadDefaultConfig()
        config = newConfig
        
        // Update config for all pending tasks
        taskQueue.updatePendingTasksConfig(newConfig)
    }
    
    // MARK: - File Selection
    
    func selectFiles() {
        pickerType = .files
        isShowingFilePicker = true
    }
    
    func selectFolder() {
        pickerType = .folder
        isShowingFilePicker = true
    }
    
    func handleFileSelection(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        taskQueue.addTasks(videoURLs: urls, config: config)
    }
    
    func handleFolderSelection(_ url: URL) {
        taskQueue.addTasksFromFolder(folderURL: url, config: config)
    }
    
    func handlePickerSelection(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        switch pickerType {
        case .files:
            handleFileSelection(urls)
        case .folder:
            if let folderURL = urls.first {
                handleFolderSelection(folderURL)
            }
        }
    }
    
    // MARK: - Drag & Drop
    
    func handleDragEntered() {
        isDragging = true
    }
    
    func handleDragExited() {
        isDragging = false
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        isDragging = false
        
        Task { @MainActor in
            var urls: [URL] = []
            for provider in providers {
                let url: URL? = await withCheckedContinuation { continuation in
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        continuation.resume(returning: url)
                    }
                }
                if let url { urls.append(url) }
            }

            // Separate files and folders
            let files = urls.filter { !$0.hasDirectoryPath }
            let folders = urls.filter { $0.hasDirectoryPath }

            // Add files
            if !files.isEmpty {
                self.taskQueue.addTasks(videoURLs: files, config: self.config)
            }

            // Add folders
            for folder in folders {
                self.taskQueue.addTasksFromFolder(folderURL: folder, config: self.config)
            }
        }
        
        return true
    }
    
}

// MARK: - Computed Properties

extension HomeViewModel {
    var canAddTasks: Bool {
        !taskQueue.isProcessing
    }
    
    var supportedVideoTypes: [UTType] {
        [.movie, .video, .mpeg4Movie, .quickTimeMovie]
    }
    
    var allowedContentTypes: [UTType] {
        switch pickerType {
        case .files:
            return supportedVideoTypes
        case .folder:
            return [.folder]
        }
    }
    
    var allowsMultipleSelection: Bool {
        switch pickerType {
        case .files:
            return true
        case .folder:
            return false
        }
    }
}

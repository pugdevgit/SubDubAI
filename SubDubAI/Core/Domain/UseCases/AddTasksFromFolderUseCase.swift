//
//  AddTasksFromFolderUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol AddTasksFromFolderUseCaseProtocol: Sendable {
    func execute(folderURL: URL, config: ProcessingConfiguration) -> [ProcessingTask]
}

final class AddTasksFromFolderUseCase: AddTasksFromFolderUseCaseProtocol {
    private let addTasksUseCase: AddTasksUseCaseProtocol
    
    init(addTasksUseCase: AddTasksUseCaseProtocol) {
        self.addTasksUseCase = addTasksUseCase
    }
    
    func execute(folderURL: URL, config: ProcessingConfiguration) -> [ProcessingTask] {
        let videoURLs = findVideoFiles(in: folderURL)
        return addTasksUseCase.execute(videoURLs: videoURLs, config: config)
    }
    
    private func findVideoFiles(in folderURL: URL) -> [URL] {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "flv", "wmv"]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        var videoFiles: [URL] = []
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            if videoExtensions.contains(fileExtension) {
                videoFiles.append(fileURL)
            }
        }
        
        return videoFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}

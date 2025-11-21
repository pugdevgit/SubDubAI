//
//  AddTasksUseCase.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation

protocol AddTasksUseCaseProtocol: Sendable {
    func execute(videoURLs: [URL], config: ProcessingConfiguration) -> [ProcessingTask]
}

final class AddTasksUseCase: AddTasksUseCaseProtocol {
    func execute(videoURLs: [URL], config: ProcessingConfiguration) -> [ProcessingTask] {
        videoURLs.map { url in
            ProcessingTask(
                videoURL: url,
                config: config,
                fileSize: getFileSize(url)
            )
        }
    }
    
    private func getFileSize(_ url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        return fileSize
    }
}

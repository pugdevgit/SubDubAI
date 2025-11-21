//
//  SubDubAIApp.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import SwiftUI
import Combine

@main
struct SubDubAIApp: App {
    @StateObject private var appContainer = AppContainer()
    
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView(
                    homeViewModel: appContainer.homeViewModel,
                    queueViewModel: appContainer.queueViewModel,
                    subtitlesViewModel: appContainer.subtitlesViewModel
                )
                .environmentObject(appContainer.taskQueue)
                .frame(minWidth: 1000, minHeight: 700)
                
                if !hasCompletedInitialSetup {
                    SetupWizardView(
                        viewModel: appContainer.setupViewModel,
                        onFinished: {
                            hasCompletedInitialSetup = true
                        }
                    )
                }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            SettingsView(viewModel: appContainer.settingsViewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}

@MainActor
final class AppContainer: ObservableObject {
    let taskQueue: TaskQueue
    let homeViewModel: HomeViewModel
    let queueViewModel: QueueViewModel
    let settingsViewModel: SettingsViewModel
    let subtitlesViewModel: SubtitlesViewModel
    let setupViewModel: SetupViewModel
    
    init() {
        // Services (existing)
        let audioService = AudioService()
        let transcriptionService = TranscriptionService()
        let segmentationService = SentenceSegmentationService()
        let translationService = TranslationService()
        let subtitleService = SubtitleGeneratorService()
        let ttsService = TTSService()
        let audioAssemblyService = AudioAssemblyService()
        let videoCompositionService = VideoCompositionService()
        let subtitleParsingService = SubtitleParsingService()
        
        // Repository
        let repository = VideoProcessingRepository(
            audioService: audioService,
            transcriptionService: transcriptionService,
            segmentationService: segmentationService,
            translationService: translationService,
            subtitleService: subtitleService,
            ttsService: ttsService,
            audioAssemblyService: audioAssemblyService,
            videoCompositionService: videoCompositionService
        )
        
        // Use Cases
        let addTasksUseCase = AddTasksUseCase()
        let addTasksFromFolderUseCase = AddTasksFromFolderUseCase(addTasksUseCase: addTasksUseCase)
        let processTaskUseCase = ProcessTaskUseCase(repository: repository)
        let processTaskQueueUseCase = ProcessTaskQueueUseCase(processTaskUseCase: processTaskUseCase)
        let cancelTaskUseCase = CancelTaskUseCase()
        let removeTaskUseCase = RemoveTaskUseCase()
        let translateSubtitlesUseCase = TranslateSubtitlesUseCase(
            parser: subtitleParsingService,
            translationService: translationService,
            subtitleService: subtitleService
        )
        
        // TaskQueue
        self.taskQueue = TaskQueue(
            addTasksUseCase: addTasksUseCase,
            addTasksFromFolderUseCase: addTasksFromFolderUseCase,
            processTaskQueueUseCase: processTaskQueueUseCase,
            processTaskUseCase: processTaskUseCase,
            cancelTaskUseCase: cancelTaskUseCase,
            removeTaskUseCase: removeTaskUseCase
        )
        
        // ViewModels
        self.homeViewModel = HomeViewModel(taskQueue: taskQueue)
        self.queueViewModel = QueueViewModel(taskQueue: taskQueue)
        self.settingsViewModel = SettingsViewModel()
        self.subtitlesViewModel = SubtitlesViewModel(useCase: translateSubtitlesUseCase)
        self.setupViewModel = SetupViewModel()
        
        // Setup callback for settings
        settingsViewModel.checkActiveTasksCallback = { [weak taskQueue] in
            taskQueue?.hasActiveTasks ?? false
        }
    }
}

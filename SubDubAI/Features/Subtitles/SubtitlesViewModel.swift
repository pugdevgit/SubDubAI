import Foundation
import Combine

@MainActor
final class SubtitlesViewModel: ObservableObject {
    @Published private(set) var config: ProcessingConfiguration
    @Published var isTranslating: Bool = false
    @Published var statusMessage: String?
    @Published var lastRunSummary: String?
    @Published var fileStatuses: [SubtitleFileStatus] = []
    @Published var overallProgress: Double = 0.0
    
    private let useCase: TranslateSubtitlesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    init(useCase: TranslateSubtitlesUseCaseProtocol) {
        self.useCase = useCase
        self.config = SettingsViewModel.loadDefaultConfig()
        
        // Keep local config in sync when settings change elsewhere
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.config = SettingsViewModel.loadDefaultConfig()
            }
            .store(in: &cancellables)
    }
    
    var languagePairDescription: String {
        "\(config.sourceLanguage.uppercased()) → \(config.targetLanguage.uppercased())"
    }
    
    var pendingCount: Int {
        fileStatuses.filter { $0.state == .pending }.count
    }
    
    var activeCount: Int {
        isTranslating && !fileStatuses.isEmpty ? 1 : 0
    }
    
    var doneCount: Int {
        fileStatuses.filter { $0.state == .success }.count
    }
    
    var failedCount: Int {
        fileStatuses.filter { $0.state == .failed }.count
    }
    
    func translate(files: [URL]) {
        guard !files.isEmpty else {
            statusMessage = "Please select one or more .srt or .vtt files."
            return
        }
        
        isTranslating = true
        statusMessage = "Translating \(files.count) file(s)..."
        lastRunSummary = nil
        overallProgress = 0.0
        fileStatuses = files.enumerated().map { index, url in
            SubtitleFileStatus(
                index: index,
                url: url,
                state: .pending,
                message: "Pending"
            )
        }
        
        let currentConfig = config
        let fileCount = files.count
        
        currentTask?.cancel()
        currentTask = Task {
            do {
                try await useCase.execute(
                    files: files,
                    sourceLanguage: currentConfig.sourceLanguage,
                    targetLanguage: currentConfig.targetLanguage,
                    onFileFinished: { [weak self] index, file, success, error in
                        guard let self else { return }
                        Task { @MainActor in
                            guard index < self.fileStatuses.count else { return }
                            var status = self.fileStatuses[index]
                            if success {
                                status.state = .success
                                status.message = "✅ Done"
                            } else {
                                status.state = .failed
                                status.message = error ?? "Failed"
                            }
                            self.fileStatuses[index] = status
                            let completed = self.fileStatuses.filter { $0.state.isCompleted }.count
                            self.overallProgress = fileCount > 0 ? Double(completed) / Double(fileCount) : 0
                        }
                    }
                )
                
                await MainActor.run {
                    self.isTranslating = false
                    self.currentTask = nil
                    let langSuffix = currentConfig.targetLanguage.replacingOccurrences(of: "-", with: "_")
                    self.statusMessage = "✅ Finished translating \(fileCount) file(s)."
                    self.lastRunSummary = "Translated subtitles were saved next to the originals with suffix _\(langSuffix)."
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isTranslating = false
                    self.statusMessage = "⏹️ Translation cancelled."
                    self.overallProgress = 0.0
                    self.currentTask = nil
                }
            } catch {
                await MainActor.run {
                    self.isTranslating = false
                    self.statusMessage = "❌ Translation failed: \(error.localizedDescription)"
                    self.overallProgress = 0.0
                    self.currentTask = nil
                }
            }
        }
    }
    
    func stop() {
        currentTask?.cancel()
    }
    
    func clear() {
        fileStatuses = []
        overallProgress = 0.0
        statusMessage = nil
        lastRunSummary = nil
    }
}

struct SubtitleFileStatus: Identifiable {
    enum State {
        case pending
        case success
        case failed
        
        var isCompleted: Bool {
            switch self {
            case .pending: return false
            case .success, .failed: return true
            }
        }
    }
    
    let id = UUID()
    let index: Int
    let url: URL
    var state: State
    var message: String
}

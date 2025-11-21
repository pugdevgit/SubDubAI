import Foundation
import SwiftUI
import Combine

enum SetupStep {
    case welcome
    case checking
    case summary
}

@MainActor
final class SetupViewModel: ObservableObject {
    @Published var step: SetupStep = .welcome
    @Published var statuses: [DependencyStatus] = []
    @Published var isChecking: Bool = false
    @Published var whisperProgressMessages: [String] = []

    private let dependencyChecker: DependencyChecker

    init() {
        let config = SettingsViewModel.loadDefaultConfig()
        self.dependencyChecker = DependencyChecker(whisperModel: config.whisperModel)
    }

    var allDependenciesSatisfied: Bool {
        !statuses.isEmpty && statuses.allSatisfy { $0.isSatisfied }
    }

    func startChecks() {
        if isChecking {
            return
        }
        step = .checking
        isChecking = true
        whisperProgressMessages = []
        Task { [weak self] in
            guard let self = self else { return }
            let results = await self.dependencyChecker.checkAll { [weak self] message in
                guard let self = self else { return }
                Task { @MainActor in
                    self.whisperProgressMessages.append(message)
                }
            }
            await MainActor.run {
                self.statuses = results
                self.isChecking = false
                self.step = .summary
            }
        }
    }

    func retry() {
        startChecks()
    }
}

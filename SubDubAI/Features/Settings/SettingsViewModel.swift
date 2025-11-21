//
//  SettingsViewModel.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
    static let taskQueueDidChange = Notification.Name("taskQueueDidChange")
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultConfig: ProcessingConfiguration
    @Published var maxConcurrentTasks: Int
    @Published var autoStartProcessing: Bool
    @Published var cleanupTempFiles: Bool
    @Published var showNotifications: Bool
    
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    // Prevent autosave loops when applying settings from notifications
    private var isApplyingExternalSettings = false
    // Debounced save scheduling
    private var saveWorkItem: DispatchWorkItem?
    
    // Callback to check for active tasks
    var checkActiveTasksCallback: (() -> Bool)?
    
    // Track if we need to save when tasks complete
    @Published private var pendingSave = false
    
    /// Settings are enabled only when no tasks are processing
    var settingsEnabled: Bool {
        !(checkActiveTasksCallback?() ?? false)
    }
    
    /// Check if there are pending changes waiting to be saved
    var hasPendingChanges: Bool {
        pendingSave
    }
    
    init() {
        // Load from UserDefaults
        let loadedConfig = Self.loadDefaultConfig()
        let loadedMaxConcurrent = defaults.integer(forKey: "maxConcurrentTasks")
        
        self.defaultConfig = loadedConfig
        self.maxConcurrentTasks = loadedMaxConcurrent == 0 ? 3 : loadedMaxConcurrent
        self.autoStartProcessing = defaults.bool(forKey: "autoStartProcessing")
        self.cleanupTempFiles = defaults.bool(forKey: "cleanupTempFiles")
        self.showNotifications = defaults.bool(forKey: "showNotifications")
        
        // Listen for settings changes from other sources (e.g. HomeViewModel)
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .sink { [weak self] notification in
                guard let self = self else { return }
                // Ignore notifications posted by our own save()
                if let sender = notification.object as AnyObject?, sender === self { return }
                Task { @MainActor in
                    self.reloadSettings()
                }
            }
            .store(in: &cancellables)
        
        // Listen for task queue changes to update settingsEnabled
        NotificationCenter.default.publisher(for: .taskQueueDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                    
                    // Check if we need to save pending changes
                    if let self = self, self.pendingSave && self.settingsEnabled {
                        print("🔄 Tasks completed - saving pending settings changes")
                        self.save()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Auto-save when settings change
        $defaultConfig
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, !self.isApplyingExternalSettings else { return }
                self.saveSoon()
            }
            .store(in: &cancellables)

        $maxConcurrentTasks
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                guard let self = self, !self.isApplyingExternalSettings else { return }
                self.saveSoon()
            }
            .store(in: &cancellables)
        
        $autoStartProcessing
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, !self.isApplyingExternalSettings else { return }
                self.saveSoon()
            }
            .store(in: &cancellables)
        
        $cleanupTempFiles
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, !self.isApplyingExternalSettings else { return }
                self.saveSoon()
            }
            .store(in: &cancellables)
        
        $showNotifications
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, !self.isApplyingExternalSettings else { return }
                self.saveSoon()
            }
            .store(in: &cancellables)
    }
    
    private func reloadSettings() {
        let loadedConfig = Self.loadDefaultConfig()
        let loadedMaxConcurrent = defaults.integer(forKey: "maxConcurrentTasks")
        
        // Suppress autosave while applying external values
        isApplyingExternalSettings = true
        self.defaultConfig = loadedConfig
        self.maxConcurrentTasks = loadedMaxConcurrent == 0 ? 3 : loadedMaxConcurrent
        self.autoStartProcessing = defaults.bool(forKey: "autoStartProcessing")
        self.cleanupTempFiles = defaults.bool(forKey: "cleanupTempFiles")
        self.showNotifications = defaults.bool(forKey: "showNotifications")
        isApplyingExternalSettings = false
    }
    
    // MARK: - Save/Load
    
    /// Schedule a debounced save to coalesce rapid changes
    func saveSoon(delay: TimeInterval = 0.35) {
        // If tasks are active, respect deferral logic but still mark pending
        if !settingsEnabled {
            pendingSave = true
            return
        }
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.save()
            }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func save() {
        // Don't save when settings are disabled (tasks are active)
        guard settingsEnabled else {
            print("⚠️ Settings save skipped - tasks are currently processing")
            print("💡 Settings will be saved automatically when all tasks complete")
            pendingSave = true
            return
        }
        
        print("💾 Saving settings...")
        Self.saveDefaultConfig(defaultConfig)
        defaults.set(maxConcurrentTasks, forKey: "maxConcurrentTasks")
        defaults.set(autoStartProcessing, forKey: "autoStartProcessing")
        defaults.set(cleanupTempFiles, forKey: "cleanupTempFiles")
        defaults.set(showNotifications, forKey: "showNotifications")
        
        // Clear pending save flag
        pendingSave = false
        
        // Notify other view models that settings changed (identify sender to avoid self-loop)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
        print("✅ Settings saved successfully")
    }
    
    func resetToDefaults() {
        defaultConfig = .default
        maxConcurrentTasks = 3
        autoStartProcessing = false
        cleanupTempFiles = true
        showNotifications = true
        save()
    }
    
    // MARK: - Configuration Updates
    
    func updateMode(_ mode: ProcessingMode) {
        defaultConfig.mode = mode
        save()
    }
    
    func updateSourceLanguage(_ language: String) {
        defaultConfig.sourceLanguage = language
        save()
    }
    
    func updateTargetLanguage(_ language: String) {
        defaultConfig.targetLanguage = language
        save()
    }
    
    func updateWhisperModel(_ model: String) {
        defaultConfig.whisperModel = model
        save()
    }
    
    func updateTTSVoice(_ voice: String) {
        defaultConfig.ttsVoice = voice
        save()
    }
    
    func updateMaxConcurrent(_ count: Int) {
        maxConcurrentTasks = max(1, min(10, count))
        save()
    }
    
    func toggleAutoStart() {
        autoStartProcessing.toggle()
        save()
    }
    
    func toggleCleanup() {
        cleanupTempFiles.toggle()
        defaultConfig.cleanupTempFiles = cleanupTempFiles
        save()
    }
    
    func toggleNotifications() {
        showNotifications.toggle()
        save()
    }
    
    // MARK: - Static Helpers
    
    static func loadDefaultConfig() -> ProcessingConfiguration {
        guard let data = UserDefaults.standard.data(forKey: "defaultConfig"),
              let config = try? JSONDecoder().decode(ProcessingConfiguration.self, from: data) else {
            return .default
        }
        return config
    }
    
    static func saveDefaultConfig(_ config: ProcessingConfiguration) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "defaultConfig")
        }
    }
}

// MARK: - Available Options

extension SettingsViewModel {
    var availableLanguages: [(code: String, name: String)] {
        [
            ("en", "English"),
            ("ru", "Russian"),
            ("es", "Spanish"),
            ("fr", "French"),
            ("de", "German"),
            ("it", "Italian"),
            ("pt", "Portuguese"),
            ("ja", "Japanese"),
            ("ko", "Korean"),
            ("zh", "Chinese")
        ]
    }
    
    var availableWhisperModels: [String] {
        ["tiny", "base", "small", "medium", "large"]
    }
    
    var availableTTSVoices: [(id: String, name: String)] {
        [
            ("ru-RU-DmitryNeural", "Dmitry (Russian Male)"),
            ("ru-RU-SvetlanaNeural", "Svetlana (Russian Female)"),
            ("en-US-GuyNeural", "Guy (US English Male)"),
            ("en-US-JennyNeural", "Jenny (US English Female)"),
            ("en-GB-RyanNeural", "Ryan (UK English Male)"),
            ("en-GB-SoniaNeural", "Sonia (UK English Female)")
        ]
    }
    
    var processingModes: [ProcessingMode] {
        [.subtitlesOnly, .subtitlesWithTranslation, .dubbedVideoOnly, .fullPipeline]
    }
}

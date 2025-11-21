//
//  SettingsView.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.settingsEnabled {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings are locked")
                            .font(.headline)
                        Text("Changing settings is unavailable during processing. Stop tasks or wait until they finish.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.yellow.opacity(0.15))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.yellow.opacity(0.3)), alignment: .bottom
                )
            }
            
            TabView {
                GeneralSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                
                ProcessingSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Processing", systemImage: "waveform")
                    }
                
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
        }
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // Info message when settings are disabled
            if !viewModel.settingsEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Settings are disabled while tasks are processing")
                                .foregroundColor(.secondary)
                        }
                        
                        if viewModel.hasPendingChanges {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text("Changes will be saved automatically when tasks complete")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            Section("Processing") {
                // Segmented presets: 1,2,3,4 + Custom
                let selection = Binding<Int>(
                    get: {
                        (1...4).contains(viewModel.maxConcurrentTasks) ? viewModel.maxConcurrentTasks : 0
                    },
                    set: { newValue in
                        if newValue == 0 {
                            // Switch to Custom; if current is preset, bump to sensible default 5
                            if (1...4).contains(viewModel.maxConcurrentTasks) {
                                viewModel.updateMaxConcurrent(5)
                            }
                        } else {
                            viewModel.updateMaxConcurrent(newValue)
                        }
                    }
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Max concurrent tasks", selection: selection) {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                        Text("Custom").tag(0)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!viewModel.settingsEnabled)
                    
                    if !(1...4).contains(viewModel.maxConcurrentTasks) {
                        HStack {
                            Text("Custom value")
                            Spacer()
                            HStack(spacing: 8) {
                                Text("\(viewModel.maxConcurrentTasks)")
                                    .font(.body)
                                    .monospacedDigit()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                Stepper("", value: Binding(
                                    get: { viewModel.maxConcurrentTasks },
                                    set: { viewModel.updateMaxConcurrent($0) }
                                ), in: 1...10)
                                .labelsHidden()
                                .controlSize(.small)
                            }
                        }
                        .disabled(!viewModel.settingsEnabled)
                    }
                    
                    Text("Limit of simultaneous tasks (1–10)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Auto-start processing", isOn: Binding(
                    get: { viewModel.autoStartProcessing },
                    set: { _ in viewModel.toggleAutoStart() }
                ))
                .disabled(!viewModel.settingsEnabled)
                
                Toggle("Cleanup temporary files", isOn: Binding(
                    get: { viewModel.cleanupTempFiles },
                    set: { _ in viewModel.toggleCleanup() }
                ))
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section("Notifications") {
                Toggle("Show notifications", isOn: Binding(
                    get: { viewModel.showNotifications },
                    set: { _ in viewModel.toggleNotifications() }
                ))
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section {
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)
                .disabled(!viewModel.settingsEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ProcessingSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Mode") {
                Picker("Processing Mode", selection: $viewModel.defaultConfig.mode) {
                    ForEach(viewModel.processingModes, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section("Subtitles") {
                Picker("Subtitle Format", selection: $viewModel.defaultConfig.subtitleFormat) {
                    ForEach(SubtitleFormat.allCases, id: \.self) { fmt in
                        Text(fmt.displayName).tag(fmt)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section("Languages") {
                Picker("Source Language", selection: $viewModel.defaultConfig.sourceLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
                
                Picker("Target Language", selection: $viewModel.defaultConfig.targetLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section("Models") {
                Picker("Whisper Model", selection: $viewModel.defaultConfig.whisperModel) {
                    ForEach(viewModel.availableWhisperModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
                
                Picker("TTS Voice", selection: $viewModel.defaultConfig.ttsVoice) {
                    ForEach(viewModel.availableTTSVoices, id: \.id) { voice in
                        Text(voice.name).tag(voice.id)
                    }
                }
                .disabled(!viewModel.settingsEnabled)
            }
            
            Section("TTS Options") {
                Toggle("⚡ Speed Synchronization", isOn: $viewModel.defaultConfig.enableSpeedSync)
                    .help("Adjust TTS speed to match original segment duration")
                    .disabled(!viewModel.settingsEnabled)
                
                Text("When enabled, TTS audio will be adjusted to match the original timing. When disabled, TTS will use natural speech rate.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Subtitle Segmentation") {
                Toggle("🎯 Fixed Segment Duration", isOn: $viewModel.defaultConfig.useFixedSegmentDuration)
                    .help("Use fixed duration for subtitle segments instead of dynamic segmentation")
                    .disabled(!viewModel.settingsEnabled)
                    .onChange(of: viewModel.defaultConfig.useFixedSegmentDuration) { _, newValue in
                        // Reset to default when disabled
                        if !newValue {
                            viewModel.defaultConfig.fixedSegmentDuration = 7.0
                        }
                    }
                
                if viewModel.defaultConfig.useFixedSegmentDuration {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Segment Duration:")
                            Spacer()
                            Text("\(String(format: "%.1f", viewModel.defaultConfig.fixedSegmentDuration))s")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $viewModel.defaultConfig.fixedSegmentDuration, in: 3.0...15.0, step: 0.5)
                            .help("Duration of each subtitle segment (3-15 seconds)")
                            .disabled(!viewModel.settingsEnabled)
                    }
                    
                    Text("Fixed mode: segments will be exactly \(String(format: "%.1f", viewModel.defaultConfig.fixedSegmentDuration))s long.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Dynamic mode: segments adapt to speech patterns, punctuation, and pauses (typically 3-7s).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("SubDubLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .shadow(radius: 4)
            
            Text("SubDubAI")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 2.0")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("AI-powered video dubbing and subtitle generation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Technologies:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("WhisperKit • Apple Translation • Edge TTS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}

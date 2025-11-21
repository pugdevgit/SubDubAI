//
//  HomeView.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var taskQueue: TaskQueue
    @StateObject private var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Drop Zone
            dropZoneView
            
            Divider()
            
            // Configuration
            configurationView
        }
        .navigationTitle("Add Tasks")
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: viewModel.allowedContentTypes,
            allowsMultipleSelection: viewModel.allowsMultipleSelection
        ) { result in
            if case .success(let urls) = result {
                viewModel.handlePickerSelection(urls)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Video Files")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Drag & drop videos or folders, or use the buttons below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statsView
        }
        .padding()
    }
    
    private var statsView: some View {
        HStack(spacing: 20) {
            StatBadge(
                title: "Pending",
                count: taskQueue.pendingCount,
                color: .blue
            )
            
            StatBadge(
                title: "Processing",
                count: taskQueue.activeCount,
                color: .orange
            )
            
            StatBadge(
                title: "Completed",
                count: taskQueue.completedCount,
                color: .green
            )
        }
    }
    
    private var dropZoneView: some View {
        VStack(spacing: 20) {
            if viewModel.isDragging {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            } else {
                Image("SubDubLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .opacity(0.95)
            }
            
            Text(viewModel.isDragging ? "Drop files here" : "Drag & Drop")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Supported: MP4, MOV, AVI, MKV, M4V")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.selectFiles()
                } label: {
                    Label("Select Files", systemImage: "doc.badge.plus")
                        .frame(width: 140)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    viewModel.selectFolder()
                } label: {
                    Label("Select Folder", systemImage: "folder.badge.plus")
                        .frame(width: 140)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isDragging ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.isDragging ? Color.blue : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                )
        )
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }
    
    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image("SubDubLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text("Current Configuration")
                        .font(.headline)
                }
                
                Spacer()
                
                Text("Edit in Settings (⌘,)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ConfigurationPanel(config: viewModel.config)
                .padding(.vertical, 8)
        }
        .padding()
    }
}

struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ConfigurationPanel: View {
    let config: ProcessingConfiguration
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left column
            VStack(alignment: .leading, spacing: 12) {
                // Mode
                HStack {
                    Text("Mode:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(config.mode.displayName)
                        .fontWeight(.medium)
                }
                
                // Languages
                HStack {
                    Text("Languages:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text("\(config.sourceLanguage.uppercased()) → \(config.targetLanguage.uppercased())")
                        .fontWeight(.medium)
                }
                
                // Subtitle Format
                HStack {
                    Text("Subtitle Format:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(config.subtitleFormat.displayName)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right column
            VStack(alignment: .leading, spacing: 12) {
                // Models
                HStack {
                    Text("Whisper Model:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(config.whisperModel)
                        .fontWeight(.medium)
                }
                
                // TTS Voice
                HStack {
                    Text("TTS Voice:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(config.ttsVoice)
                        .fontWeight(.medium)
                }
                
                // Options
                HStack(alignment: .top) {
                    Text("Options:")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        if config.enableSpeedSync {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Speed Sync")
                                    .font(.caption)
                            }
                        }
                        if config.cleanupTempFiles {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Cleanup Temp Files")
                                    .font(.caption)
                            }
                        }
                        if config.useFixedSegmentDuration {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Fixed Segment: \(String(format: "%.1f", config.fixedSegmentDuration))s")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    let container = AppContainer()
    return HomeView(viewModel: container.homeViewModel)
        .environmentObject(container.taskQueue)
        .frame(width: 800, height: 600)
}

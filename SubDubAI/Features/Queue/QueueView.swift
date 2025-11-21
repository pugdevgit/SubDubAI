//
//  QueueView.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var taskQueue: TaskQueue
    @StateObject private var viewModel: QueueViewModel
    
    init(viewModel: QueueViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            Divider()
            
            if viewModel.isEmpty {
                emptyStateView
            } else {
                // Task List
                taskListView
            }
        }
        .navigationTitle("Processing Queue")
        .confirmationDialog(
            "Clear All Tasks",
            isPresented: $viewModel.showingClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.confirmRemoveAllTasks()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all tasks and cancel any currently processing. This action cannot be undone.")
        }
    }
    
    private var toolbarView: some View {
        HStack {
            // Controls
            HStack(spacing: 8) {
                Button {
                    viewModel.startProcessing()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canStart)
                
                Button {
                    viewModel.stopProcessing()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canStop)
                
                Divider()
                    .frame(height: 20)
                
                Button {
                    viewModel.removeCompletedTasks()
                } label: {
                    Label("Clear Completed", systemImage: "trash")
                }
                .disabled(!viewModel.canClearCompleted)
                
                Button {
                    viewModel.requestClearAll()
                } label: {
                    Label("Clear All", systemImage: "trash.fill")
                }
                .disabled(viewModel.isEmpty)
            }
            
            Spacer()
            
            // Progress
            if viewModel.isProcessing {
                HStack(spacing: 12) {
                    ProgressView(value: viewModel.overallProgress) {
                        Text("Overall Progress")
                            .font(.caption)
                    }
                    .frame(width: 200)
                    
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                StatLabel(title: "Pending", count: viewModel.pendingCount, icon: "circle")
                StatLabel(title: "Active", count: viewModel.activeCount, icon: "arrow.triangle.2.circlepath")
                StatLabel(title: "Done", count: viewModel.completedCount, icon: "checkmark.circle.fill")
                StatLabel(title: "Failed", count: viewModel.failedCount, icon: "xmark.circle.fill")
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("SubDubLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .opacity(0.9)
            
            Text("No Tasks")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add video files from the Home tab to get started")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var taskListView: some View {
        List(selection: $viewModel.selectedTaskId) {
            ForEach(viewModel.filteredTasks) { task in
                TaskRow(task: task)
                    .contextMenu {
                        if task.canCancel {
                            Button("Cancel") {
                                viewModel.cancelTask(id: task.id)
                            }
                        }
                        
                        Button("Remove") {
                            viewModel.removeTask(id: task.id)
                        }
                        
                        Divider()
                        
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([task.videoURL])
                        }
                    }
            }
        }
    }
}

struct StatLabel: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
}

struct TaskRow: View {
    let task: ProcessingTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            statusIcon
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(task.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let step = task.currentStep as ProcessingStep?, step != .idle {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(step.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let elapsed = task.formattedElapsedTime {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(elapsed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Whisper model info
                    if !task.config.whisperModel.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Whisper: \(task.config.whisperModel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Error message for failed tasks
                if task.status == .failed, let error = task.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Progress
            if task.isProcessing {
                ProgressView(value: task.progress)
                    .frame(width: 100)
                
                Text("\(Int(task.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        case .processing:
            ProgressView()
                .controlSize(.small)
                .frame(width: 16, height: 16)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .cancelled:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    let container = AppContainer()
    return QueueView(viewModel: container.queueViewModel)
        .environmentObject(container.taskQueue)
        .frame(width: 800, height: 600)
}

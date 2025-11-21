//
//  MainView.swift
//  SubDubAI
//
//  Created on November 8, 2025.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var taskQueue: TaskQueue
    @State private var selectedTab: Tab = .home
    @Environment(\.openSettings) private var openSettingsAction
    
    let homeViewModel: HomeViewModel
    let queueViewModel: QueueViewModel
    let subtitlesViewModel: SubtitlesViewModel
    
    enum Tab: Hashable {
        case home
        case queue
        case subtitles
    }
    
    private func openSettings() {
        // Try environment action first (macOS 14+)
        if #available(macOS 14.0, *) {
            openSettingsAction()
        } else {
            // Fallback for older macOS
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Button(action: { selectedTab = .home }) {
                    HStack {
                        Label("Home", systemImage: "house.fill")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == .home ? Color.accentColor.opacity(0.2) : Color.clear)
                
                Button(action: { selectedTab = .queue }) {
                    HStack {
                        Label("Queue", systemImage: "list.bullet")
                        Spacer()
                        if taskQueue.pendingCount > 0 {
                            Text("\(taskQueue.pendingCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == .queue ? Color.accentColor.opacity(0.2) : Color.clear)

                Button(action: { selectedTab = .subtitles }) {
                    HStack {
                        Label("Subtitles", systemImage: "captions.bubble")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == .subtitles ? Color.accentColor.opacity(0.2) : Color.clear)
                
                Divider()
                    .padding(.vertical, 4)
                
                Button(action: openSettings) {
                    HStack {
                        Label("Settings", systemImage: "gear")
                        Spacer()
                        Text("⌘,")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
            }
            .navigationTitle("SubDubAI")
            .frame(minWidth: 200)
        } detail: {
            // Content
            switch selectedTab {
            case .home:
                HomeView(viewModel: homeViewModel)
            case .queue:
                QueueView(viewModel: queueViewModel)
            case .subtitles:
                SubtitlesView(viewModel: subtitlesViewModel)
            }
        }
    }
}

#Preview {
    let container = AppContainer()
    return MainView(
        homeViewModel: container.homeViewModel,
        queueViewModel: container.queueViewModel,
        subtitlesViewModel: container.subtitlesViewModel
    )
    .environmentObject(container.taskQueue)
}

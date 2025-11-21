import SwiftUI
import UniformTypeIdentifiers

struct SubtitlesView: View {
    @ObservedObject var viewModel: SubtitlesViewModel
    
    private enum PickerType {
        case files
        case folder
    }

    @State private var isImporterPresented = false
    @State private var selectedFiles: [URL] = []
    @State private var isDropping = false
    @State private var pickerType: PickerType = .files
    
    var body: some View {
        VStack(spacing: 0) {
            controls
                .padding()
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                header
                languageSummary
                dropZone
                filesSection
                
                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                if let summary = viewModel.lastRunSummary {
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: pickerType == .files ? allowedSubtitleTypes : [.folder],
            allowsMultipleSelection: pickerType == .files,
            onCompletion: handleFileImport
        )
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("SubDubLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Subtitle Translation")
                    .font(.title2.weight(.semibold))
                Text("Translate existing SRT/VTT subtitles without reprocessing video.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }

    private func collectSubtitleFiles(in folder: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var result: [URL] = []
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]), values.isRegularFile == true {
                if ["srt", "vtt", "ass"].contains(fileURL.pathExtension.lowercased()) {
                    result.append(fileURL)
                }
            }
        }
        return result
    }
    
    private var allowedSubtitleTypes: [UTType] {
        ["srt", "vtt", "ass"].compactMap { UTType(filenameExtension: $0) }
    }
    
    private var languageSummary: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                Text("Language pair")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.languagePairDescription)
                    .font(.headline)
                Text("Change source/target languages in Settings.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var filesSection: some View {
        GroupBox("Selected subtitle files") {
            if selectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No files selected.")
                        .foregroundColor(.secondary)
                    Text("Use \"Select files…\" to choose .srt, .vtt or .ass files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else if !viewModel.fileStatuses.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.fileStatuses) { status in
                            HStack(spacing: 8) {
                                statusIcon(for: status)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(status.url.lastPathComponent)
                                    Text(status.message)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120, maxHeight: 220)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(selectedFiles, id: \.self) { url in
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(url.lastPathComponent)
                                    Text(url.deletingLastPathComponent().path)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120, maxHeight: 220)
            }
        }
    }
    
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropping ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDropping ? Color.accentColor.opacity(0.06) : Color.clear)
                )
            
            VStack(spacing: 8) {
                Image("SubDubLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .opacity(isDropping ? 1.0 : 0.9)
                
                Text("Drop subtitle files here")
                    .font(.headline)
                Text("SRT, VTT and ASS files will be added to the list.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button {
                        pickerType = .files
                        isImporterPresented = true
                    } label: {
                        Label("Select files…", systemImage: "doc.badge.plus")
                            .frame(width: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isTranslating)

                    Button {
                        pickerType = .folder
                        isImporterPresented = true
                    } label: {
                        Label("Select folder…", systemImage: "folder")
                            .frame(width: 140)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isTranslating)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropping) { providers in
            handleDrop(providers)
        }
    }
    
    private var controls: some View {
        HStack {
            // Primary action
            Button {
                viewModel.translate(files: selectedFiles)
            } label: {
                Label("Translate", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isTranslating || selectedFiles.isEmpty)
            
            Button {
                viewModel.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.isTranslating)
            
            Divider()
                .frame(height: 20)
            
            Button {
                selectedFiles = []
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(selectedFiles.isEmpty && viewModel.fileStatuses.isEmpty)
            
            Spacer()
            
            // Overall progress
            if viewModel.isTranslating {
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
                statLabel(title: "Pending", count: viewModel.pendingCount, icon: "circle")
                statLabel(title: "Active", count: viewModel.activeCount, icon: "arrow.triangle.2.circlepath")
                statLabel(title: "Done", count: viewModel.doneCount, icon: "checkmark.circle.fill")
                statLabel(title: "Failed", count: viewModel.failedCount, icon: "xmark.circle.fill")
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            switch pickerType {
            case .files:
                applySelectedUrls(urls)
            case .folder:
                if let folder = urls.first {
                    let collected = collectSubtitleFiles(in: folder)
                    applySelectedUrls(collected)
                }
            }
        case .failure(let error):
            viewModel.statusMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    private func filterSupported(_ urls: [URL]) -> [URL] {
        let allowed = Set(["srt", "vtt", "ass"])
        return urls.filter { allowed.contains($0.pathExtension.lowercased()) }
    }
    
    private func applySelectedUrls(_ urls: [URL]) {
        let newFiltered = filterSupported(urls)
        // Merge with existing selection and deduplicate by standardized path
        var merged: [URL] = []
        var seen = Set<String>()
        for url in selectedFiles + newFiltered {
            let key = url.standardizedFileURL.path
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(url)
            }
        }
        selectedFiles = merged
        viewModel.fileStatuses = []
        viewModel.overallProgress = 0.0
        if newFiltered.isEmpty {
            viewModel.statusMessage = "No supported subtitle files (.srt, .vtt, .ass) were selected."
        } else if newFiltered.count < urls.count {
            viewModel.statusMessage = "Some files were ignored because only .srt, .vtt and .ass are supported."
        } else {
            viewModel.statusMessage = "Selected \(selectedFiles.count) file(s)."
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let typeIdentifier = UTType.fileURL.identifier
        var found = false
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                found = true
                provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    DispatchQueue.main.async {
                        applySelectedUrls([url])
                    }
                }
            }
        }
        
        return found
    }
    
    @ViewBuilder
    private func statusIcon(for status: SubtitleFileStatus) -> some View {
        switch status.state {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }

    private func statLabel(title: String, count: Int, icon: String) -> some View {
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

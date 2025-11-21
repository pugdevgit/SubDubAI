import Foundation

enum DependencyKind: String, CaseIterable, Identifiable {
    case ffmpeg
    case whisperModel
    case directories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ffmpeg:
            return "FFmpeg"
        case .whisperModel:
            return "Whisper model"
        case .directories:
            return "Working directories"
        }
    }

    var description: String {
        switch self {
        case .ffmpeg:
            return "Command-line tool for audio and video processing."
        case .whisperModel:
            return "Model files required for transcription."
        case .directories:
            return "Output and work directories used by the app."
        }
    }
}

struct DependencyStatus: Identifiable {
    let id = UUID()
    let kind: DependencyKind
    var isSatisfied: Bool
    var message: String

    init(kind: DependencyKind, isSatisfied: Bool, message: String) {
        self.kind = kind
        self.isSatisfied = isSatisfied
        self.message = message
    }
}

final class DependencyChecker {
    private let shellService: ShellService
    private let transcriptionService: TranscriptionService

    init(shellService: ShellService = ShellService(), whisperModel: String) {
        self.shellService = shellService
        self.transcriptionService = TranscriptionService(modelName: whisperModel)
    }

    func checkFFmpeg() async -> DependencyStatus {
        let available = await shellService.checkFFmpeg()
        if available {
            return DependencyStatus(
                kind: .ffmpeg,
                isSatisfied: true,
                message: "ffmpeg is available in PATH."
            )
        } else {
            return DependencyStatus(
                kind: .ffmpeg,
                isSatisfied: false,
                message: "ffmpeg was not found in PATH. Install it via Homebrew (brew install ffmpeg) or from the official website."
            )
        }
    }

    func checkDirectories() async -> DependencyStatus {
        do {
            try Configuration.createDirectories()
            return DependencyStatus(
                kind: .directories,
                isSatisfied: true,
                message: "Required directories are available."
            )
        } catch {
            return DependencyStatus(
                kind: .directories,
                isSatisfied: false,
                message: "Failed to create required directories: \(error.localizedDescription)"
            )
        }
    }

    func checkWhisperModel(onProgress: @escaping @Sendable (String) -> Void) async -> DependencyStatus {
        let initialized = await transcriptionService.initialize(onProgress: onProgress)
        if initialized {
            return DependencyStatus(
                kind: .whisperModel,
                isSatisfied: true,
                message: "Whisper model initialized successfully."
            )
        } else {
            return DependencyStatus(
                kind: .whisperModel,
                isSatisfied: false,
                message: "Failed to initialize Whisper model."
            )
        }
    }

    func checkAll(onWhisperProgress: @escaping @Sendable (String) -> Void) async -> [DependencyStatus] {
        async let ffmpegStatus = checkFFmpeg()
        async let directoriesStatus = checkDirectories()
        async let whisperStatus = checkWhisperModel(onProgress: onWhisperProgress)
        let (ffmpeg, directories, whisper) = await (ffmpegStatus, directoriesStatus, whisperStatus)
        return [ffmpeg, directories, whisper]
    }
}

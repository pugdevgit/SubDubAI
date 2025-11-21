import Foundation

protocol TranslateSubtitlesUseCaseProtocol: Sendable {
    func execute(
        files: [URL],
        sourceLanguage: String,
        targetLanguage: String,
        onFileFinished: @escaping @Sendable (_ index: Int, _ file: URL, _ success: Bool, _ error: String?) -> Void
    ) async throws
}

/// Use case for translating existing subtitle files (SRT/VTT)
struct TranslateSubtitlesUseCase: TranslateSubtitlesUseCaseProtocol {
    private let parser: SubtitleParsingService
    private let translationService: TranslationService
    private let subtitleService: SubtitleGeneratorService

    init(
        parser: SubtitleParsingService,
        translationService: TranslationService,
        subtitleService: SubtitleGeneratorService
    ) {
        self.parser = parser
        self.translationService = translationService
        self.subtitleService = subtitleService
    }

    func execute(
        files: [URL],
        sourceLanguage: String,
        targetLanguage: String,
        onFileFinished: @escaping @Sendable (_ index: Int, _ file: URL, _ success: Bool, _ error: String?) -> Void
    ) async throws {
        guard !files.isEmpty else { return }

        for (index, file) in files.enumerated() {
            try Task.checkCancellation()

            do {
                let (format, segments) = try parser.parseFile(at: file)
                guard !segments.isEmpty else { continue }

                // Translate segments using existing TranslationService actor
                let bilingualSegments = await translationService.translate(
                    segments: segments,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    onProgress: { message in
                        print("[Subtitles] \(file.lastPathComponent): \(message)")
                    }
                )

                guard !bilingualSegments.isEmpty else { continue }

                // Build output path: movie.srt -> movie_ru.srt
                let outputURL = buildOutputURL(
                    for: file,
                    targetLanguage: targetLanguage,
                    format: format
                )

                let ok = subtitleService.generateSingle(
                    format: format,
                    segments: bilingualSegments,
                    path: outputURL.path,
                    useTranslated: true,
                    onProgress: { message in
                        print("[Subtitles] \(outputURL.lastPathComponent): \(message)")
                    }
                )

                if !ok {
                    print("❌ Failed to generate translated subtitles for \(file.path)")
                }

                onFileFinished(index, file, ok, ok ? nil : "Failed to generate translated subtitles")
            } catch {
                print("❌ Failed to translate subtitles for \(file.path): \(error)")
                onFileFinished(index, file, false, String(describing: error))
                continue
            }
        }
    }

    private func buildOutputURL(
        for input: URL,
        targetLanguage: String,
        format: SubtitleFormat
    ) -> URL {
        let dir = input.deletingLastPathComponent()
        let baseName = input.deletingPathExtension().lastPathComponent
        let ext = format.fileExtension
        let sanitizedLang = targetLanguage.replacingOccurrences(of: "-", with: "_")
        let newName = "\(baseName)_\(sanitizedLang).\(ext)"
        return dir.appendingPathComponent(newName)
    }
}

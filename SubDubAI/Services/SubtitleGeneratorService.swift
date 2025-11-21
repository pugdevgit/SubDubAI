import Foundation

/// Service for generating subtitle files (SRT, VTT, ASS)
class SubtitleGeneratorService {
    
    // MARK: - Public unified API
    
    /// Generate both original and translated subtitle files for the given format
    func generateBoth(
        format: SubtitleFormat,
        segments: [BilingualSegment],
        originalPath: String,
        translatedPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool {
        switch format {
        case .srt:
            return generateSRT(segments: segments, originalPath: originalPath, translatedPath: translatedPath, onProgress: onProgress)
        case .vtt:
            return generateVTT(segments: segments, originalPath: originalPath, translatedPath: translatedPath, onProgress: onProgress)
        case .ass:
            return generateASS(segments: segments, originalPath: originalPath, translatedPath: translatedPath, onProgress: onProgress)
        }
    }
    
    /// Generate a single subtitle file (original or translated) for the given format
    func generateSingle(
        format: SubtitleFormat,
        segments: [BilingualSegment],
        path: String,
        useTranslated: Bool,
        onProgress: @escaping (String) -> Void
    ) -> Bool {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to generate subtitles")
            return false
        }
        let content: String
        switch format {
        case .srt:
            onProgress("📝 Generating SRT file...")
            content = generateSRTContent(segments: segments, useTranslated: useTranslated)
        case .vtt:
            onProgress("📝 Generating VTT file...")
            content = generateVTTContent(segments: segments, useTranslated: useTranslated)
        case .ass:
            onProgress("📝 Generating ASS file...")
            content = generateASSContent(segments: segments, useTranslated: useTranslated)
        }
        let ok = saveToFile(content: content, path: path)
        if ok { onProgress("💾 Subtitles: \(path)") }
        return ok
    }
    
    /// Generate SRT subtitle files from bilingual segments
    /// - Parameters:
    ///   - segments: Bilingual segments
    ///   - originalPath: Path for original language subtitles
    ///   - translatedPath: Path for translated language subtitles
    ///   - onProgress: Progress callback
    /// - Returns: True if both files were generated successfully
    func generateSRT(
        segments: [BilingualSegment],
        originalPath: String,
        translatedPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to generate subtitles")
            return false
        }

        onProgress("📝 Generating SRT files...")
        
        // Generate original subtitles
        let originalSRT = generateSRTContent(
            segments: segments,
            useTranslated: false
        )
        
        // Generate translated subtitles
        let translatedSRT = generateSRTContent(
            segments: segments,
            useTranslated: true
        )
        
        // Save files
        var successCount = 0
        
        // Save original
        if saveToFile(content: originalSRT, path: originalPath) {
            onProgress("💾 Original subtitles: \(originalPath)")
            successCount += 1
        } else {
            onProgress("❌ Failed to save original subtitles")
        }
        
        // Save translated
        if saveToFile(content: translatedSRT, path: translatedPath) {
            onProgress("💾 Translated subtitles: \(translatedPath)")
            successCount += 1
        } else {
            onProgress("❌ Failed to save translated subtitles")
        }
        
        if successCount == 2 {
            onProgress("✅ Both subtitle files generated successfully!")
            return true
        }
        
        return false
    }

    // MARK: - Helpers for other formats (placed after generateSRT to avoid local scope)
    /// Generate VTT content from segments
    private func generateVTTContent(
        segments: [BilingualSegment],
        useTranslated: Bool
    ) -> String {
        var vtt = "WEBVTT\n\n"
        for (_, segment) in segments.enumerated() {
            let text = useTranslated ? segment.translated : segment.original
            vtt += "\(formatVTTTime(segment.startTime)) --> \(formatVTTTime(segment.endTime))\n"
            vtt += "\(text)\n\n"
        }
        return vtt
    }
    
    /// Generate ASS content from segments (basic script with default style)
    private func generateASSContent(
        segments: [BilingualSegment],
        useTranslated: Bool
    ) -> String {
        var ass = "[Script Info]\nScriptType: v4.00+\nPlayResX: 1920\nPlayResY: 1080\n\n"
        ass += "[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
        ass += "Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,0,2,80,80,60,1\n\n"
        ass += "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n"
        for (_, segment) in segments.enumerated() {
            let text = (useTranslated ? segment.translated : segment.original).replacingOccurrences(of: "\n", with: "\\N")
            ass += "Dialogue: 0,\(formatASSTime(segment.startTime)),\(formatASSTime(segment.endTime)),Default,,0,0,0,,\(text)\n"
        }
        return ass
    }
    
    // MARK: - Time formatting helpers
    private func formatVTTTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, secs, millis)
    }
    
    private func formatASSTime(_ seconds: Double) -> String {
        // ASS uses H:MM:SS.cs (centiseconds)
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let centis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d:%02d.%02d", hours, minutes, secs, centis)
    }
    
    /// Generate VTT subtitle files from bilingual segments
    /// - Returns: True if both files were generated successfully
    func generateVTT(
        segments: [BilingualSegment],
        originalPath: String,
        translatedPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to generate subtitles")
            return false
        }
        onProgress("📝 Generating VTT files...")
        let original = generateVTTContent(segments: segments, useTranslated: false)
        let translated = generateVTTContent(segments: segments, useTranslated: true)
        var successCount = 0
        if saveToFile(content: original, path: originalPath) {
            onProgress("💾 Original subtitles: \(originalPath)")
            successCount += 1
        } else { onProgress("❌ Failed to save original subtitles") }
        if saveToFile(content: translated, path: translatedPath) {
            onProgress("💾 Translated subtitles: \(translatedPath)")
            successCount += 1
        } else { onProgress("❌ Failed to save translated subtitles") }
        if successCount == 2 { onProgress("✅ Both subtitle files generated successfully!"); return true }
        return false
    }
    
    /// Generate ASS subtitle files from bilingual segments
    /// - Returns: True if both files were generated successfully
    func generateASS(
        segments: [BilingualSegment],
        originalPath: String,
        translatedPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to generate subtitles")
            return false
        }
        onProgress("📝 Generating ASS files...")
        let original = generateASSContent(segments: segments, useTranslated: false)
        let translated = generateASSContent(segments: segments, useTranslated: true)
        var successCount = 0
        if saveToFile(content: original, path: originalPath) {
            onProgress("💾 Original subtitles: \(originalPath)")
            successCount += 1
        } else { onProgress("❌ Failed to save original subtitles") }
        if saveToFile(content: translated, path: translatedPath) {
            onProgress("💾 Translated subtitles: \(translatedPath)")
            successCount += 1
        } else { onProgress("❌ Failed to save translated subtitles") }
        if successCount == 2 { onProgress("✅ Both subtitle files generated successfully!"); return true }
        return false
    }

    /// Generate SRT content from segments
    private func generateSRTContent(
        segments: [BilingualSegment],
        useTranslated: Bool
    ) -> String {
        var srtContent = ""
        
        for (index, segment) in segments.enumerated() {
            let sequenceNumber = index + 1
            let text = useTranslated ? segment.translated : segment.original
            
            // SRT format:
            // 1
            // 00:00:00,000 --> 00:00:03,500
            // Subtitle text
            //
            srtContent += "\(sequenceNumber)\n"
            srtContent += "\(segment.formattedStartTime) --> \(segment.formattedEndTime)\n"
            srtContent += "\(text)\n"
            srtContent += "\n"
        }
        
        return srtContent
    }
    
    /// Save content to file
    private func saveToFile(content: String, path: String) -> Bool {
        do {
            let url = URL(fileURLWithPath: path)
            
            // Create directory if needed
            let directory = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
            
            // Write file
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
            
        } catch {
            return false
        }
    }
}

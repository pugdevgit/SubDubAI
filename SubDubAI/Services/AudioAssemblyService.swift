import Foundation

/// Service for assembling TTS segments into final dubbed audio
class AudioAssemblyService {
    
    private let shellService = ShellService()
    private let silenceGenerator = SilenceGeneratorService()
    
    /// Assemble TTS segments with proper timing into final audio
    /// - Parameters:
    ///   - ttsSegments: Array of TTS segments with audio paths and timing
    ///   - outputPath: Path for final assembled audio
    ///   - onProgress: Progress callback with message and progress (0.0-1.0)
    /// - Returns: True if successful
    func assembleAudio(
        ttsSegments: [TTSSegment],
        outputPath: String,
        onProgress: @escaping (String, Double) -> Void
    ) async -> Bool {
        guard !ttsSegments.isEmpty else {
            onProgress("⚠️ No TTS segments to assemble", 0.0)
            return false
        }
        
        onProgress("🎵 Assembling \(ttsSegments.count) audio segments...", 0.0)
        
        // Verify all TTS audio files exist
        let fileManager = FileManager.default
        var missingFiles: [String] = []
        for (index, segment) in ttsSegments.enumerated() {
            guard let audioPath = segment.audioPath else {
                onProgress("❌ Segment \(index) has no audio path", 0.0)
                missingFiles.append("segment_\(index)")
                continue
            }
            
            if !fileManager.fileExists(atPath: audioPath) {
                missingFiles.append(audioPath)
            }
        }
        
        if !missingFiles.isEmpty {
            onProgress("❌ Missing TTS audio files: \(missingFiles.count)", 0.0)
            for file in missingFiles.prefix(3) {
                onProgress("   - \(file)", 0.0)
            }
            return false
        }
        
        onProgress("✅ All TTS audio files exist", 0.1)
        
        // Sort segments by start time
        let sortedSegments = ttsSegments.sorted { $0.startTime < $1.startTime }
        
        // Calculate gaps between segments
        let gaps = calculateGaps(segments: sortedSegments)
        onProgress("📊 Detected \(gaps.count) gaps between segments", 0.2)
        
        // Create temp directory next to output file
        let outputURL = URL(fileURLWithPath: outputPath)
        let outputDir = outputURL.deletingLastPathComponent().path
        let tempDir = "\(outputDir)/temp_assembly"
        let concatFilePath = "\(outputDir)/concat_list.txt"
        
        // Create temp directory
        try? FileManager.default.createDirectory(
            atPath: tempDir,
            withIntermediateDirectories: true
        )
        
        // Generate silence files for gaps
        onProgress("🔇 Generating silence files...", 0.3)
        
        let silencePaths = await silenceGenerator.generateSilences(
            gaps: gaps,
            outputDir: tempDir,
            onProgress: onProgress
        )
        
        guard silencePaths.count == gaps.count else {
            onProgress("❌ Failed to generate all silence files", 0.0)
            return false
        }
        
        onProgress("✅ Generated \(silencePaths.count) silence files", 0.7)
        
        // Create concat file for ffmpeg
        if !createConcatFile(
            segments: sortedSegments,
            silences: silencePaths,
            outputPath: concatFilePath,
            onProgress: onProgress
        ) {
            onProgress("❌ Failed to create concat file", 0.0)
            return false
        }
        
        // Concatenate all files using ffmpeg
        onProgress("🔗 Concatenating audio files...", 0.8)
        if !(await concatenateFiles(
            concatFilePath: concatFilePath,
            outputPath: outputPath,
            onProgress: onProgress
        )) {
            onProgress("❌ Failed to concatenate audio files", 0.0)
            return false
        }
        
        // Cleanup temp files
        cleanupTempFiles(tempDir: tempDir, concatFile: concatFilePath)
        
        onProgress("✅ Audio assembly completed!", 1.0)
        return true
    }
    
    /// Calculate gap durations between segments
    private func calculateGaps(segments: [TTSSegment]) -> [Double] {
        let minGapDuration = 0.05 // Minimum 50ms for FFmpeg
        var gaps: [Double] = []
        
        // Initial silence (before first segment)
        if let firstSegment = segments.first {
            if firstSegment.startTime > minGapDuration {
                gaps.append(firstSegment.startTime)
            }
        }
        
        // Gaps between segments
        for i in 0..<(segments.count - 1) {
            let currentEnd = segments[i].endTime
            let nextStart = segments[i + 1].startTime
            let gap = nextStart - currentEnd
            
            // Only add gap if it's meaningful (>50ms)
            if gap >= minGapDuration {
                gaps.append(gap)
            }
            // Skip gaps that are too small for FFmpeg
        }
        
        return gaps
    }
    
    /// Create ffmpeg concat file
    private func createConcatFile(
        segments: [TTSSegment],
        silences: [String],
        outputPath: String,
        onProgress: @escaping (String, Double) -> Void
    ) -> Bool {
        var concatContent = ""
        var silenceIndex = 0
        
        // Add initial silence if present
        if silenceIndex < silences.count {
            concatContent += "file '\(silences[silenceIndex])'\n"
            silenceIndex += 1
        }
        
        // Interleave segments and silences
        for (index, segment) in segments.enumerated() {
            guard let audioPath = segment.audioPath else {
                onProgress("⚠️ Segment \(segment.index) has no audio path", 0.0)
                continue
            }
            
            // Add segment audio
            concatContent += "file '\(audioPath)'\n"
            
            // Add silence after segment (if not last segment)
            if index < segments.count - 1 && silenceIndex < silences.count {
                concatContent += "file '\(silences[silenceIndex])'\n"
                silenceIndex += 1
            }
        }
        
        // Write to file
        do {
            try concatContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            onProgress("❌ Failed to write concat file: \(error.localizedDescription)", 0.0)
            return false
        }
    }
    
    /// Concatenate files using ffmpeg
    private func concatenateFiles(
        concatFilePath: String,
        outputPath: String,
        onProgress: @escaping (String, Double) -> Void
    ) async -> Bool {
        let command = """
        ffmpeg -f concat -safe 0 -i "\(concatFilePath)" -c:a libmp3lame -b:a 192k "\(outputPath)" -y
        """
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            if FileManager.default.fileExists(atPath: outputPath) {
                // Get file size
                if let attributes = try? FileManager.default.attributesOfItem(atPath: outputPath),
                   let fileSize = attributes[.size] as? Int64 {
                    let sizeMB = Double(fileSize) / 1_048_576.0
                    onProgress("📦 Output size: \(String(format: "%.2f", sizeMB)) MB", 0.95)
                }
                return true
            } else {
                onProgress("⚠️ ffmpeg succeeded but output file not found", 0.0)
                return false
            }
        } else {
            onProgress("❌ ffmpeg error: \(result.error ?? "Unknown error")", 0.0)
            return false
        }
    }
    
    /// Cleanup temporary files
    private func cleanupTempFiles(tempDir: String, concatFile: String) {
        let fileManager = FileManager.default
        
        // Remove temp silence directory
        try? fileManager.removeItem(atPath: tempDir)
        
        // Remove concat file
        try? fileManager.removeItem(atPath: concatFile)
    }
}

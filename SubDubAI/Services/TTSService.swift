import Foundation

/// Service for generating Text-to-Speech audio using Edge TTS
actor TTSService {
    
    private let shellService = ShellService()
    private let speedAdjuster = AudioSpeedAdjustmentService()
    
    /// Generate TTS audio for all segments
    /// - Parameters:
    ///   - segments: Bilingual segments with text to synthesize
    ///   - outputDir: Directory to save TTS audio files
    ///   - voice: Edge TTS voice name (e.g., "ru-RU-DmitryNeural")
    ///   - enableSpeedSync: Enable speed synchronization to match original timing
    ///   - onProgress: Progress callback
    /// - Returns: Array of TTS segments with audio paths
    func generateTTS(
        segments: [BilingualSegment],
        outputDir: String,
        voice: String,
        enableSpeedSync: Bool = true,
        onProgress: @escaping @Sendable (String) -> Void
    ) async -> [TTSSegment] {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to generate TTS")
            return []
        }
        
        // Create output directory
        if !createDirectory(at: outputDir) {
            onProgress("❌ Failed to create TTS output directory")
            return []
        }
        
        onProgress("🎙️ Generating TTS for \(segments.count) segments...")
        onProgress("🗣️ Voice: \(voice)")
        
        var ttsSegments: [TTSSegment] = []
        
        for (index, segment) in segments.enumerated() {
            // Check for cancellation before each segment
            do {
                try Task.checkCancellation()
            } catch {
                onProgress("⚠️ TTS generation cancelled")
                return []
            }
            
            let ttsSegment = TTSSegment(
                index: index + 1,
                text: segment.translated,
                startTime: segment.startTime,
                endTime: segment.endTime,
                audioPath: ""
            )
            
            // Show progress
            onProgress("⏳ [\(ttsSegment.index)/\(segments.count)] \"\(segment.translated.prefix(30))...\"")
            
            // Generate audio file (temporary)
            let expectedName = await MainActor.run { ttsSegment.expectedFilename }
            let tempPath = "\(outputDir)/temp_\(expectedName)"
            let finalPath = "\(outputDir)/\(expectedName)"
            
            // Step 1: Generate TTS
            if !(await generateSegmentAudio(
                text: segment.translated,
                voice: voice,
                outputPath: tempPath,
                onProgress: onProgress
            )) {
                onProgress("❌ Failed to generate segment \(ttsSegment.index)")
                return []
            }
            
            // Step 2: Adjust speed to match target duration (if enabled)
            if enableSpeedSync {
                let targetDuration = segment.endTime - segment.startTime
                if await speedAdjuster.adjustSpeed(
                    inputPath: tempPath,
                    outputPath: finalPath,
                    targetDuration: targetDuration,
                    onProgress: onProgress
                ) != nil {
                    // Cleanup temp file
                    try? FileManager.default.removeItem(atPath: tempPath)
                    
                    var updatedSegment = ttsSegment
                    updatedSegment.audioPath = finalPath
                    ttsSegments.append(updatedSegment)
                } else {
                    onProgress("❌ Failed to adjust speed for segment \(ttsSegment.index)")
                    // Cleanup temp file
                    try? FileManager.default.removeItem(atPath: tempPath)
                    return []
                }
            } else {
                // Use TTS audio as-is without speed adjustment
                do {
                    try FileManager.default.moveItem(atPath: tempPath, toPath: finalPath)
                    
                    // Log actual duration
                    if let actualDuration = await speedAdjuster.getAudioDuration(path: finalPath) {
                        onProgress("✓ Natural speech: \(String(format: "%.2f", actualDuration))s (no sync)")
                    }
                    
                    var updatedSegment = ttsSegment
                    updatedSegment.audioPath = finalPath
                    ttsSegments.append(updatedSegment)
                } catch {
                    onProgress("❌ Failed to save segment \(ttsSegment.index)")
                    // Cleanup temp file
                    try? FileManager.default.removeItem(atPath: tempPath)
                    return []
                }
            }
        }
        
        onProgress("✅ TTS generation completed!")
        onProgress("📊 Generated \(ttsSegments.count) audio segments")
        
        return ttsSegments
    }
    
    /// Generate audio for a single segment using Edge TTS
    private func generateSegmentAudio(
        text: String,
        voice: String,
        outputPath: String,
        onProgress: @escaping @Sendable (String) -> Void
    ) async -> Bool {
        // Escape text for shell
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        
        // Build edge-tts command
        let edgeTTSPath = "/Users/oleg/Library/Python/3.9/bin/edge-tts"
        let command = """
        "\(edgeTTSPath)" \
        --voice "\(voice)" \
        --text "\(escapedText)" \
        --write-media "\(outputPath)"
        """
        
        // Execute command
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            // Verify file was created
            if FileManager.default.fileExists(atPath: outputPath) {
                return true
            } else {
                onProgress("⚠️ Edge TTS succeeded but file not found")
                return false
            }
        } else {
            onProgress("❌ Edge TTS error: \(result.output)")
            return false
        }
    }
    
    /// Create directory if it doesn't exist
    private func createDirectory(at path: String) -> Bool {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path) {
            return true
        }
        
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true
            )
            return true
        } catch {
            return false
        }
    }
    
    /// List available Edge TTS voices for a language
    func listVoices(language: String, onProgress: @escaping @Sendable (String) -> Void) async -> [String] {
        onProgress("🔍 Fetching available voices for \(language.uppercased())...")
        
        let edgeTTSPath = "/Users/oleg/Library/Python/3.9/bin/edge-tts"
        let command = "\"\(edgeTTSPath)\" --list-voices"
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            // Parse voices (filter by language)
            let voices = result.output
                .components(separatedBy: "\n")
                .filter { $0.contains("Name: \(language)") }
                .compactMap { line -> String? in
                    if let nameRange = line.range(of: "Name: ") {
                        let voiceName = line[nameRange.upperBound...].trimmingCharacters(in: CharacterSet.whitespaces)
                        return String(voiceName.prefix(while: { !$0.isWhitespace }))
                    }
                    return nil
                }
            
            onProgress("✅ Found \(voices.count) voices")
            return voices
        } else {
            onProgress("❌ Failed to list voices")
            return []
        }
    }
}

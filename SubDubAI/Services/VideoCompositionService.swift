import Foundation

/// Service for composing final video with dubbed audio and subtitles
class VideoCompositionService {
    
    private let shellService = ShellService()
    
    /// Compose final video with dubbed audio and embedded subtitles
    /// - Parameters:
    ///   - inputVideo: Path to original video file
    ///   - dubbedAudio: Path to dubbed audio file
    ///   - subtitlePath: Path to subtitle file (optional, for embedding)
    ///   - outputVideo: Path for final output video
    ///   - onProgress: Progress callback
    /// - Returns: True if successful
    func composeVideo(
        inputVideo: String,
        dubbedAudio: String,
        subtitlePath: String?,
        outputVideo: String,
        onProgress: @escaping (String) -> Void
    ) async -> Bool {
        // Verify input files exist
        guard FileManager.default.fileExists(atPath: inputVideo) else {
            onProgress("❌ Input video not found: \(inputVideo)")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: dubbedAudio) else {
            onProgress("❌ Dubbed audio not found: \(dubbedAudio)")
            return false
        }
        
        onProgress("🎬 Starting video composition...")
        
        // Build ffmpeg command
        var command = """
        ffmpeg -i "\(inputVideo)" -i "\(dubbedAudio)"
        """
        
        // Add subtitle input if provided
        if let subtitlePath = subtitlePath,
           FileManager.default.fileExists(atPath: subtitlePath) {
            command += " -i \"\(subtitlePath)\""
            onProgress("📝 Including subtitles: \(subtitlePath)")
        }
        
        // Map video from input, audio from dubbed track
        command += """
         -map 0:v:0 -map 1:a:0
        """
        
        // Add subtitle track if provided
        if subtitlePath != nil {
            command += " -map 2:s:0"
        }
        
        // Video codec: copy (no re-encoding for speed)
        command += " -c:v copy"
        
        // Audio codec: AAC with good quality
        command += " -c:a aac -b:a 192k"
        
        // Subtitle codec: mov_text for MP4
        if subtitlePath != nil {
            command += " -c:s mov_text"
        }
        
        // Set metadata
        command += " -metadata:s:a:0 language=rus"
        if subtitlePath != nil {
            command += " -metadata:s:s:0 language=rus"
        }
        
        // Output file (overwrite)
        command += " \"\(outputVideo)\" -y"
        
        onProgress("🔨 Composing video...")
        onProgress("📹 Video: copy (no re-encode)")
        onProgress("🔊 Audio: AAC 192kbps")
        
        // Execute ffmpeg
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            // Verify output file
            if FileManager.default.fileExists(atPath: outputVideo) {
                // Get file size
                if let attributes = try? FileManager.default.attributesOfItem(atPath: outputVideo),
                   let fileSize = attributes[.size] as? Int64 {
                    let sizeMB = Double(fileSize) / 1_048_576.0
                    onProgress("📦 Output size: \(String(format: "%.2f", sizeMB)) MB")
                }
                
                // Get video duration
                if let duration = await getVideoDuration(path: outputVideo) {
                    let minutes = Int(duration) / 60
                    let seconds = Int(duration) % 60
                    onProgress("⏱️ Duration: \(minutes):\(String(format: "%02d", seconds))")
                }
                
                return true
            } else {
                onProgress("⚠️ ffmpeg succeeded but output file not found")
                return false
            }
        } else {
            onProgress("❌ Video composition failed")
            if let error = result.error, !error.isEmpty {
                onProgress("Error: \(error)")
            }
            return false
        }
    }
    
    /// Replace audio in video (simpler version without subtitles)
    /// - Parameters:
    ///   - inputVideo: Path to original video file
    ///   - dubbedAudio: Path to dubbed audio file
    ///   - outputVideo: Path for final output video
    ///   - onProgress: Progress callback
    /// - Returns: True if successful
    func replaceAudio(
        inputVideo: String,
        dubbedAudio: String,
        outputVideo: String,
        onProgress: @escaping (String) -> Void
    ) async -> Bool {
        return await composeVideo(
            inputVideo: inputVideo,
            dubbedAudio: dubbedAudio,
            subtitlePath: nil,
            outputVideo: outputVideo,
            onProgress: onProgress
        )
    }
    
    /// Get video duration using ffprobe
    private func getVideoDuration(path: String) async -> Double? {
        let command = """
        ffprobe -i "\(path)" -show_entries format=duration -v quiet -of csv="p=0"
        """
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            let durationString = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(durationString)
        }
        
        return nil
    }
    
    /// Create video with burned-in subtitles (alternative approach)
    /// This re-encodes video but ensures subtitle visibility
    func composeVideoWithBurnedSubtitles(
        inputVideo: String,
        dubbedAudio: String,
        subtitlePath: String,
        outputVideo: String,
        onProgress: @escaping (String) -> Void
    ) async -> Bool {
        // Verify input files
        guard FileManager.default.fileExists(atPath: inputVideo) else {
            onProgress("❌ Input video not found")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: dubbedAudio) else {
            onProgress("❌ Dubbed audio not found")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: subtitlePath) else {
            onProgress("❌ Subtitle file not found")
            return false
        }
        
        onProgress("🎬 Creating video with burned-in subtitles...")
        onProgress("⚠️ This will re-encode video (slower but subtitles always visible)")
        
        // Escape subtitle path for ffmpeg filter
        let escapedSubPath = subtitlePath
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ":", with: "\\:")
        
        let command = """
        ffmpeg -i "\(inputVideo)" -i "\(dubbedAudio)" \
               -vf "subtitles='\(escapedSubPath)'" \
               -map 0:v:0 -map 1:a:0 \
               -c:v libx264 -preset medium -crf 23 \
               -c:a aac -b:a 192k \
               "\(outputVideo)" -y
        """
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 && FileManager.default.fileExists(atPath: outputVideo) {
            onProgress("✅ Video with burned subtitles created")
            return true
        } else {
            onProgress("❌ Failed to create video with burned subtitles")
            return false
        }
    }
}

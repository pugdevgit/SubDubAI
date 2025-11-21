import Foundation

/// Service for audio extraction and processing
class AudioService {
    private let shellService: ShellService
    
    init(shellService: ShellService = ShellService()) {
        self.shellService = shellService
    }
    
    /// Extract audio from video file
    /// - Parameters:
    ///   - videoPath: Path to input video file
    ///   - outputPath: Path where audio file will be saved
    ///   - onProgress: Callback for progress updates
    /// - Returns: True if extraction was successful
    func extractAudio(
        from videoPath: String,
        to outputPath: String,
        onProgress: @escaping (String) -> Void
    ) async -> Bool {
        onProgress("📥 Extracting audio from video...")
        
        // Check if ffmpeg is available
        guard await shellService.checkFFmpeg() else {
            onProgress("❌ Error: ffmpeg not found. Please install ffmpeg.")
            return false
        }
        
        // Check if input file exists
        guard FileManager.default.fileExists(atPath: videoPath) else {
            onProgress("❌ Error: Input video not found at \(videoPath)")
            return false
        }
        
        // Create output directory if needed
        let outputDir = (outputPath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: outputDir) {
            do {
                try FileManager.default.createDirectory(
                    atPath: outputDir,
                    withIntermediateDirectories: true
                )
            } catch {
                onProgress("❌ Error: Cannot create output directory: \(error)")
                return false
            }
        }
        
        // Build ffmpeg command
        let command = """
            ffmpeg -i "\(videoPath)" \
            -vn -ar 44100 -ac 2 -ab 192k \
            -f mp3 -y "\(outputPath)" 2>&1
            """
        
        onProgress("🔧 Running ffmpeg...")
        
        // Execute command
        let result = await shellService.execute(command)
        
        // Check if output file was created
        guard FileManager.default.fileExists(atPath: outputPath) else {
            onProgress("❌ Error: Audio extraction failed")
            if let error = result.error, !error.isEmpty {
                onProgress("Error details: \(error)")
            }
            return false
        }
        
        // Get file size for verification
        if let attributes = try? FileManager.default.attributesOfItem(atPath: outputPath),
           let fileSize = attributes[.size] as? Int64 {
            let fileSizeMB = Double(fileSize) / 1_000_000.0
            onProgress(String(format: "✅ Audio extracted successfully (%.2f MB)", fileSizeMB))
            onProgress("📁 Output: \(outputPath)")
        } else {
            onProgress("✅ Audio extracted successfully")
            onProgress("📁 Output: \(outputPath)")
        }
        
        return true
    }
    
    /// Get duration of audio/video file in seconds
    func getDuration(of filePath: String) async -> Double? {
        let command = """
            ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "\(filePath)"
            """
        
        let result = await shellService.execute(command)
        guard result.exitCode == 0 else { return nil }
        
        return Double(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

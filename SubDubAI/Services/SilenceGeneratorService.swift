import Foundation

/// Service for generating silent audio files
class SilenceGeneratorService {
    
    private let shellService = ShellService()
    
    /// Generate a silent audio file
    /// - Parameters:
    ///   - duration: Duration in seconds
    ///   - outputPath: Path to save the silent audio file
    ///   - onProgress: Progress callback
    /// - Returns: True if successful
    func generateSilence(
        duration: Double,
        outputPath: String,
        onProgress: @escaping (String) -> Void
    ) async -> Bool {
        guard duration > 0 else {
            onProgress("⚠️ Silence duration must be positive")
            return false
        }
        
        // Use ffmpeg to generate silence
        let command = """
        ffmpeg -f lavfi -i anullsrc=r=48000:cl=stereo -t \(duration) -c:a libmp3lame -b:a 128k "\(outputPath)" -y
        """
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            if FileManager.default.fileExists(atPath: outputPath) {
                return true
            } else {
                onProgress("⚠️ Silence generation succeeded but file not found")
                return false
            }
        } else {
            onProgress("❌ Failed to generate silence: \(result.error ?? "Unknown error")")
            return false
        }
    }
    
    /// Generate multiple silence files for gaps between segments
    /// - Parameters:
    ///   - gaps: Array of gap durations in seconds
    ///   - outputDir: Directory to save silence files
    ///   - onProgress: Progress callback with message and progress (0.0-1.0)
    /// - Returns: Array of paths to silence files
    func generateSilences(
        gaps: [Double],
        outputDir: String,
        onProgress: @escaping (String, Double) -> Void
    ) async -> [String] {
        guard !gaps.isEmpty else {
            return []
        }
        
        // Create output directory
        if !createDirectory(at: outputDir) {
            onProgress("❌ Failed to create silence output directory", 0.0)
            return []
        }
        
        var silencePaths: [String] = []
        
        for (index, duration) in gaps.enumerated() {
            let filename = String(format: "silence_%03d.mp3", index)
            let outputPath = "\(outputDir)/\(filename)"
            
            // Calculate progress (0.3 to 0.7 range for silence generation)
            let progress = 0.3 + (Double(index) / Double(gaps.count)) * 0.4
            onProgress("🔇 Generating silence \(index + 1)/\(gaps.count)...", progress)
            
            if await generateSilence(
                duration: duration,
                outputPath: outputPath,
                onProgress: { message in
                    // Ignore individual silence progress messages to avoid spam
                }
            ) {
                silencePaths.append(outputPath)
            } else {
                onProgress("❌ Failed to generate silence \(index)", 0.0)
                return []
            }
        }
        
        return silencePaths
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
}

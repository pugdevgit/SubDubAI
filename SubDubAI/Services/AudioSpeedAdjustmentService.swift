import Foundation

/// Service for adjusting audio speed to match target duration
class AudioSpeedAdjustmentService {
    
    private let shellService = ShellService()
    
    /// Adjust audio speed to match target duration
    /// - Parameters:
    ///   - inputPath: Path to input audio file
    ///   - outputPath: Path for adjusted audio file
    ///   - targetDuration: Desired duration in seconds
    ///   - onProgress: Progress callback
    /// - Returns: Actual duration after adjustment, or nil if failed
    func adjustSpeed(
        inputPath: String,
        outputPath: String,
        targetDuration: Double,
        onProgress: @escaping (String) -> Void
    ) async -> Double? {
        // Get current duration
        guard let currentDuration = await getAudioDuration(path: inputPath) else {
            onProgress("❌ Failed to detect audio duration")
            return nil
        }
        
        // Calculate speed factor
        let speedFactor = currentDuration / targetDuration
        
        // Check if adjustment is needed
        let tolerance = 0.05 // 5% tolerance
        if abs(speedFactor - 1.0) < tolerance {
            // Duration is close enough, copy file
            onProgress("✓ Duration OK (\(String(format: "%.2f", currentDuration))s), no adjustment needed")
            
            do {
                try FileManager.default.copyItem(atPath: inputPath, toPath: outputPath)
                return currentDuration
            } catch {
                onProgress("❌ Failed to copy file: \(error.localizedDescription)")
                return nil
            }
        }
        
        onProgress("⚡ Adjusting speed: \(String(format: "%.2f", speedFactor))x (\(String(format: "%.2f", currentDuration))s → \(String(format: "%.2f", targetDuration))s)")
        
        // Build atempo filter chain
        let atempoFilter = buildAtempoChain(speed: speedFactor)
        
        // Apply speed adjustment using ffmpeg
        let command = """
        ffmpeg -i "\(inputPath)" \
               -filter:a "\(atempoFilter)" \
               -c:a libmp3lame -b:a 128k \
               "\(outputPath)" -y -loglevel error
        """
        
        let result = await shellService.execute(command)
        
        if result.exitCode == 0 {
            // Verify output duration
            if let finalDuration = await getAudioDuration(path: outputPath) {
                onProgress("✅ Adjusted: \(String(format: "%.2f", finalDuration))s (target: \(String(format: "%.2f", targetDuration))s)")
                return finalDuration
            } else {
                onProgress("⚠️ Adjustment succeeded but cannot verify duration")
                return targetDuration // Assume it worked
            }
        } else {
            onProgress("❌ Speed adjustment failed: \(result.error ?? "Unknown error")")
            return nil
        }
    }
    
    /// Build atempo filter chain for ffmpeg
    /// atempo supports range 0.5 - 2.0, so we need to chain multiple filters for larger changes
    private func buildAtempoChain(speed: Double) -> String {
        // Clamp speed to reasonable range
        let clampedSpeed = min(max(speed, 0.25), 4.0)
        
        if clampedSpeed >= 0.5 && clampedSpeed <= 2.0 {
            // Single atempo filter
            return "atempo=\(clampedSpeed)"
        } else if clampedSpeed > 2.0 {
            // Chain multiple atempo=2.0 filters
            var chain: [String] = []
            var remaining = clampedSpeed
            
            while remaining > 2.0 {
                chain.append("atempo=2.0")
                remaining /= 2.0
            }
            
            // Add final adjustment
            if remaining > 0.5 {
                chain.append("atempo=\(remaining)")
            }
            
            return chain.joined(separator: ",")
        } else {
            // Chain multiple atempo=0.5 filters (slow down)
            var chain: [String] = []
            var remaining = clampedSpeed
            
            while remaining < 0.5 {
                chain.append("atempo=0.5")
                remaining /= 0.5
            }
            
            // Add final adjustment
            if remaining < 2.0 {
                chain.append("atempo=\(remaining)")
            }
            
            return chain.joined(separator: ",")
        }
    }
    
    /// Get audio duration using ffprobe
    func getAudioDuration(path: String) async -> Double? {
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
}

import Foundation
import Translation

/// Service for translating text using Apple Translation framework
actor TranslationService {
    
    /// Translate segments from source to target language
    /// - Parameters:
    ///   - segments: Segments to translate
    ///   - sourceLanguage: Source language code (e.g., "en")
    ///   - targetLanguage: Target language code (e.g., "ru")
    ///   - onProgress: Progress callback
    /// - Returns: Array of bilingual segments
    func translate(
        segments: [Segment],
        sourceLanguage: String,
        targetLanguage: String,
        onProgress: @escaping @Sendable (String) -> Void
    ) async -> [BilingualSegment] {
        guard !segments.isEmpty else {
            onProgress("⚠️ No segments to translate")
            return []
        }
        
        onProgress("🌐 Translating \(segments.count) segments...")
        onProgress("📍 \(sourceLanguage.uppercased()) → \(targetLanguage.uppercased())")
        
        var bilingualSegments: [BilingualSegment] = []
        
        let sourceLocale = Locale.Language(identifier: sourceLanguage)
        let targetLocale = Locale.Language(identifier: targetLanguage)
        
        // Check if language pair is available
        onProgress("🔍 Checking language availability...")
        let availability = LanguageAvailability()
        let status = await availability.status(from: sourceLocale, to: targetLocale)
        
        switch status {
        case .installed:
            onProgress("✅ Language pair is installed and ready")
        case .supported:
            onProgress("⚠️ Language pair is supported but not installed")
            onProgress("💡 System will prompt you to download on first translation")
            onProgress("⏳ Download may take 1-5 minutes (one-time only)")
            onProgress("📥 Starting translation (system dialog may appear)...")
        case .unsupported:
            onProgress("❌ Language pair \(sourceLanguage)→\(targetLanguage) is not supported")
            onProgress("💡 Available pairs: en↔ru, en↔es, en↔fr, en↔de, en↔it, etc.")
            return []
        @unknown default:
            onProgress("⚠️ Unknown language availability status")
            onProgress("🔄 Attempting translation anyway...")
        }
        
        do {
            let session = TranslationSession(
                installedSource: sourceLocale,
                target: targetLocale
            )
            
            for (index, segment) in segments.enumerated() {
                // Check for cancellation before each segment
                try Task.checkCancellation()
                
                // Show progress
                if index % 10 == 0 {
                    onProgress("⏳ Translating segment \(index + 1)/\(segments.count)...")
                }
                
                // Translate the segment text
                let response = try await session.translate(segment.text)
                
                // Create bilingual segment
                let bilingualSegment = BilingualSegment(
                    original: segment.text,
                    translated: response.targetText,
                    startTime: segment.startTime,
                    endTime: segment.endTime
                )
                
                bilingualSegments.append(bilingualSegment)
            }
            
            onProgress("✅ Translation complete!")
            
        } catch {
            onProgress("❌ Translation failed: \(error.localizedDescription)")
        }
        
        return bilingualSegments
    }
}

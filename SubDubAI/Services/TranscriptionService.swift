import Foundation
@preconcurrency import WhisperKit

/// Service for audio transcription using WhisperKit
actor TranscriptionService {
    private var whisperKit: WhisperKit?
    private let modelName: String
    
    init(modelName: String = "base") {
        self.modelName = modelName
    }
    
    /// Initialize WhisperKit with the specified model
    /// - Parameter onProgress: Callback for progress updates
    /// - Returns: True if initialization was successful
    func initialize(onProgress: @escaping @Sendable (String) -> Void) async -> Bool {
        onProgress("🔧 Initializing WhisperKit...")
        onProgress("📦 Model: \(modelName)")
        
        do {
            onProgress("⏳ Downloading model (this may take 5-10 minutes)...")
            
            // Initialize WhisperKit - it will download model if needed
            whisperKit = try await WhisperKit(
                model: modelName,
                verbose: true,
                logLevel: .debug
            )
            
            onProgress("✅ WhisperKit initialized successfully")
            return true
            
        } catch {
            onProgress("❌ Failed to initialize WhisperKit")
            onProgress("Error: \(error)")
            if let nsError = error as NSError? {
                onProgress("Domain: \(nsError.domain)")
                onProgress("Code: \(nsError.code)")
                onProgress("UserInfo: \(nsError.userInfo)")
            }
            return false
        }
    }
    
    /// Transcribe audio file
    /// - Parameters:
    ///   - audioPath: Path to audio file
    ///   - language: Language code (e.g., "en", "ru"). nil for auto-detection
    ///   - onProgress: Callback for progress updates
    /// - Returns: TranscriptionResult or nil if failed
    func transcribe(
        audioPath: String,
        language: String? = nil,
        onProgress: @escaping @Sendable (String) -> Void
    ) async -> TranscriptionResult? {
        
        guard let whisperKit = whisperKit else {
            onProgress("❌ WhisperKit not initialized. Call initialize() first.")
            return nil
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: audioPath) else {
            onProgress("❌ Audio file not found: \(audioPath)")
            return nil
        }
        
        onProgress("🎤 Starting transcription...")
        onProgress("📁 File: \(audioPath)")
        if let lang = language {
            onProgress("🌍 Language: \(lang)")
        } else {
            onProgress("🌍 Language: Auto-detect")
        }
        
        do {
            // Prepare transcription options
            let options = DecodingOptions(
                verbose: true,
                task: .transcribe,
                language: language,
                temperature: 0.0,
                sampleLength: 224,
                usePrefillPrompt: true,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: false,
                wordTimestamps: true
            )
            
            onProgress("⏳ Transcribing... This may take a few minutes.")
            
            // Transcribe
            let transcriptionResults = try await whisperKit.transcribe(
                audioPath: audioPath,
                decodeOptions: options
            )
            
            guard let transcriptionResult = transcriptionResults.first else {
                onProgress("❌ No transcription result returned")
                return nil
            }
            
            // Extract full text
            let fullText = transcriptionResult.text
            
            // Extract words with timestamps
            var allWords: [Word] = []
            
            for segment in transcriptionResult.segments {
                if let words = segment.words {
                    for word in words {
                        allWords.append(Word(
                            text: word.word,
                            start: Double(word.start),
                            end: Double(word.end)
                        ))
                    }
                }
            }
            
            onProgress("✅ Transcription complete!")
            onProgress("📊 Total words: \(allWords.count)")
            onProgress("📝 Text length: \(fullText.count) characters")
            
            return TranscriptionResult(
                text: fullText,
                words: allWords,
                language: language ?? transcriptionResult.language,
                duration: nil
            )
            
        } catch {
            onProgress("❌ Transcription failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Save transcription result to JSON file
    @MainActor func saveToJSON(
        result: TranscriptionResult,
        to path: String,
        onProgress: @escaping @Sendable (String) -> Void
    ) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(result)
            
            try jsonData.write(to: URL(fileURLWithPath: path))
            
            onProgress("💾 Transcription saved to: \(path)")
            return true
            
        } catch {
            onProgress("❌ Failed to save JSON: \(error.localizedDescription)")
            return false
        }
    }
}

import Foundation

/// Service for segmenting words into sentences/segments for subtitles
class SentenceSegmentationService {
    
    /// Configuration for segmentation
    private let maxWordsPerSegment: Int
    private let maxDurationPerSegment: Double
    private let minPauseDuration: Double
    private let useFixedDuration: Bool
    private let fixedDuration: Double
    
    init(
        maxWordsPerSegment: Int = 15,
        maxDurationPerSegment: Double = 7.0,
        minPauseDuration: Double = 0.5,
        useFixedDuration: Bool = false,
        fixedDuration: Double = 7.0
    ) {
        self.maxWordsPerSegment = maxWordsPerSegment
        self.maxDurationPerSegment = maxDurationPerSegment
        self.minPauseDuration = minPauseDuration
        self.useFixedDuration = useFixedDuration
        self.fixedDuration = fixedDuration
    }
    
    /// Segment words into subtitle segments
    /// - Parameters:
    ///   - words: Array of words with timestamps
    ///   - useFixedDuration: Override for fixed duration mode (nil = use init value)
    ///   - fixedDuration: Override for fixed duration value (nil = use init value)
    ///   - onProgress: Progress callback
    /// - Returns: Array of segments
    func segment(
        words: [Word],
        useFixedDuration: Bool? = nil,
        fixedDuration: Double? = nil,
        onProgress: @escaping (String) -> Void
    ) -> [Segment] {
        let effectiveUseFixed = useFixedDuration ?? self.useFixedDuration
        let effectiveFixed = fixedDuration ?? self.fixedDuration
        guard !words.isEmpty else {
            onProgress("⚠️ No words to segment")
            return []
        }
        
        onProgress("📝 Segmenting \(words.count) words into sentences...")
        
        var segments: [Segment] = []
        var currentWords: [Word] = []
        
        for (index, word) in words.enumerated() {
            currentWords.append(word)
            
            // Determine if we should break here
            let shouldBreak = shouldBreakSegment(
                currentWords: currentWords,
                currentWord: word,
                nextWord: index + 1 < words.count ? words[index + 1] : nil,
                useFixedDuration: effectiveUseFixed,
                fixedDuration: effectiveFixed
            )
            
            if shouldBreak || index == words.count - 1 {
                // Create segment from accumulated words
                if let segment = createSegment(from: currentWords) {
                    segments.append(segment)
                }
                currentWords.removeAll()
            }
        }
        
        onProgress("✅ Created \(segments.count) segments")
        
        return segments
    }
    
    /// Determine if we should break the segment at this point
    private func shouldBreakSegment(
        currentWords: [Word],
        currentWord: Word,
        nextWord: Word?,
        useFixedDuration: Bool,
        fixedDuration: Double
    ) -> Bool {
        // FIXED DURATION MODE: Only break when duration reached
        if useFixedDuration {
            if let firstWord = currentWords.first {
                let duration = currentWord.end - firstWord.start
                // Break when we reach or exceed the fixed duration
                if duration >= fixedDuration {
                    return true
                }
            }
            return false
        }
        
        // DYNAMIC MODE: Use intelligent segmentation
        // Break if too many words
        if currentWords.count >= maxWordsPerSegment {
            return true
        }
        
        // Break if duration is too long
        if let firstWord = currentWords.first {
            let duration = currentWord.end - firstWord.start
            if duration >= maxDurationPerSegment {
                return true
            }
        }
        
        // Break at sentence-ending punctuation
        if hasSentenceEndingPunctuation(currentWord.text) {
            return true
        }
        
        // Break at long pause
        if let nextWord = nextWord {
            let pause = nextWord.start - currentWord.end
            if pause >= minPauseDuration {
                return true
            }
        }
        
        return false
    }
    
    /// Check if word ends with sentence-ending punctuation
    private func hasSentenceEndingPunctuation(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasSuffix(".") || 
               trimmed.hasSuffix("!") || 
               trimmed.hasSuffix("?")
    }
    
    /// Create a segment from words
    private func createSegment(from words: [Word]) -> Segment? {
        guard !words.isEmpty,
              let firstWord = words.first,
              let lastWord = words.last else {
            return nil
        }
        
        let text = words.map { $0.text }.joined(separator: " ")
        
        return Segment(
            text: text,
            words: words,
            startTime: firstWord.start,
            endTime: lastWord.end
        )
    }
}

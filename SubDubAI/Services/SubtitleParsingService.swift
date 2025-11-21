import Foundation

/// Service for parsing existing subtitle files (SRT, VTT) into Segment models
final class SubtitleParsingService {
    enum ParsingError: LocalizedError {
        case unsupportedFormat(String)
        case invalidFile(String)
        case invalidTimecode(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let ext):
                return "Unsupported subtitle format: .\(ext)"
            case .invalidFile(let path):
                return "Invalid subtitle file: \(path)"
            case .invalidTimecode(let line):
                return "Invalid timecode line: \(line)"
            }
        }
    }

    /// Parse a subtitle file by extension (.srt / .vtt)
    func parseFile(at url: URL) throws -> (format: SubtitleFormat, segments: [Segment]) {
        let ext = url.pathExtension.lowercased()
        guard ["srt", "vtt", "ass"].contains(ext) else {
            throw ParsingError.unsupportedFormat(ext)
        }

        let data = try Data(contentsOf: url)
        guard let rawString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw ParsingError.invalidFile(url.path)
        }

        // Normalise newlines
        let content = rawString.replacingOccurrences(of: "\r\n", with: "\n")

        switch ext {
        case "srt":
            let segments = try parseSRT(content: content)
            return (.srt, segments)
        case "vtt":
            let segments = try parseVTT(content: content)
            return (.vtt, segments)
        case "ass":
            let segments = try parseASS(content: content)
            return (.ass, segments)
        default:
            throw ParsingError.unsupportedFormat(ext)
        }
    }

    // MARK: - SRT

    private func parseSRT(content: String) throws -> [Segment] {
        var segments: [Segment] = []

        // Split by blank lines between blocks
        let blocks = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        for block in blocks {
            let lines = block
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard lines.count >= 2 else { continue }

            var index = 0
            // Optional numeric cue index
            if Int(lines[0]) != nil {
                index = 1
            }

            guard index < lines.count else { continue }

            let timeLine = lines[index]
            let textLines = Array(lines.dropFirst(index + 1))
            guard let (start, end) = try parseSRTTimeRange(timeLine) else { continue }

            let text = textLines.joined(separator: " ")
            let segment = Segment(
                text: text,
                words: [],
                startTime: start,
                endTime: end
            )
            segments.append(segment)
        }

        return segments
    }

    private func parseSRTTimeRange(_ line: String) throws -> (Double, Double)? {
        // Example: 00:00:01,000 --> 00:00:03,500
        let parts = line.components(separatedBy: "-->")
        guard parts.count == 2 else { throw ParsingError.invalidTimecode(line) }
        let startString = parts[0].trimmingCharacters(in: .whitespaces)
        let endString = parts[1].trimmingCharacters(in: .whitespaces)
        guard let start = parseSRTTime(startString), let end = parseSRTTime(endString) else {
            throw ParsingError.invalidTimecode(line)
        }
        return (start, end)
    }

    private func parseSRTTime(_ value: String) -> Double? {
        // 00:00:01,000
        let components = value.components(separatedBy: [":", ","])
        guard components.count == 4,
              let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]),
              let millis = Int(components[3]) else { return nil }

        let total = Double(hours * 3600 + minutes * 60 + seconds) + Double(millis) / 1000.0
        return total
    }

    // MARK: - VTT

    private func parseVTT(content: String) throws -> [Segment] {
        var segments: [Segment] = []

        var lines = content.components(separatedBy: "\n")
        // Skip WEBVTT header if present
        if let first = lines.first, first.uppercased().hasPrefix("WEBVTT") {
            lines.removeFirst()
        }

        let joined = lines.joined(separator: "\n")
        let blocks = joined.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        for block in blocks {
            let rawLines = block
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard rawLines.count >= 2 else { continue }

            var index = 0
            var timeLine = rawLines[index]

            // Some VTT cues have an ID line before the timecode
            if !timeLine.contains("-->") && rawLines.count >= 2 {
                index += 1
                timeLine = rawLines[index]
            }

            guard timeLine.contains("-->") else { continue }

            let textLines = Array(rawLines.dropFirst(index + 1))
            guard let (start, end) = try parseVTTTimeRange(timeLine) else { continue }

            let text = textLines.joined(separator: " ")
            let segment = Segment(
                text: text,
                words: [],
                startTime: start,
                endTime: end
            )
            segments.append(segment)
        }

        return segments
    }

    private func parseVTTTimeRange(_ line: String) throws -> (Double, Double)? {
        // Example: 00:00:01.000 --> 00:00:03.500
        let parts = line.components(separatedBy: "-->")
        guard parts.count == 2 else { throw ParsingError.invalidTimecode(line) }
        let startString = parts[0].trimmingCharacters(in: .whitespaces)
        let endString = parts[1].trimmingCharacters(in: .whitespaces)
        guard let start = parseVTTTime(startString), let end = parseVTTTime(endString) else {
            throw ParsingError.invalidTimecode(line)
        }
        return (start, end)
    }

    private func parseVTTTime(_ value: String) -> Double? {
        // 00:00:01.000
        let mainParts = value.components(separatedBy: ".")
        guard mainParts.count == 2 else { return nil }
        let timePart = mainParts[0]
        let millisPart = mainParts[1]

        let hms = timePart.components(separatedBy: ":")
        guard hms.count == 3,
              let hours = Int(hms[0]),
              let minutes = Int(hms[1]),
              let seconds = Int(hms[2]),
              let millis = Int(millisPart) else { return nil }

        let total = Double(hours * 3600 + minutes * 60 + seconds) + Double(millis) / 1000.0
        return total
    }
    
    // MARK: - ASS
    
    private func parseASS(content: String) throws -> [Segment] {
        var segments: [Segment] = []
        let lines = content.components(separatedBy: "\n")
        var inEvents = false
        var startIndex = 1
        var endIndex = 2
        var textIndex = 9 // default ASS format: Layer, Start, End, ..., Text
        
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            if line.hasPrefix("[Events]") {
                inEvents = true
                continue
            }
            
            if !inEvents {
                continue
            }
            
            if line.hasPrefix("[") {
                // Next section started
                inEvents = false
                continue
            }
            
            if line.lowercased().hasPrefix("format:") {
                let formatPart = line.dropFirst("Format:".count)
                let columns = formatPart
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                for (idx, col) in columns.enumerated() {
                    if col == "start" { startIndex = idx }
                    if col == "end" { endIndex = idx }
                    if col == "text" { textIndex = idx }
                }
                continue
            }
            
            if line.lowercased().hasPrefix("dialogue:") {
                let afterPrefix = line.dropFirst("Dialogue:".count)
                // Split into fields, keeping Text (last column) intact even if it contains commas
                let fields = afterPrefix.split(separator: ",", maxSplits: textIndex, omittingEmptySubsequences: false)
                guard fields.count > max(startIndex, endIndex, textIndex) else { continue }
                
                let startString = fields[startIndex].trimmingCharacters(in: .whitespaces)
                let endString = fields[endIndex].trimmingCharacters(in: .whitespaces)
                guard let start = parseASSTime(startString), let end = parseASSTime(endString) else {
                    continue
                }
                
                let textField = fields[textIndex].trimmingCharacters(in: .whitespaces)
                let cleanedText = cleanASSText(textField)
                
                let segment = Segment(
                    text: cleanedText,
                    words: [],
                    startTime: start,
                    endTime: end
                )
                segments.append(segment)
            }
        }
        
        return segments
    }
    
    private func parseASSTime(_ value: String) -> Double? {
        // ASS uses H:MM:SS.cs (centiseconds)
        let components = value.components(separatedBy: [":", "."])
        guard components.count == 4,
              let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]),
              let centis = Int(components[3]) else { return nil }
        let total = Double(hours * 3600 + minutes * 60 + seconds) + Double(centis) / 100.0
        return total
    }
    
    private func cleanASSText(_ value: String) -> String {
        // Remove override tags in { ... }
        var result = ""
        var skipping = false
        for char in value {
            if char == "{" {
                skipping = true
                continue
            }
            if char == "}" {
                skipping = false
                continue
            }
            if !skipping {
                result.append(char)
            }
        }
        // Convert \N / \n to real line breaks
        let withLineBreaks = result
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")
        return withLineBreaks.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

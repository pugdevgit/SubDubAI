import Foundation

/// Represents a validation issue found during system check
struct ValidationIssue: Identifiable, Sendable {
    let id = UUID()
    let type: IssueType
    let component: Component
    let message: String
    let suggestion: String?
    let actionCommand: String?
    
    enum IssueType: String, Sendable {
        case critical // Blocks functionality
        case warning  // Degrades functionality
        case info     // Informational only
    }
    
    enum Component: String, Sendable {
        case ffmpeg
        case whisperModel
        case diskSpace
        case outputDirectory
        case libreTranslate
        case permissions
    }
    
    var icon: String {
        switch type {
        case .critical:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var color: String {
        switch type {
        case .critical:
            return "red"
        case .warning:
            return "orange"
        case .info:
            return "blue"
        }
    }
}

/// Result of system validation
struct ValidationResult: Sendable {
    let issues: [ValidationIssue]
    let checks: [ValidationCheck]
    let timestamp: Date
    
    var isValid: Bool {
        !hasCriticalIssues
    }
    
    var hasCriticalIssues: Bool {
        issues.contains { $0.type == .critical }
    }
    
    var hasWarnings: Bool {
        issues.contains { $0.type == .warning }
    }
    
    var criticalIssues: [ValidationIssue] {
        issues.filter { $0.type == .critical }
    }
    
    var warnings: [ValidationIssue] {
        issues.filter { $0.type == .warning }
    }
    
    var infos: [ValidationIssue] {
        issues.filter { $0.type == .info }
    }
}

/// Individual validation check result
struct ValidationCheck: Identifiable, Sendable {
    let id = UUID()
    let component: ValidationIssue.Component
    let passed: Bool
    let message: String
    let details: String?
    
    var icon: String {
        passed ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var color: String {
        passed ? "green" : "red"
    }
}

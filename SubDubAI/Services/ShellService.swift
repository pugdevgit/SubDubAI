import Foundation

/// Service for executing shell commands
class ShellService {
    
    /// Execute a shell command asynchronously and return output
    /// Runs on a background thread to avoid blocking UI
    @discardableResult
    func execute(_ command: String) async -> (output: String, error: String?, exitCode: Int32) {
        return await withCheckedContinuation { continuation in
            // Run on background thread to avoid blocking
            Task.detached {
                let task = Process()
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                task.arguments = ["-c", command]
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.standardInput = nil
                
                // Set PATH to include Homebrew paths
                var environment = ProcessInfo.processInfo.environment
                let homebrewPaths = "/opt/homebrew/bin:/usr/local/bin"
                if let existingPath = environment["PATH"] {
                    environment["PATH"] = "\(homebrewPaths):\(existingPath)"
                } else {
                    environment["PATH"] = "\(homebrewPaths):/usr/bin:/bin"
                }
                task.environment = environment
                
                do {
                    try task.run()
                    task.waitUntilExit()  // Blocks background thread, not main thread
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8)
                    
                    continuation.resume(returning: (output, error, task.terminationStatus))
                } catch {
                    continuation.resume(returning: ("", error.localizedDescription, -1))
                }
            }
        }
    }
    
    /// Check if a command-line tool is available
    func isToolAvailable(_ toolName: String) async -> Bool {
        let result = await execute("which \(toolName)")
        return result.exitCode == 0 && !result.output.isEmpty
    }
    
    /// Check if ffmpeg is available
    func checkFFmpeg() async -> Bool {
        return await isToolAvailable("ffmpeg")
    }
}

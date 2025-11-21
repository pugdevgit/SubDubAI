# 🤝 Contributing Guide

Thank you for your interest in SubDubAI! We welcome contributions from the community.

## Getting Started

### 1. Fork the Repository

```bash
# Go to GitHub and click "Fork"
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/SubDubAI.git
cd SubDubAI
```

### 2. Create a Branch for Your Feature

```bash
git checkout -b feature/your-feature-name
# or for bugs
git checkout -b fix/bug-description
```

### 3. Make Changes

Follow our code standards (see below).

### 4. Create a Pull Request

```bash
git push origin feature/your-feature-name
# Then create PR on GitHub
```

## Code Standards

### Swift Style Guide

#### Naming

```swift
// ✅ Correct
class VideoProcessingRepository { }
func processVideo() { }
let maxConcurrentTasks = 3
var isProcessing = false

// ❌ Incorrect
class video_processing_repository { }
func process_video() { }
let max_concurrent_tasks = 3
var processing = false
```

#### Formatting

```swift
// ✅ Correct - Proper indentation and spacing
func processVideo(
    videoURL: URL,
    config: ProcessingConfiguration
) async throws -> ProcessingTask {
    // Implementation
}

// ❌ Incorrect - Poor formatting
func processVideo(videoURL: URL, config: ProcessingConfiguration) async throws -> ProcessingTask {
    // Implementation
}
```

#### Comments

```swift
// ✅ Correct - Clear and concise
/// Processes video and returns processing task
/// - Parameters:
///   - videoURL: URL to video file
///   - config: Processing configuration
/// - Returns: Processing task with results
func processVideo(
    videoURL: URL,
    config: ProcessingConfiguration
) async throws -> ProcessingTask

// ❌ Incorrect - Unclear or missing
func processVideo(videoURL: URL, config: ProcessingConfiguration) async throws -> ProcessingTask
```

#### Error Handling

```swift
// ✅ Correct - Proper error handling
do {
    let result = try await service.process()
    return result
} catch {
    logger.error("Processing failed: \(error)")
    throw ProcessingError.failed
}

// ❌ Incorrect - Ignoring errors
let result = try! await service.process()
```

#### Concurrency

```swift
// ✅ Correct - Proper MainActor usage
@MainActor
final class ViewModel: ObservableObject {
    @Published var state: State = .idle
}

// ✅ Correct - Proper async/await
async func processVideo() throws -> Result {
    return try await repository.process()
}

// ❌ Incorrect - Mixing old and new patterns
func processVideo(completion: @escaping (Result) -> Void) {
    DispatchQueue.main.async {
        completion(result)
    }
}
```

## Commit Messages

### Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Test additions or changes
- **chore**: Build, dependencies, etc.

### Examples

```bash
# ✅ Good
git commit -m "feat: add concurrency limiter for TTS generation"
git commit -m "fix: resolve MainActor isolation warnings"
git commit -m "docs: update README with screenshots"

# ❌ Bad
git commit -m "fix stuff"
git commit -m "WIP"
git commit -m "asdf"
```

## Pull Request Process

### Before Submitting

1. **Update your branch** with latest main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Run tests**:
   ```bash
   xcodebuild test -scheme SubDubAI
   ```

3. **Check code style**:
   ```bash
   # Use Xcode's built-in formatting
   # Editor → Structure → Re-Indent
   ```

4. **Build successfully**:
   ```bash
   xcodebuild build -scheme SubDubAI
   ```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #(issue number)

## Testing
Describe testing performed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings generated
```

## Types of Contributions

### Bug Reports

1. Check if bug already exists
2. Provide clear description
3. Include steps to reproduce
4. Attach logs and screenshots
5. Specify macOS version and hardware

### Feature Requests

1. Check if feature already requested
2. Provide clear description
3. Explain use case
4. Suggest implementation (if possible)

### Documentation

1. Fix typos and errors
2. Improve clarity
3. Add examples
4. Update outdated information

### Code Improvements

1. Refactor for clarity
2. Improve performance
3. Add tests
4. Fix code style issues

## Development Setup

### Prerequisites

```bash
# Install Xcode
xcode-select --install

# Install Homebrew dependencies
brew install ffmpeg
pip3 install edge-tts
```

### Building

```bash
# Build
xcodebuild build -scheme SubDubAI

# Run
xcodebuild run -scheme SubDubAI

# Test
xcodebuild test -scheme SubDubAI
```

### Debugging

```bash
# Enable detailed logging
# In Xcode: Product → Scheme → Edit Scheme
# Run → Arguments Passed On Launch: -com.apple.CoreData.SQLDebug 1
```

## Project Structure

```
SubDubAI/
├── SubDubAI/
│   ├── Core/
│   │   ├── Domain/          # Business logic
│   │   └── Data/            # Data layer
│   ├── Features/            # UI screens
│   ├── Services/            # External services
│   ├── Shared/              # Shared components
│   └── Models/              # Data models
├── SubDubAITests/           # Unit tests
├── SubDubAIUITests/         # UI tests
└── Docs/                    # Documentation
```

## Testing Guidelines

### Unit Tests

```swift
// ✅ Good test
func testProcessVideoWithValidInput() async throws {
    let input = URL(fileURLWithPath: "/test.mp4")
    let result = try await service.process(input)
    XCTAssertNotNil(result)
}

// ❌ Bad test
func testProcess() {
    // No clear purpose
}
```

### Test Coverage

- Aim for 80%+ coverage
- Test happy path and error cases
- Test edge cases
- Mock external dependencies

## Code Review

### What We Look For

- ✅ Code follows style guidelines
- ✅ Tests are included
- ✅ Documentation is updated
- ✅ No new warnings
- ✅ Performance is acceptable
- ✅ Security is considered

### Review Process

1. Automated checks (build, tests)
2. Code review by maintainers
3. Feedback and discussion
4. Approval and merge

## Reporting Security Issues

**Do not** create public issues for security vulnerabilities.

Instead, email security details to: [security@example.com]

## Code of Conduct

### Be Respectful

- Treat all contributors with respect
- Be open to feedback
- Avoid harassment or discrimination

### Be Helpful

- Help other contributors
- Answer questions
- Share knowledge

### Be Professional

- Keep discussions on-topic
- Avoid spam
- Follow project guidelines

## Questions?

- Check existing issues and discussions
- Create new issue with question tag
- Contact maintainers

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- GitHub contributors page
- Release notes

---

**Thank you for contributing to SubDubAI!**

**Last Updated**: November 2025

# 🏗️ SubDubAI Architecture

## Overview

SubDubAI uses **Clean Architecture** with separation into three main layers:

```
┌─────────────────────────────────────────┐
│         Presentation Layer (UI)         │
│  SwiftUI Views + MVVM ViewModels        │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│         Domain Layer (Business Logic)   │
│  UseCases + Entities + Repositories     │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│         Data Layer (Services)           │
│  Services + External APIs               │
└─────────────────────────────────────────┘
```

## Architecture Layers

### 1. Presentation Layer (UI)

**Location**: `Features/` and `Shared/State/`

**Components**:
- **QueueView** - Main interface with task queue
- **QueueViewModel** - Queue state management
- **SettingsView** - Settings screen
- **SettingsViewModel** - Settings management
- **TaskQueue** - Queue and concurrency management

**Patterns**:
- MVVM for logic/UI separation
- @Published for reactive updates
- @MainActor for thread safety

### 2. Domain Layer (Business Logic)

**Location**: `Core/Domain/`

**Components**:

#### Entities (Data Models)
- `ProcessingTask` - Video processing task
- `ProcessingConfiguration` - Processing configuration
- `BilingualSegment` - Segment with original and translated text
- `TTSSegment` - Segment with voiceover
- `TranscriptionResult` - Transcription result

#### Repositories (Interfaces)
- `VideoProcessingRepositoryProtocol` - Video processing interface
- Defines contracts for all processing operations

#### UseCases (Business Logic)
- `ProcessTaskUseCase` - Orchestrates complete video processing cycle
- `ProcessTaskQueueUseCase` - Task queue management
- `AddTasksUseCase` - Task addition
- `CancelTaskUseCase` - Task cancellation

### 3. Data Layer (Services)

**Location**: `Services/` and `Core/Data/`

**Main Services**:

#### AudioService
- Audio extraction from video files
- Uses FFmpeg

#### TranscriptionService
- Speech-to-text conversion
- WhisperKit integration
- Word-level timestamp retrieval

#### TranslationService
- Text translation between languages
- Uses macOS Translation Framework

#### TTSService
- Voiceover generation
- Uses edge-tts CLI
- Concurrency management (max 2 simultaneous)
- Retry with exponential backoff
- 90-second timeout per segment

#### AudioAssemblyService
- Voiceover assembly with pauses
- Uses FFmpeg for concatenation
- Streaming processing with progress

#### ShellService
- System command execution
- Timeout and streaming output support
- Error handling and exit codes

#### SubtitleGeneratorService
- Subtitle generation (SRT, VTT, ASS)
- Time synchronization

#### VideoCompositionService
- Final video composition
- Audio and subtitle embedding

## State Management

### TaskQueue (MainActor)

Central application state management:

```swift
@MainActor
final class TaskQueue: ObservableObject {
    @Published var tasks: [ProcessingTask]
    @Published var isProcessing: Bool
    
    // Concurrency management
    private var activeTaskHandles: [UUID: Task<Void?, Never>]
    private var maxConcurrentTasks: Int
    private var pendingTaskQueue: [ProcessingTask]
}
```

**Responsibilities**:
- Task list storage
- Parallel execution management
- Active task tracking
- Starting next task on completion

### SettingsViewModel

User settings management:
- Source and target languages
- Voiceover voice
- Maximum concurrent tasks (1-4)
- Subtitle format
- Flags (speed sync, file cleanup)

## Concurrency Management

### ConcurrencyLimiter (Actor)

```swift
actor ConcurrencyLimiter {
    private var activeCount = 0
    private let maxConcurrent: Int
    
    func acquire() async
    func release()
}
```

**Usage**:
- Limit simultaneous TTS generations to 2
- Prevent system overload
- Thread-safe access via Actor

### TaskGroup for Parallel Operations

```swift
await withTaskGroup(of: Void.self) { group in
    // Start up to maxConcurrent tasks
    // Start next on completion
}
```

## Error Handling

### Error Hierarchy

```
Error
├── RepositoryError
│   ├── audioExtractionFailed
│   ├── transcriptionFailed
│   ├── translationFailed
│   ├── ttsFailed
│   ├── audioAssemblyFailed
│   └── videoCompositionFailed
├── ProcessingError
│   ├── missingSegments
│   └── missingBilingualSegments
└── ShellError
    ├── commandNotFound
    └── executionFailed
```

### Handling Strategies

1. **Retry with backoff** - For TTS and network operations
2. **Graceful degradation** - Continue on partial errors
3. **Logging** - Detailed information about each stage
4. **Recovery** - Ability to restart tasks

## Execution Flow

### Main Processing Flow

```
1. User adds video
   ↓
2. Task added to queue (status: pending)
   ↓
3. TaskQueue starts task (status: processing)
   ↓
4. ProcessTaskUseCase orchestrates stages:
   - Audio extraction
   - Transcription
   - Translation
   - Subtitle generation
   - Voiceover generation (with concurrency limit)
   - Audio assembly
   - Video composition
   ↓
5. Task completed (status: completed/failed)
   ↓
6. Next task from queue starts
```

### Asynchronous Operations

```
Main Thread (UI Updates)
    ↓
Task { @MainActor in ... }
    ↓
Background Thread (Processing)
    ↓
await service.operation()
    ↓
Callback with progress
    ↓
Task { @MainActor in updateUI() }
```

## Progress Streaming

### Callback Chain

```
ProcessTaskUseCase.onProgress
    ↓
Repository.onProgress
    ↓
Service.onProgress (e.g., AudioAssemblyService)
    ↓
FFmpeg progress parsing
    ↓
Task { @MainActor in updateUI() }
    ↓
QueueViewModel.updateTask()
    ↓
UI updates
```

## Type Safety and Concurrency

### Sendable Protocols

```swift
// All data models marked as Sendable
struct ProcessingTask: Sendable { }
struct BilingualSegment: Sendable { }

// Callbacks marked as @Sendable
onProgress: @escaping @Sendable @MainActor (Double) async -> Void
```

### MainActor Isolation

```swift
@MainActor
final class TaskQueue: ObservableObject {
    // All UI updates happen on MainActor
}

// Explicit dispatch for background thread updates
Task { @MainActor in
    updateUI()
}
```

## Dependencies and DI

### Dependency Injection

```swift
// In AppDelegate or main context
let repository = VideoProcessingRepository(
    audioService: AudioService(),
    transcriptionService: TranscriptionService(),
    translationService: TranslationService(),
    // ...
)

let useCase = ProcessTaskUseCase(repository: repository)

let taskQueue = TaskQueue(
    processTaskUseCase: useCase,
    // ...
)
```

## Performance and Optimization

### Caching

- WhisperKit models cached in `~/Library/Caches/huggingface/`
- Transcription results saved for reuse

### Concurrency

- Maximum 2 simultaneous TTS generations
- Maximum N concurrent tasks (configurable 1-4)
- Asynchronous operations without UI blocking

### Memory Management

- Weak references in closures to prevent retain cycles
- Timely cleanup of temporary files
- Streaming processing of large files

## Testing

### Test Structure

```
SubDubAITests/
├── Services/
│   ├── TTSServiceTests.swift
│   ├── TranscriptionServiceTests.swift
│   └── ...
├── UseCases/
│   ├── ProcessTaskUseCaseTests.swift
│   └── ...
└── ViewModels/
    ├── QueueViewModelTests.swift
    └── ...
```

### Testing Strategy

1. **Unit tests** - Individual services
2. **Integration tests** - UseCase and Repository
3. **UI tests** - ViewModels and Views

## Logging and Debugging

### Logging Levels

```
📋 - State information
🎬 - Operation start
✅ - Successful completion
❌ - Error
⚠️ - Warning
🔄 - Operation retry
⏱️ - Timing information
```

### Debug Information

- Job ID for operation tracking
- Timing information for each stage
- Error details with exit codes and stderr
- Concurrency and queue information

---

**Last Updated**: November 2025

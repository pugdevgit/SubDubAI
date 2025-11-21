# SubDubAI v2.0 - Requirements and Improvements

**Date:** November 8, 2025  
**Version:** 2.0  
**Status:** Planning

---

## 🎯 Main Goal

Redesign the application with support for:
- ✅ Batch processing (multiple files)
- ✅ Proper architecture (MVVM + Clean Architecture)
- ✅ Flexible processing modes
- ✅ Modern macOS UI (NavigationSplitView)
- ✅ Parallel processing (2 files simultaneously)

---

## 📋 Functional Requirements

### 1. Adding Files

**Methods:**
- "Add Video Files" button (single/multiple selection)
- "Add Folder" button (auto-search for videos)
- Drag & Drop onto window

**Formats:** `.mp4`, `.mov`, `.avi`, `.mkv`, `.m4v`

---

### 2. Processing Modes

#### Mode 1: Subtitles Only
- Steps: Extract → Transcribe → Subtitles
- Output: `{name}_{lang}.srt`

#### Mode 2: Subtitles + Translation
- Steps: Extract → Transcribe → Translate → Subtitles
- Output: `{name}_en.srt` + `{name}_ru.srt`

#### Mode 3: Dubbed Video Only
- Steps: Extract → Transcribe → Translate → TTS → Assemble → Video
- Output: `{name}_dubbed.mp4`

#### Mode 4: Full Pipeline (default)
- All steps: Extract → Transcribe → Translate → Subtitles → TTS → Assemble → Video
- Output: `{name}_en.srt` + `{name}_ru.srt` + `{name}_dubbed.mp4`

---

### 3. Settings

**Languages:**
- Source: en / ru / uk
- Target: en / ru / uk

**Models:**
- Whisper: tiny / base / small / medium

**TTS:**
- Voice Name: text field (e.g., `ru-RU-DmitryNeural`)
- Speed Sync: toggle

**Performance:**
- Max Parallel Tasks: 1-4 (default: 2)

**Output:**
- Save Location: next to video (default) or custom directory
- Cleanup: delete temporary files

---

### 4. File Saving

**Default:** next to source video

**Naming format:**
```
Source:      /path/to/video.mp4

Subtitles:   /path/to/video_en.srt
             /path/to/video_ru.srt

Video:       /path/to/video_dubbed.mp4

Temporary:   /path/to/.subdubai/
             ├── video_audio.mp3
             ├── video_transcription.json
             └── tts_segments/
```

**Conflicts:** add suffix `_1`, `_2`, etc.

---

### 5. Task Management

**Task Model:**
```
- id: UUID
- videoURL: URL
- status: pending/processing/completed/failed/cancelled
- currentStep: ProcessingStep
- progress: 0.0-1.0
- config: ProcessingConfiguration
- outputFiles: OutputFiles?
- error: String?
```

**Actions:**
- Start/Pause/Cancel
- Retry (for failed)
- Delete
- Show in Finder

---

### 6. Task Queue

**Logic:**
- User adds N files → N tasks created (pending)
- Queue takes first M tasks (M = maxParallelTasks)
- Processes in parallel via Swift Concurrency
- When one finishes, picks next from queue

**Parallelism:**
- Default: 2 tasks simultaneously
- Configurable: 1-4

---

## 🏗️ Architecture

### Folder Structure

```
SubDubAI/
├── App/
│   ├── SubDubAIApp.swift
│   └── AppDependencies.swift
│
├── Core/
│   ├── Models/
│   │   ├── Domain/
│   │   │   ├── Task.swift
│   │   │   ├── ProcessingConfiguration.swift
│   │   │   └── OutputFiles.swift
│   │   └── Processing/
│   │       └── (existing models)
│   │
│   ├── Domain/
│   │   ├── UseCases/
│   │   │   ├── AddTasksUseCase.swift
│   │   │   ├── ProcessTaskUseCase.swift
│   │   │   └── ProcessTaskQueueUseCase.swift
│   │   └── Repositories/
│   │       └── VideoProcessingRepository.swift
│   │
│   └── Services/
│       └── (existing services)
│
├── Features/
│   ├── Home/
│   ├── Tasks/
│   ├── Settings/
│   └── Logs/
│
└── Shared/
    ├── Views/
    │   ├── MainView.swift
    │   └── SidebarView.swift
    └── Components/
```

### Architectural Layers

```
Presentation Layer (UI)
    ↓ commands
Domain Layer (Business Logic)
    ↓ orchestrates
Infrastructure Layer (Services)
    ↓ creates
Output Files
```

### Dependency Injection

```swift
AppDependencies {
    // Services
    // Repositories
    // Use Cases
    // ViewModels factories
}
```

---

## 🎨 UI Requirements

### MainView Structure

**NavigationSplitView:**
- Sidebar (250px)
- Detail View (dynamic content)

### Sidebar Sections

```
HOME
├─ 🏠 Home

TASKS
├─ 📊 All Tasks (badge: total)
├─ ⏸️ Queue (badge: pending)
├─ ▶️ Processing (badge: active)
├─ ✅ Completed (badge: completed)
└─ ❌ Failed (badge: failed)

OTHER
├─ ⚙️ Settings
└─ 📋 Logs
```

### Home View

- Add files buttons
- Drag & Drop zone
- Quick Settings (mode, languages)
- "Start Processing" button

### Task List View

- Overall progress
- Task list with progress bars
- Status icons
- Current step
- ETA
- Action buttons

### Task Detail View

Sections:
1. Information (file, size, path)
2. Status (progress, step, ETA)
3. Configuration (mode, languages, model)
4. Output Files (created files + Show in Finder)
5. Actions (Pause/Cancel/Delete)

### Settings View

Sections:
1. Processing Mode
2. Languages
3. Models
4. TTS
5. Performance
6. Output

### Logs View

- Level filter
- Search
- Color coding
- Export
- Clear

---

## ⚙️ Technical Details

### Concurrency

**Structure:**
```
MainActor (UI)
└─> ViewModels (@MainActor)
    └─> Use Cases
        └─> TaskGroup
            ├─> Task 1 (Background)
            └─> Task 2 (Background)
```

**Parallelism via TaskGroup:**
```swift
await withTaskGroup(of: Void.self) { group in
    for task in pendingTasks.prefix(maxConcurrent) {
        group.addTask {
            await processTask(task)
        }
    }
}
```

### Error Handling

- Service level: throw errors
- Use Case: catch and convert
- ViewModel: update @Published error
- UI: show alerts/messages

### Logging

- Levels: Debug / Info / Warning / Error
- Components: service names
- Persistence: optional file logging
- UI: real-time updates

---

## 📝 Implementation Plan

### Phase 1: Domain Models
- Task model
- ProcessingConfiguration
- ProcessingMode enum
- TaskStatus enum

### Phase 2: Use Cases
- AddTasksUseCase
- ProcessTaskUseCase
- ProcessTaskQueueUseCase

### Phase 3: Repository
- VideoProcessingRepository
- Integration with existing Services

### Phase 4: ViewModels
- TaskQueueViewModel
- TaskListViewModel
- TaskDetailViewModel
- SettingsViewModel

### Phase 5: UI
- MainView + Sidebar
- Home View
- Task List View
- Task Detail View
- Settings View

### Phase 6: Integration
- DI container
- Testing
- Polish

---

## ✅ Success Criteria

**Functionality:**
- ✅ Adding single/multiple files works
- ✅ All 4 processing modes work correctly
- ✅ Parallel processing of 2 files
- ✅ Files saved next to source
- ✅ Settings applied to tasks

**Architecture:**
- ✅ Clean separation of layers
- ✅ UI independent from Services
- ✅ Testable Use Cases
- ✅ DI without singletons

**UX:**
- ✅ Real-time progress display
- ✅ Can cancel/restart tasks
- ✅ Informative logs
- ✅ Intuitive navigation

---

## 📚 References

**Existing Documents:**
- `promt3.md` - current implementation
- `prompt_ui.md` - UI reference (Speech2Subs)

**Apple Guidelines:**
- Human Interface Guidelines (macOS)
- Swift Concurrency Best Practices
- NavigationSplitView patterns

---

**Ready for implementation!**

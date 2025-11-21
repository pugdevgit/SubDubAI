# SubDubAI - Video Translation Pipeline (macOS SwiftUI)

## 🎯 Overview

**SubDubAI** - полнофункциональное macOS приложение для автоматического перевода видео с дублированием голоса и субтитрами.

**Технологии:**
- SwiftUI (macOS GUI)
- WhisperKit (локальная транскрипция)
- Apple Translation Framework (локальный перевод)
- Edge TTS (генерация речи)
- ffmpeg (обработка медиа)

**Язык:** English → Russian (настраиваемо)

---

## 📋 Pipeline Steps

### Полный цикл обработки:

```
1. Extract Audio     → Извлечение аудио из видео
2. Transcribe        → Транскрипция с word-level timestamps
3. Subtitles         → Генерация EN/RU субтитров
4. Generate TTS      → TTS для переведенного текста
5. Assemble Audio    → Сборка финального аудио
6. Final Video       → Композиция видео с дубляжом
```

---

## 🏗️ Architecture

### Project Structure

```
SubDubAI/
├── SubDubAI/
│   ├── Models/
│   │   ├── TranscriptionResult.swift      # WhisperKit результаты
│   │   ├── Segment.swift                  # Текстовый сегмент с таймингом
│   │   ├── BilingualSegment.swift         # EN/RU сегмент
│   │   └── TTSSegment.swift               # TTS аудио сегмент
│   ├── Services/
│   │   ├── ShellService.swift             # Shell команды
│   │   ├── AudioService.swift             # Извлечение аудио
│   │   ├── TranscriptionService.swift     # WhisperKit интеграция
│   │   ├── SentenceSegmentationService.swift  # Разбивка на предложения
│   │   ├── TranslationService.swift       # Apple Translation
│   │   ├── SubtitleGeneratorService.swift # SRT генерация
│   │   ├── TTSService.swift               # Edge TTS
│   │   ├── AudioSpeedAdjustmentService.swift  # Синхронизация скорости
│   │   ├── SilenceGeneratorService.swift  # Генерация пауз
│   │   ├── AudioAssemblyService.swift     # Сборка аудио
│   │   └── VideoCompositionService.swift  # Финальное видео
│   ├── Configuration.swift                # Централизованная конфигурация
│   ├── ContentView.swift                  # UI + оркестрация
│   └── SubDubAIApp.swift                  # App entry point
├── Input/
│   └── test_video.mp4                     # Входное видео
└── Output/
    ├── audio.mp3                          # Извлеченное аудио
    ├── transcription.json                 # Транскрипция
    ├── english_subtitles.srt              # Английские субтитры
    ├── russian_subtitles.srt              # Русские субтитры
    ├── tts_segments/                      # TTS файлы
    │   ├── segment_001.mp3
    │   └── ...
    ├── dubbed_audio.mp3                   # Собранный дубляж
    └── final_video.mp4                    # 🎬 Финальное видео
```

---

## 📦 Models

### TranscriptionResult
```swift
struct TranscriptionResult: Codable {
    let text: String           // Полный текст
    let words: [WordTiming]    // Слова с таймингами
}

struct WordTiming: Codable {
    let word: String
    let start: Double          // Секунды
    let end: Double
}
```

### Segment
```swift
struct Segment {
    let index: Int
    let text: String
    let startTime: Double
    let endTime: Double
    var duration: Double { endTime - startTime }
}
```

### BilingualSegment
```swift
struct BilingualSegment {
    let index: Int
    let original: String       // EN текст
    let translated: String     // RU текст
    let startTime: Double
    let endTime: Double
    
    func toSRTFormat() -> String
    func toSRTTimeFormat(_ seconds: Double) -> String
}
```

### TTSSegment
```swift
struct TTSSegment: Codable {
    let index: Int
    let text: String           // RU текст для TTS
    let startTime: Double
    let endTime: Double
    var audioPath: String?     // Путь к MP3 файлу
    var expectedFilename: String { "segment_\(index).mp3" }
}
```

---

## 🔧 Services

### 1. ShellService
**Назначение:** Выполнение shell команд

```swift
class ShellService {
    func execute(_ command: String) -> (output: String, error: String?, exitCode: Int32)
    func isToolAvailable(_ toolName: String) -> Bool
    func checkFFmpeg() -> Bool
}
```

**Особенности:**
- Настройка PATH для Homebrew (`/opt/homebrew/bin`)
- Поддержка ffmpeg, edge-tts, ffprobe

---

### 2. AudioService
**Назначение:** Извлечение аудио из видео

```swift
class AudioService {
    func extractAudio(
        from videoPath: String,
        outputPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool
}
```

**ffmpeg команда:**
```bash
ffmpeg -i video.mp4 \
  -vn -ar 44100 -ac 2 -b:a 192k \
  -f mp3 output.mp3
```

---

### 3. TranscriptionService
**Назначение:** Транскрипция через WhisperKit SDK

```swift
class TranscriptionService {
    func initialize(onProgress: @escaping (String) -> Void) async -> Bool
    func transcribe(
        audioPath: String,
        onProgress: @escaping (String) -> Void
    ) async -> TranscriptionResult?
}
```

**Особенности:**
- Модель: `base` (настраиваемо в Configuration)
- Word-level timestamps
- Асинхронная инициализация с прогрессом
- Сохранение в JSON

---

### 4. SentenceSegmentationService
**Назначение:** Разбивка слов на предложения

```swift
class SentenceSegmentationService {
    func segment(
        words: [WordTiming],
        onProgress: @escaping (String) -> Void
    ) -> [Segment]
}
```

**Алгоритм:**
- Пунктуация (`.`, `!`, `?`)
- Паузы > 0.5 сек
- Макс. 15 слов
- Макс. 10 сек

---

### 5. TranslationService
**Назначение:** Перевод через Apple Translation Framework

```swift
class TranslationService {
    func translate(
        segments: [Segment],
        sourceLanguage: String,
        targetLanguage: String,
        onProgress: @escaping (String) -> Void
    ) async -> [BilingualSegment]
}
```

**Особенности:**
- Локальный перевод (без интернета)
- Автоматическая загрузка моделей (диалог системы)
- Проверка доступности языковой пары
- Batch обработка

---

### 6. SubtitleGeneratorService
**Назначение:** Генерация SRT файлов

```swift
class SubtitleGeneratorService {
    func generate(
        segments: [BilingualSegment],
        originalPath: String,
        translatedPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool
}
```

**Формат SRT:**
```
1
00:00:00,000 --> 00:00:02,500
Hello world

2
00:00:02,500 --> 00:00:05,000
This is a test
```

---

### 7. TTSService
**Назначение:** Генерация TTS через Edge TTS

```swift
class TTSService {
    func generateTTS(
        segments: [BilingualSegment],
        outputDir: String,
        voice: String,
        onProgress: @escaping (String) -> Void
    ) -> [TTSSegment]
}
```

**Edge TTS команда:**
```bash
edge-tts \
  --voice "ru-RU-DmitryNeural" \
  --text "Привет мир" \
  --write-media segment_001.mp3
```

**Процесс:**
1. Генерация temp файла
2. Проверка длительности (ffprobe)
3. **Speed adjustment** (если включено)
4. Сохранение финального файла

---

### 8. AudioSpeedAdjustmentService ⭐
**Назначение:** Синхронизация длительности TTS с оригиналом

```swift
class AudioSpeedAdjustmentService {
    func adjustSpeed(
        inputPath: String,
        outputPath: String,
        targetDuration: Double,
        onProgress: @escaping (String) -> Void
    ) -> Double?
    
    func getAudioDuration(path: String) -> Double?
}
```

**atempo фильтр:**
```bash
ffmpeg -i input.mp3 \
  -filter:a "atempo=1.5" \
  output.mp3
```

**Цепочка для > 2.0x:**
```bash
-filter:a "atempo=2.0,atempo=1.25"
```

**Особенности:**
- Диапазон: 0.25x - 4.0x
- Толерантность: 5%
- Автоматические цепочки фильтров

---

### 9. SilenceGeneratorService
**Назначение:** Генерация пауз между сегментами

```swift
class SilenceGeneratorService {
    func generateSilence(
        duration: Double,
        outputPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool
}
```

**ffmpeg команда:**
```bash
ffmpeg -f lavfi \
  -i anullsrc=r=48000:cl=stereo \
  -t 2.5 silence.mp3
```

---

### 10. AudioAssemblyService
**Назначение:** Сборка финального аудио

```swift
class AudioAssemblyService {
    func assembleAudio(
        ttsSegments: [TTSSegment],
        outputPath: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool
}
```

**Процесс:**
1. Сортировка сегментов по времени
2. Вычисление пауз между сегментами
3. Генерация silence файлов
4. Создание concat файла для ffmpeg
5. Склейка всех файлов

**Concat файл:**
```
file 'segment_001.mp3'
file 'silence_001.mp3'
file 'segment_002.mp3'
file 'silence_002.mp3'
...
```

**ffmpeg concat:**
```bash
ffmpeg -f concat -safe 0 \
  -i concat_list.txt \
  -c:a libmp3lame -b:a 192k \
  dubbed_audio.mp3
```

---

### 11. VideoCompositionService
**Назначение:** Финальная композиция видео

```swift
class VideoCompositionService {
    func composeVideo(
        inputVideo: String,
        dubbedAudio: String,
        subtitlePath: String?,
        outputVideo: String,
        onProgress: @escaping (String) -> Void
    ) -> Bool
}
```

**ffmpeg команда (с субтитрами):**
```bash
ffmpeg \
  -i input_video.mp4 \
  -i dubbed_audio.mp3 \
  -i russian_subtitles.srt \
  -map 0:v:0 -map 1:a:0 -map 2:s:0 \
  -c:v copy \
  -c:a aac -b:a 192k \
  -c:s mov_text \
  -metadata:s:a:0 language=rus \
  -metadata:s:s:0 language=rus \
  final_video.mp4
```

**Альтернатива - burned subtitles:**
```bash
ffmpeg -i input.mp4 -i audio.mp3 \
  -vf "subtitles='subs.srt'" \
  -map 0:v:0 -map 1:a:0 \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 192k \
  output.mp4
```

---

## ⚙️ Configuration

### Configuration.swift

```swift
struct Configuration {
    // Paths
    static let inputVideo = "\(baseDirectory)/Input/test_video.mp4"
    static let outputAudio = "\(outputDir)/audio.mp3"
    static let outputTranscription = "\(outputDir)/transcription.json"
    static let outputEnglishSubtitles = "\(outputDir)/english_subtitles.srt"
    static let outputRussianSubtitles = "\(outputDir)/russian_subtitles.srt"
    static let outputTTSSegments = "\(outputDir)/tts_segments"
    static let outputDubbedAudio = "\(outputDir)/dubbed_audio.mp3"
    static let outputFinalVideo = "\(outputDir)/final_video.mp4"
    
    // Models
    static let whisperModel = "base"  // tiny, base, small, medium, large-v3
    
    // Languages
    static let sourceLanguage = "en"
    static let targetLanguage = "ru"
    
    // TTS
    static let ttsVoice = "ru-RU-DmitryNeural"  // или SvetlanaNeural
    static let ttsRate = "+0%"
    
    // Speed Sync ⚡
    static var enableSpeedSync = true  // Toggle в UI
}
```

---

## 🎨 User Interface

### ContentView.swift

**Структура:**
```swift
struct ContentView: View {
    @State private var logMessages: [String] = []
    @State private var isProcessing = false
    @State private var isWhisperKitInitialized = false
    @State private var transcriptionResult: TranscriptionResult?
    @State private var bilingualSegments: [BilingualSegment] = []
    @State private var ttsSegments: [TTSSegment] = []
    @State private var isDubbedAudioReady = false
    
    // Services
    private let audioService = AudioService()
    private let transcriptionService = TranscriptionService()
    private let segmentationService = SentenceSegmentationService()
    private let translationService = TranslationService()
    private let subtitleService = SubtitleGeneratorService()
    private let ttsService = TTSService()
    private let audioAssemblyService = AudioAssemblyService()
    private let videoCompositionService = VideoCompositionService()
}
```

**UI элементы:**

1. **Configuration Info**
   - Input video path
   - Output path
   - Video exists check

2. **TTS Settings Panel**
   - Toggle: Speed Synchronization (ON/OFF)
   - Status indicator

3. **Pipeline Buttons** (2 ряда по 3 кнопки):
   ```
   [1. Extract Audio]  [2. Transcribe]    [3. Subtitles]
   [4. Generate TTS]   [5. Assemble Audio] [6. Final Video]
   ```

4. **Log Area**
   - ScrollView с сообщениями
   - Автоскролл к последнему

**Button States:**
- Disabled во время processing
- Enabled только когда предыдущие шаги завершены
- Цветовая кодировка (blue, green, orange, purple, cyan, pink)

---

## 🔄 Pipeline Flow

### Step-by-Step Execution

```swift
// Step 1: Extract Audio
func extractAudio() {
    isProcessing = true
    DispatchQueue.global().async {
        let success = audioService.extractAudio(...)
        DispatchQueue.main.async {
            isProcessing = false
            // Update UI
        }
    }
}

// Step 2: Transcribe (Async/Await)
func transcribeAudio() {
    Task {
        isProcessing = true
        
        if !isWhisperKitInitialized {
            let initialized = await transcriptionService.initialize(...)
            isWhisperKitInitialized = initialized
        }
        
        if let result = await transcriptionService.transcribe(...) {
            transcriptionResult = result  // Cache in memory
            // Also save to JSON
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
}

// Step 3: Generate Subtitles
func generateSubtitles() {
    Task {
        // 1. Load transcription (memory or file)
        // 2. Segment into sentences
        // 3. Translate segments
        // 4. Generate SRT files
        // 5. Save bilingual segments for next step
    }
}

// Step 4: Generate TTS
func generateTTS() {
    DispatchQueue.global().async {
        let segments = ttsService.generateTTS(...)
        DispatchQueue.main.async {
            ttsSegments = segments
        }
    }
}

// Step 5: Assemble Audio
func assembleAudio() {
    DispatchQueue.global().async {
        let success = audioAssemblyService.assembleAudio(...)
        DispatchQueue.main.async {
            isDubbedAudioReady = success
        }
    }
}

// Step 6: Compose Final Video
func composeFinalVideo() {
    DispatchQueue.global().async {
        let success = videoCompositionService.composeVideo(...)
        // Show completion message
    }
}
```

---

## 🚀 Dependencies

### System Tools
```bash
# ffmpeg (медиа обработка)
brew install ffmpeg

# Edge TTS (генерация речи)
pip3 install edge-tts
```

### Swift Packages
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.2")
]
```

### Apple Frameworks
- SwiftUI (UI)
- Translation (перевод)
- AVFoundation (опционально)

---

## 📊 Performance

### Timing (для 10-минутного видео):

| Step | Duration | Notes |
|------|----------|-------|
| 1. Extract Audio | 5-10 сек | Зависит от размера |
| 2. Transcribe | 2-5 мин | base модель, GPU |
| 3. Subtitles | 10-30 сек | Первый раз: загрузка модели |
| 4. Generate TTS | 1-3 мин | ~2-4 сек/сегмент + sync |
| 5. Assemble Audio | 5-15 сек | ffmpeg concat |
| 6. Final Video | 10-30 сек | copy video (fast) |
| **TOTAL** | **4-10 мин** | |

### Optimization Tips:
- Использовать `tiny` модель WhisperKit (быстрее, хуже качество)
- Отключить Speed Sync для более быстрого TTS
- Параллельная обработка (будущее улучшение)

---

## 🎯 Features

### ✅ Implemented

1. **Audio Extraction** - ffmpeg
2. **Transcription** - WhisperKit SDK с word timestamps
3. **Sentence Segmentation** - умная разбивка
4. **Translation** - Apple Translation (локально)
5. **Subtitle Generation** - SRT (EN + RU)
6. **TTS Generation** - Edge TTS
7. **Speed Synchronization** - atempo автоподгонка
8. **Audio Assembly** - concat с паузами
9. **Video Composition** - замена аудио + субтитры
10. **UI Progress** - детальные логи
11. **Toggle Controls** - Speed Sync ON/OFF
12. **File Persistence** - JSON кэширование
13. **Memory Caching** - для быстрого доступа

### 🔮 Future Enhancements

1. **Multiple Languages** - выбор языка в UI
2. **Voice Selection** - список доступных голосов
3. **Quality Settings** - WhisperKit model selector
4. **Batch Processing** - несколько видео
5. **Preview** - просмотр результата в приложении
6. **Error Recovery** - retry механизм
7. **Custom Timing** - ручная корректировка
8. **Burned Subtitles** - опция в UI

---

## 🐛 Known Issues & Solutions

### Issue: WhisperKit initialization slow
**Solution:** Используется `base` модель (быстрее чем large-v3)

### Issue: Translation model download
**Solution:** Система автоматически показывает диалог загрузки

### Issue: TTS длиннее оригинала
**Solution:** Speed Sync с atempo (включено по умолчанию)

### Issue: ffmpeg not found
**Solution:** PATH настроен в ShellService для Homebrew

---

## 📝 Usage Example

### Complete Workflow:

```
1. Поместить test_video.mp4 в Input/
2. Запустить приложение (⌘R)
3. Нажать "1. Extract Audio" 
4. Нажать "2. Transcribe" (первый раз долго - загрузка модели)
5. Нажать "3. Subtitles" (первый раз долго - загрузка перевода)
6. Нажать "4. Generate TTS" (Speed Sync: ON)
7. Нажать "5. Assemble Audio"
8. Нажать "6. Final Video"
9. Проверить Output/final_video.mp4
```

### Expected Output:
```
Output/
├── audio.mp3 (4.2 MB)
├── transcription.json (154 words)
├── english_subtitles.srt (15 segments)
├── russian_subtitles.srt (15 segments)
├── tts_segments/ (34 files)
├── dubbed_audio.mp3 (3.9 MB)
└── final_video.mp4 (45 MB) 🎬
```

---

## 🎓 Success Criteria

✅ **Functional:**
- Все 6 шагов работают без ошибок
- Финальное видео воспроизводится
- Субтитры читаемы
- Аудио синхронизировано

✅ **Quality:**
- Транскрипция точная (>90%)
- Перевод естественный
- TTS произношение четкое
- Синхронизация ±0.5 сек

✅ **Performance:**
- 10-мин видео < 10 мин обработки
- UI отзывчивый
- Детальный прогресс

---

## 📚 Technical Notes

### Threading Model:
- **Main Thread:** UI updates, @MainActor
- **Background Queue:** Heavy processing (audio, video)
- **Task/Async:** WhisperKit, Translation (structured concurrency)

### Data Flow:
```
Video → Audio → Words → Sentences → Bilingual → TTS → Assembly → Video
         ↓       ↓        ↓           ↓           ↓       ↓
       File    Memory   Memory      Memory      Files   File
```

### Error Handling:
- Service level: возврат Bool или Optional
- UI level: логирование в console
- User feedback: детальные сообщения в Log

---

## 🔗 Resources

- **WhisperKit:** https://github.com/argmaxinc/WhisperKit
- **Edge TTS:** https://github.com/rany2/edge-tts
- **ffmpeg:** https://ffmpeg.org
- **Apple Translation:** https://developer.apple.com/documentation/translation

---

## 📄 Summary

**SubDubAI** - это полнофункциональное macOS приложение для автоматического перевода видео с дублированием.

**Ключевые особенности:**
- 🎯 Полный пайплайп (6 шагов)
- 🖥️ SwiftUI интерфейс
- 🔒 Локальная обработка (privacy-first)
- ⚡ Speed synchronization
- 📝 Двуязычные субтитры
- 🎙️ Качественный TTS
- 🎬 Готовое видео

**Статус:** Полностью реализовано и готово к использованию!

---

**Document:** Technical specification and implementation guide  
**Version:** 1.0 (Current Implementation)  
**Platform:** macOS 14.0+  
**Language:** Swift 5.0 + SwiftUI  
**Last Updated:** November 2024

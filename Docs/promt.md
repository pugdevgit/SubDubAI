# Video Translation Pipeline - macOS Swift Implementation Spec

## 🎯 Application Overview

Local video translation and dubbing application for macOS using only FREE and LOCAL components.
No API keys required. All processing happens on-device using Apple Silicon optimization.

---

## 📦 Core Technologies (FREE & LOCAL)

### 1. Speech Recognition
- **WhisperKit** - Apple Silicon optimized Whisper
- Model: `openai_whisper-large-v2`
- Uses: Apple Neural Engine
- Location: `./models/whisperkit/`

### 2. Translation
- **Marian NMT** - Neural Machine Translation
- Location: `./models/marian/`
- Supports multiple language pairs
- Python-based execution

### 3. Text-to-Speech
- **Edge TTS** - Microsoft free TTS
- Command: `edge-tts`
- Multiple voice options
- Network required for generation

### 4. Media Processing
- **FFmpeg** - Audio/video manipulation
- **yt-dlp** - Video downloading

---

## 🔄 Complete Pipeline Flow

```
INPUT
  ↓
[1] Video Download/Upload → Extract Audio
  ↓
[2] Audio Segmentation (VAD-based)
  ↓
[3] Speech Recognition (WhisperKit) → Transcription with timestamps
  ↓
[4] Sentence Segmentation & Translation (Marian NMT)
  ↓
[5] Text-to-Speech Generation (Edge TTS) → Dubbed audio segments
  ↓
[6] Audio Assembly → Stitch TTS segments with timing
  ↓
[7] Video Composition → Replace audio + Embed subtitles
  ↓
OUTPUT: Translated video with dubbed audio + bilingual subtitles
```

---

## 📋 Stage 1: Video Acquisition

### Input Options
1. **Local file upload** (`.mp4`, `.mov`, `.avi`)
2. **YouTube URL** (via yt-dlp)
3. **Bilibili URL** (via yt-dlp)

### Process
```
If local file:
  - Use file directly as video source
  
If URL:
  - Download video with yt-dlp
  - Download audio separately (best quality)
  - Store in: tasks/{taskId}/
```

### Audio Extraction
```bash
ffmpeg -i input_video.mp4 -vn -ar 44100 -ac 2 -ab 192k -f mp3 audio.mp3
```

### Output
- `origin_audio.mp3` - Extracted audio track
- `input_video.mp4` - Original video (if needed for composition)
- Task folder structure created

---

## 📋 Stage 2: Audio Segmentation

### Purpose
Split long audio into manageable chunks for efficient processing

### Voice Activity Detection (VAD)
```
Use FFmpeg silencedetect filter to find natural break points:
- Detect silence > 0.5 seconds
- Split audio at these points
- Target segment length: ~5 minutes
- Create overlapping boundaries for continuity
```

### Segment Creation
```
For each segment [start_time, end_time]:
  - Create: split_audio_000.mp3, split_audio_001.mp3, etc.
  - Store metadata: {id, start, end, duration, file_path}
```

### Output
- Multiple audio segments
- Segment timing metadata
- Progress: 15%

---

## 📋 Stage 3: Speech Recognition (WhisperKit)

### Per Segment Process

**Step 1: Run WhisperKit CLI**
```bash
whisperkit-cli transcribe \
  --model-path ./models/whisperkit/openai_whisper-large-v2 \
  --audio-encoder-compute-units all \
  --text-decoder-compute-units all \
  --language en \
  --report \
  --report-path tasks/{taskId}/ \
  --word-timestamps \
  --skip-special-tokens \
  --audio-path segment.mp3
```

**Step 2: Parse JSON Output**
WhisperKit generates `segment.json` with structure:
```json
{
  "segments": [
    {
      "text": "Hello world",
      "words": [
        {"word": "Hello", "start": 0.12, "end": 0.58},
        {"word": "world", "start": 0.62, "end": 1.05}
      ]
    }
  ]
}
```

**Step 3: Extract Data**
- Full transcript text
- Word-level timing: {word, start_ms, end_ms}
- Segment boundaries

### Parallel Processing
```
Process 2-3 segments simultaneously
Use Apple Neural Engine for acceleration
Monitor memory usage
```

### Merge Results
```
Combine all segment transcriptions
Adjust timestamps to global timeline
Handle segment boundary words
Create unified transcript
```

### Output
- Complete transcript with word-level timestamps
- Timing accuracy: ±50ms
- Progress: 20-70%

---

## 📋 Stage 4: Translation & Sentence Segmentation

### Step 1: Intelligent Sentence Breaking

**Goal**: Split transcript into natural subtitle-length sentences

**Method**:
```
Analyze word timestamps
Detect natural pauses (>500ms between words)
Create sentence boundaries:
  - Min duration: 2 seconds
  - Max duration: 7 seconds
  - Grammatically complete
  - Optimal for subtitle display
```

**Sentence Structure**:
```json
{
  "id": 1,
  "text": "Hello, how are you?",
  "start_time": 0.12,
  "end_time": 2.45,
  "words": [...]
}
```

### Step 2: Translation with Marian NMT

**Context-Aware Translation**:
```python
For each sentence:
  - Get previous 3 sentences (context)
  - Get next 2 sentences (lookahead)
  - Build translation prompt with context
  - Call Marian model
  - Post-process result
```

**Marian Execution**:
```bash
python3 pkg/marian/scripts/translate.py \
  --model ./models/marian \
  --source en \
  --target ru \
  --text "Hello, how are you?"
```

**Parallel Translation**:
```
Process 3-5 sentences simultaneously
Use thread pool
Retry failed translations (max 3 attempts)
Fall back to original text if all fail
```

### Output
- Translated sentence pairs:
```json
{
  "original": "Hello, how are you?",
  "translated": "Привет, как дела?",
  "start": 0.12,
  "end": 2.45
}
```
- Progress: 70-85%

---

## 📋 Stage 5: Subtitle File Generation

### Create SRT Files

**Original Language (en.srt)**:
```
1
00:00:00,120 --> 00:00:02,450
Hello, how are you?

2
00:00:02,500 --> 00:00:05,300
I'm doing great, thanks!
```

**Translated Language (ru.srt)**:
```
1
00:00:00,120 --> 00:00:02,450
Привет, как дела?

2
00:00:02,500 --> 00:00:05,300
У меня всё отлично, спасибо!
```

**Bilingual (bilingual.srt)**:
```
1
00:00:00,120 --> 00:00:02,450
Hello, how are you?
Привет, как дела?

2
00:00:02,500 --> 00:00:05,300
I'm doing great, thanks!
У меня всё отлично, спасибо!
```

### Subtitle Positioning Options
- Original at top, translation at bottom
- Translation at top, original at bottom
- Single language only

---

## 📋 Stage 6: Text-to-Speech Generation

### Per Sentence TTS

**Step 1: Generate Speech**
```bash
edge-tts \
  -f text_input.txt \
  -v ru-RU-DmitryNeural \
  --write-media output.mp3
```

**Step 2: Convert to WAV**
```bash
ffmpeg -i output.mp3 -ar 44100 -ac 1 output.wav
```

**Step 3: Time Alignment**
```
Target duration = subtitle_end - subtitle_start
Generated duration = actual WAV duration
Speed ratio = generated / target

If ratio > 1.2 or < 0.8:
  Adjust speed with FFmpeg:
  ffmpeg -i input.wav -filter:a "atempo={ratio}" output.wav
```

### Parallel TTS Processing
```
Process 3 sentences simultaneously
Implement retry logic (max 3 attempts)
Use exponential backoff
Generate silence for failed TTS
```

### Silence Generation
```
For gaps between sentences:
  Calculate silence_duration = next_start - current_end
  Generate: ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t {duration} silence.wav
```

### Audio Assembly
```
Collect all TTS segments in order:
[TTS_1] [Silence_1] [TTS_2] [Silence_2] ... [TTS_N]

Concatenate:
ffmpeg -f concat -safe 0 -i filelist.txt -c copy final_dubbed.wav
```

### Output
- `final_dubbed_audio.wav` - Complete TTS track
- Timing matches original subtitles
- Progress: 85-95%

---

## 📋 Stage 7: Video Composition

### Step 1: Replace Audio Track
```bash
ffmpeg -i original_video.mp4 -i final_dubbed_audio.wav \
  -c:v copy -map 0:v:0 -map 1:a:0 \
  -c:a aac -b:a 192k \
  video_with_dubbed_audio.mp4
```

### Step 2: Embed Subtitles (Optional)

**Convert SRT to ASS** (for styling):
```
Create ASS file with:
- Font: Arial (macOS default)
- Size: 48 (1080p), 24 (720p)
- Position: Bottom center
- Colors: White text, black outline
- Background: Semi-transparent box
```

**Burn Subtitles into Video**:
```bash
ffmpeg -i video_with_dubbed_audio.mp4 \
  -vf "ass=subtitles.ass" \
  -c:a copy \
  final_output.mp4
```

### Vertical Video Support
```
If width < height (portrait):
  Process as vertical video
  
If width > height (landscape) AND user wants vertical:
  1. Add branded borders (top/bottom)
  2. Scale video to fit 9:16 aspect ratio
  3. Add title overlays
  4. Reposition subtitles for mobile viewing
```

### Output Files
```
tasks/{taskId}/output/
  ├── horizontal_final.mp4      # Landscape with subs
  ├── vertical_final.mp4        # Portrait with subs
  ├── en.srt                    # Original subtitles
  ├── ru.srt                    # Translated subtitles
  ├── bilingual.srt             # Both languages
  └── final_dubbed_audio.wav    # Dubbed audio track
```

### Progress
- 95-100%
- Task status: COMPLETED

---

## 🗂️ Data Structures

### Task State
```swift
enum TaskStatus {
    case created
    case downloading
    case extractingAudio
    case segmenting
    case transcribing
    case translating
    case generatingTTS
    case composing
    case completed
    case failed
}

struct SubtitleTask {
    let taskId: String
    let videoSrc: String
    var status: TaskStatus
    var progress: Int  // 0-100
    var failReason: String?
    var subtitleInfos: [SubtitleInfo]
}
```

### Segment Data
```swift
struct AudioSegment {
    let id: Int
    let filePath: String
    let startTime: Double
    let endTime: Double
    var transcription: TranscriptionData?
}

struct TranscriptionData {
    let text: String
    let words: [Word]
}

struct Word {
    let text: String
    let start: Double  // seconds
    let end: Double
}
```

### Translation Data
```swift
struct Sentence {
    let id: Int
    let originalText: String
    var translatedText: String?
    let startTime: Double
    let endTime: Double
}
```

---

## ⚙️ Configuration

### Local Processing Config
```toml
[transcribe]
provider = "whisperkit"
model = "large-v2"

[translate]
provider = "marian"
model_path = "./models/marian"
source_lang = "en"
target_lang = "ru"

[tts]
provider = "edge-tts"
voice = "ru-RU-DmitryNeural"

[app]
segment_duration = 5  # minutes
transcribe_parallel = 2
translate_parallel = 3
```

### Voice Options (Edge TTS)
```
English:
- en-US-AriaNeural (female)
- en-US-GuyNeural (male)
- en-GB-SoniaNeural (British female)

Russian:
- ru-RU-DmitryNeural (male)
- ru-RU-SvetlanaNeural (female)

Spanish:
- es-ES-ElviraNeural (female)
- es-MX-DaliaNeural (Mexican female)
```

---

## 🏗️ Swift Implementation Architecture

### App Structure
```
VideoTranslatorApp/
├── Models/
│   ├── Task.swift
│   ├── Segment.swift
│   └── Subtitle.swift
├── Services/
│   ├── VideoService.swift
│   ├── AudioService.swift
│   ├── TranscriptionService.swift
│   ├── TranslationService.swift
│   ├── TTSService.swift
│   └── CompositionService.swift
├── Utilities/
│   ├── FFmpegWrapper.swift
│   ├── WhisperKitWrapper.swift
│   ├── MarianWrapper.swift
│   └── EdgeTTSWrapper.swift
├── Views/
│   ├── MainView.swift
│   ├── TaskListView.swift
│   └── ProgressView.swift
└── Pipeline/
    └── TranslationPipeline.swift
```

### Key Classes

**TranslationPipeline**:
```swift
class TranslationPipeline {
    func processVideo(url: String) async throws -> Task
    private func downloadVideo() async throws
    private func extractAudio() async throws
    private func segmentAudio() async throws
    private func transcribeSegments() async throws
    private func translateText() async throws
    private func generateTTS() async throws
    private func composeVideo() async throws
}
```

**WhisperKitWrapper**:
```swift
class WhisperKitWrapper {
    let modelPath = "./models/whisperkit/openai_whisper-large-v2"
    
    func transcribe(audioPath: String, language: String) async throws -> TranscriptionData {
        // Execute whisperkit-cli
        // Parse JSON output
        // Return structured data
    }
}
```

**MarianWrapper**:
```swift
class MarianWrapper {
    func translate(text: String, from: String, to: String) async throws -> String {
        // Execute Python script
        // Parse output
        // Return translation
    }
    
    func translateBatch(_ texts: [String]) async throws -> [String]
}
```

**EdgeTTSWrapper**:
```swift
class EdgeTTSWrapper {
    func generateSpeech(text: String, voice: String, outputPath: String) async throws {
        // Execute edge-tts command
        // Convert to WAV if needed
        // Adjust timing
    }
}
```

---

## 📊 Performance Metrics

### Processing Time (10-min video on M2 Mac)
```
Stage 1 - Download/Extract:     30-60s
Stage 2 - Segmentation:          10-20s
Stage 3 - Transcription:         2-3 min
Stage 4 - Translation:           1-2 min
Stage 5 - Subtitle Generation:   5-10s
Stage 6 - TTS:                   2-4 min
Stage 7 - Composition:           30-60s

TOTAL: ~7-12 minutes
```

### Resource Usage
```
CPU: 30-60% (during transcription)
RAM: 4-8 GB
Disk: 500MB-2GB temporary
Neural Engine: Active (WhisperKit)
Network: Only for Edge TTS
```

---

## 🛠️ Dependencies Setup

### Required Tools
```bash
# 1. Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install FFmpeg
brew install ffmpeg

# 3. Install yt-dlp
brew install yt-dlp

# 4. Install WhisperKit CLI
brew install argmaxinc/formulae/whisperkit-cli

# 5. Install Edge TTS
pip3 install edge-tts

# 6. Install Python dependencies for Marian
pip3 install transformers torch sentencepiece
```

### Model Downloads
```bash
# WhisperKit model (auto-downloaded on first use)
whisperkit-cli download --model large-v2

# Marian models (auto-downloaded by Python script)
# Located in: ./models/marian/
```

---

## 🎯 User Flow

### Minimal User Input
```
1. Select video source (file/URL)
2. Choose:
   - Original language (or auto-detect)
   - Target language
   - Voice type (male/female)
3. Click "Start Translation"
4. Wait for completion (~10 min for 10-min video)
5. Download results
```

### Output Options
```
User receives:
☑ Dubbed video (MP4)
☑ Original subtitles (SRT)
☑ Translated subtitles (SRT)
☑ Bilingual subtitles (SRT)
☑ Dubbed audio track (WAV)
```

---

## ✅ Key Features

### 100% Local Processing
- No API keys required
- All free tools
- Privacy-friendly
- Works offline (except TTS)

### Apple Silicon Optimized
- WhisperKit uses Neural Engine
- Faster than CPU-only solutions
- Energy efficient

### High Quality Output
- Whisper large-v2 model
- Context-aware translation
- Natural TTS voices
- Professional subtitles

---

## 🔍 Error Handling

### Retry Strategies
```
Transcription: Max 3 attempts per segment
Translation: Max 3 attempts per sentence
TTS: Max 3 attempts per segment
```

### Fallback Behaviors
```
If transcription fails: Use silence + empty text
If translation fails: Use original text
If TTS fails: Generate silence with same duration
```

### Recovery
```
Save progress after each stage
Allow resume from last checkpoint
Clean up temporary files on error
```

---

## 📝 Implementation Notes

### Swift-Specific Considerations

**Process Execution**:
```swift
Use Process() for command-line tools
Capture stdout/stderr
Handle async execution
Monitor progress
```

**File Management**:
```swift
Create temporary workspace
Organize by task ID
Clean up completed tasks
Handle permissions
```

**UI Updates**:
```swift
Use @Published properties
Update progress on main thread
Show real-time status
Display logs in debug mode
```

**Concurrency**:
```swift
Use Swift Concurrency (async/await)
Actor-based state management
Parallel processing where possible
Resource-aware scheduling
```

---

## 🎓 Success Criteria

A successful Swift implementation should:

✅ Process 10-min video in < 15 minutes
✅ Use < 8GB RAM
✅ Generate accurate subtitles (< 10% WER)
✅ Produce natural-sounding TTS
✅ Handle errors gracefully
✅ Work on macOS 12+
✅ Support M1/M2/M3 chips
✅ Require zero configuration

---

## 📚 Additional Resources

### Documentation
- WhisperKit: https://github.com/argmaxinc/whisperkit
- Marian NMT: https://marian-nmt.github.io
- Edge TTS: https://github.com/rany2/edge-tts
- FFmpeg: https://ffmpeg.org/documentation.html

### Community
- WhisperKit Discord
- Marian Gitter
- FFmpeg mailing list

---

**Document Purpose**: Complete specification for building a local video translation app on macOS using Swift and free/open-source tools.

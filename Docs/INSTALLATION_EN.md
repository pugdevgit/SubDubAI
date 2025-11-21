# 📦 Installation and Setup

## System Requirements

### Minimum Requirements

- **macOS**: 12.0 or higher
- **RAM**: 8 GB (16 GB recommended)
- **Disk**: 10 GB free space
- **Internet**: Required for model download

### Recommended Requirements

- **macOS**: 13.0 or higher
- **RAM**: 16 GB or more
- **Disk**: SSD with 20+ GB free space
- **Processor**: Apple Silicon (M1/M2/M3) or Intel Core i7+

## Installing Dependencies

### 1. Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install FFmpeg

```bash
brew install ffmpeg
```

**Verify Installation**:
```bash
ffmpeg -version
```

### 3. Install Python and edge-tts

```bash
# Install Python (if not installed)
brew install python@3.11

# Install edge-tts
pip3 install edge-tts
```

**Verify Installation**:
```bash
edge-tts --help
```

### 4. Install Xcode Command Line Tools (if not installed)

```bash
xcode-select --install
```

## Cloning and Setting Up the Project

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/SubDubAI.git
cd SubDubAI
```

### 2. Open Project in Xcode

```bash
open SubDubAI.xcodeproj
```

### 3. Select Target and Scheme

- **Target**: SubDubAI
- **Scheme**: SubDubAI
- **Device**: My Mac

### 4. Build Project

```bash
# In Xcode: ⌘B
# Or in terminal:
xcodebuild build -scheme SubDubAI
```

## First Run

### 1. Run the Application

```bash
# In Xcode: ⌘R
# Or in terminal:
xcodebuild run -scheme SubDubAI
```

### 2. Wait for Model Download

On first run, the application will download:
- **WhisperKit model** (~1.5 GB) - for transcription
- This may take 5-10 minutes depending on internet speed

**Cache Location**:
```bash
~/Library/Caches/huggingface/
```

### 3. Verify Functionality

1. Click "+" button to add video
2. Select test video (1-5 minutes recommended)
3. Choose languages and parameters
4. Click "Start Processing"
5. Monitor progress in queue

## Application Configuration

### Main Settings (Available in UI)

**Settings** → **General**:

- **Max Concurrent Tasks** - Number of simultaneously processed videos (1-4)
  - 1 - Minimum system load
  - 2-3 - Optimal for most systems
  - 4 - Maximum performance (requires 16+ GB RAM)

- **Source Language** - Original video language
- **Target Language** - Dubbing target language
- **TTS Voice** - Voiceover voice
- **Subtitle Format** - Subtitle format (SRT, VTT, ASS)

**Settings** → **Advanced**:

- **Enable Speed Sync** - Automatic voiceover speed synchronization
- **Cleanup Temp Files** - Remove temporary files after processing
- **Auto-start Processing** - Automatically start when adding video

### Environment Variables

```bash
# Specify edge-tts path (if not in PATH)
export EDGE_TTS_PATH=/usr/local/bin/edge-tts

# Specify ffmpeg path (if not in PATH)
export FFMPEG_PATH=/usr/local/bin/ffmpeg

# Increase open file limit
ulimit -n 4096
```

## Troubleshooting Installation

### Error: "ffmpeg not found"

```bash
# Check installation
which ffmpeg

# If not found, install
brew install ffmpeg

# If Homebrew doesn't work, install manually
# Download from https://ffmpeg.org/download.html
```

### Error: "edge-tts not found"

```bash
# Check installation
which edge-tts

# If not found, install
pip3 install edge-tts

# If pip doesn't work
python3 -m pip install edge-tts
```

### Error: "WhisperKit model download failed"

```bash
# Clear cache
rm -rf ~/Library/Caches/huggingface/

# Restart application
# Model will download again
```

### Slow Model Download

- Check internet speed
- Try later (may be server issue)
- Use VPN if access is blocked

### Application Hangs During Processing

- Close other applications to free memory
- Reduce "Max Concurrent Tasks" to 1
- Use shorter videos for testing
- Restart computer

### Error: "Translation failed"

- Check internet connection
- Verify correct languages are selected
- Try restarting the application
- Verify macOS Translation Framework is available

## Performance Optimization

### For Slow Systems (8 GB RAM)

```
Max Concurrent Tasks: 1
Enable Speed Sync: OFF
Cleanup Temp Files: ON
```

### For Medium Systems (12 GB RAM)

```
Max Concurrent Tasks: 2
Enable Speed Sync: ON
Cleanup Temp Files: ON
```

### For Powerful Systems (16+ GB RAM)

```
Max Concurrent Tasks: 3-4
Enable Speed Sync: ON
Cleanup Temp Files: ON
```

## Working with Video Files

### Supported Formats

**Video**:
- MP4, MOV, AVI, MKV, WebM, FLV

**Audio**:
- MP3, AAC, WAV, FLAC, OGG

### Recommended Video Parameters

- **Resolution**: 720p or higher
- **Video Bitrate**: 2-5 Mbps
- **Audio Bitrate**: 128-192 kbps
- **Frame Rate**: 24-60 fps
- **Video Codec**: H.264 or H.265

### File Sizes

- **Minimum**: 100 MB
- **Optimal**: 500 MB - 2 GB
- **Maximum**: 10 GB (may be slow)

## Working with Output Files

### Output Folder Structure

```
Output/
├── video_name_ru.mp4          # Final dubbed video
├── video_name_ru.srt          # Subtitles
├── audio_dubbed.mp3           # Voiceover
└── .subdubai/
    ├── audio.mp3              # Original audio
    ├── transcription.json     # Transcription
    ├── segments.json          # Segments
    └── tts/                   # Voiceovers by segment
```

### Subtitle Formats

- **SRT** - Standard format, compatible with all players
- **VTT** - WebVTT, supports styles and positioning
- **ASS** - Advanced SubStation Alpha, maximum capabilities

## Backup and Recovery

### Saving Settings

Settings are stored in:
```bash
~/Library/Preferences/com.yourcompany.SubDubAI.plist
```

To backup:
```bash
cp ~/Library/Preferences/com.yourcompany.SubDubAI.plist ~/Desktop/SubDubAI_backup.plist
```

### Restoring from Backup

```bash
cp ~/Desktop/SubDubAI_backup.plist ~/Library/Preferences/com.yourcompany.SubDubAI.plist
```

## Updating the Application

### Update from Repository

```bash
cd SubDubAI
git pull origin main
xcodebuild build -scheme SubDubAI
```

### Update Dependencies

```bash
# FFmpeg
brew upgrade ffmpeg

# edge-tts
pip3 install --upgrade edge-tts

# Swift packages (automatic in Xcode)
# File → Packages → Update to Latest Package Versions
```

## Uninstalling the Application

### Complete Removal

```bash
# Remove application
rm -rf /Applications/SubDubAI.app

# Remove model cache
rm -rf ~/Library/Caches/huggingface/

# Remove settings
rm ~/Library/Preferences/com.yourcompany.SubDubAI.plist

# Remove temporary files
rm -rf ~/Library/Application\ Support/SubDubAI/
```

## Getting Help

### Logging and Debugging

Enable detailed logging:
```bash
# In Xcode: Product → Scheme → Edit Scheme
# Run → Arguments Passed On Launch: -com.apple.CoreData.SQLDebug 1
```

### Collecting Information for Bug Report

```bash
# System information
system_profiler SPSoftwareDataType SPHardwareDataType

# FFmpeg version
ffmpeg -version

# edge-tts version
edge-tts --version

# Application logs
log stream --predicate 'process == "SubDubAI"'
```

---

**Last Updated**: November 2025

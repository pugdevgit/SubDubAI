# ❓ Frequently Asked Questions (FAQ)

## General Questions

### Q: What is SubDubAI?
**A**: SubDubAI is a macOS application that automatically translates videos and creates dubbing. It uses AI for transcription, translation, and speech synthesis.

### Q: What languages are supported?
**A**: The application supports 70+ languages thanks to the built-in macOS Translation Framework. Main languages: English, Russian, Spanish, French, German, Italian, Portuguese, Japanese, Chinese, and others.

### Q: Is it free?
**A**: Yes, SubDubAI is completely free. All used technologies (WhisperKit, macOS Translation, edge-tts, FFmpeg) are either built-in or open-source.

### Q: Do I need internet?
**A**: Partially. For transcription and video processing, internet is not required (after model download). For translation and speech synthesis, internet connection is required.

### Q: What video formats are supported?
**A**: All formats supported by FFmpeg are supported: MP4, MOV, AVI, MKV, WebM, FLV, and others.

---

## Installation and Requirements

### Q: What are the system requirements?
**A**: 
- macOS 12.0 or higher
- 8 GB RAM (16 GB recommended)
- 10 GB free disk space
- Internet connection for model download

### Q: How do I install dependencies?
**A**: 
```bash
brew install ffmpeg
pip3 install edge-tts
```

### Q: Where can I download the application?
**A**: Clone the repository:
```bash
git clone https://github.com/yourusername/SubDubAI.git
cd SubDubAI
open SubDubAI.xcodeproj
```

### Q: Why is the application slow on first run?
**A**: On first run, the WhisperKit model (~1.5 GB) is downloaded. This is normal and happens only once. Subsequent runs will be fast.

### Q: Where are models stored?
**A**: 
```bash
~/Library/Caches/huggingface/
```

### Q: How do I clear the model cache?
**A**: 
```bash
rm -rf ~/Library/Caches/huggingface/
```

---

## Usage

### Q: How do I add a video for processing?
**A**: 
1. Click "+" button in main window
2. Select video file or folder
3. Choose languages and parameters
4. Click "Add"

### Q: How do I process multiple videos simultaneously?
**A**: Add multiple videos to the queue. The application will process them in parallel depending on "Max Concurrent Tasks" setting (1-4).

### Q: How do I change the translation language?
**A**: 
1. Open Settings
2. Select "Target Language"
3. Choose desired language

### Q: How do I select a different voiceover voice?
**A**: 
1. Open Settings
2. Select "TTS Voice"
3. Choose desired voice from list

### Q: How do I change subtitle format?
**A**: 
1. Open Settings
2. Select "Subtitle Format"
3. Choose SRT, VTT, or ASS

### Q: What does each task status mean?
**A**:
- **Pending** - Waiting for processing
- **Processing** - Currently processing
- **Completed** - Successfully completed
- **Failed** - Error during processing
- **Cancelled** - Cancelled by user

### Q: How do I cancel video processing?
**A**: Click "Cancel" button next to task in queue.

### Q: Where are processing results located?
**A**: In folder next to source video:
```
Output/
├── video_name_ru.mp4          # Final video
├── video_name_ru.srt          # Subtitles
└── audio_dubbed.mp3           # Voiceover
```

---

## Performance and Optimization

### Q: Why is processing slow?
**A**: Several reasons:
- Insufficient RAM (requires 8+ GB)
- Too many concurrent tasks
- Large video file
- Weak processor

**Solution**: Reduce "Max Concurrent Tasks" to 1-2 and close other applications.

### Q: How long does video processing take?
**A**: For 1-hour video:
- Transcription: 10-30 minutes
- Translation: 1-3 minutes
- Speech synthesis: 5-15 minutes
- Assembly and composition: 10-15 minutes
- **Total**: 30-60 minutes

Time depends on computer power and video length.

### Q: How do I speed up processing?
**A**:
1. Use computer with more power
2. Increase RAM to 16+ GB
3. Use SSD instead of HDD
4. Close other applications
5. Increase "Max Concurrent Tasks" (if enough memory)

### Q: What graphics cards are supported?
**A**: Application uses CPU for processing. GPU acceleration is planned for future versions.

---

## Errors and Troubleshooting

### Q: Error "ffmpeg not found"
**A**: 
```bash
brew install ffmpeg
# Or download from https://ffmpeg.org/download.html
```

### Q: Error "edge-tts not found"
**A**: 
```bash
pip3 install edge-tts
```

### Q: Error "Transcription failed"
**A**: 
- Check that audio is clear
- Verify correct language is selected
- Try shorter video
- Restart application

### Q: Error "Translation failed"
**A**: 
- Check internet connection
- Verify correct languages are selected
- Try later (may be server issue)
- Restart application

### Q: Error "TTS generation failed"
**A**: 
- Check internet connection
- Verify correct voice is selected
- Try different voice
- Restart application

### Q: Application hangs during processing
**A**: 
- Close other applications
- Reduce "Max Concurrent Tasks" to 1
- Restart computer
- Check free memory

### Q: Application crashes with error
**A**: 
1. Open Console.app
2. Find SubDubAI logs
3. Copy error message
4. Create issue on GitHub with this information

### Q: Video doesn't open in player
**A**: 
- Check that video is fully processed
- Try opening in different player (VLC, QuickTime)
- Check that video codec is supported

### Q: Subtitles are not synchronized
**A**: 
- May be issue with source video
- Try enabling "Enable Speed Sync"
- Try different subtitle format

### Q: Voiceover is not synchronized with video
**A**: 
- Enable "Enable Speed Sync" in Settings
- Check that source video is not corrupted
- Try reprocessing video

---

## Functionality

### Q: Can the application process videos with multiple audio tracks?
**A**: Not yet, application processes only first audio track. This is planned for future versions.

### Q: Can the application preserve original sound?
**A**: No, application replaces original sound with dubbing. This is planned for future versions.

### Q: Can the application process live streams?
**A**: No, application works only with local video files.

### Q: Can the application download videos from YouTube?
**A**: No, but you can download video using youtube-dl and then process it in SubDubAI.

### Q: Can the application process videos with subtitles?
**A**: Application ignores existing subtitles and creates new ones based on transcription.

### Q: Can the application preserve original subtitles?
**A**: No, application creates new subtitles based on translation.

---

## Advanced Questions

### Q: How do I use the application from command line?
**A**: Not currently supported, but CLI interface is planned.

### Q: How do I integrate SubDubAI into another application?
**A**: Application uses Clean Architecture, so its components can be easily used in other projects. Contact developer for API information.

### Q: How do I add support for new languages?
**A**: Languages are supported through macOS Translation Framework. If your language is not supported, it's a system limitation.

### Q: How do I add support for new voices?
**A**: Voices are provided by edge-tts. If you want to add new voice, create issue on GitHub.

### Q: How do I use custom transcription model?
**A**: Not currently supported, but this feature is planned.

### Q: How do I use cloud services instead of local?
**A**: This is planned for future versions. Currently application uses only local solutions.

---

## Development and Contributing

### Q: How can I help with development?
**A**: 
1. Fork the repository
2. Create branch for your feature
3. Make changes
4. Create pull request

### Q: How do I report a bug?
**A**: 
1. Open GitHub Issues
2. Describe the problem
3. Attach logs and screenshots
4. Specify macOS version and hardware

### Q: How do I suggest a new feature?
**A**: 
1. Open GitHub Issues
2. Describe the feature
3. Explain why it's needed
4. Suggest implementation (if possible)

### Q: Where can I find code documentation?
**A**: 
- README.md - General information
- ARCHITECTURE.md - Application architecture
- INSTALLATION.md - Installation and setup
- TECHNOLOGIES.md - Used technologies
- Code comments

### Q: How do I run tests?
**A**: 
```bash
xcodebuild test -scheme SubDubAI
```

### Q: How do I build a release?
**A**: 
```bash
xcodebuild build -scheme SubDubAI -configuration Release
```

---

## License and Legal

### Q: What license is used?
**A**: MIT License. You can use, modify, and distribute the application freely.

### Q: Can I use this commercially?
**A**: Yes, MIT License allows commercial use.

### Q: What content rights do I get?
**A**: You get rights to the video you created. Make sure you have rights to the source video and music.

### Q: Is there a warranty?
**A**: No, application is provided "as is" without warranties. Use at your own risk.

---

## Contacts and Support

### Q: How do I contact the developer?
**A**: 
- GitHub Issues for bugs and features
- Email: [your email]
- Twitter: [@your twitter]

### Q: Where can I find latest news?
**A**: 
- GitHub Releases
- GitHub Discussions
- Twitter

### Q: How can I support the project?
**A**: 
- ⭐ Star on GitHub
- 🐛 Report bugs
- 💡 Suggest new features
- 🤝 Create pull requests
- 📢 Recommend to friends

---

**Last Updated**: November 2025

If you didn't find answer to your question, create issue on GitHub or contact the developer.

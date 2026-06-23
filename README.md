# 🎓 Class Notes Pipeline

This project is 100% **VIBE CODED** to secure absolute freedom from expensive, restrictive subscription wrappers (like WisprFlow, Otter.ai, Plaud, and Fathom) and bypass annoying API rate limits. 

It is an automated, intelligent command-line pipeline designed to record class lectures or online meetings, compress audio on-the-fly to save disk space, transcribe utilizing Google Gemini on Cloud TPUs (free today using Gemini's developer free tier), and format raw text transcripts into beautiful, production-grade Microsoft Word (`.docx`) notes.

The pipeline is completely self-contained and automatically manages directories, files, and post-recording cleanup.

---

## ✨ Key Features

1. **Dual Recording Modes**
   * **Online Class**: Captures desktop/system audio directly from loopback sinks (perfect for Zoom, Teams, or browser-based lectures).
   * **Offline Class**: Captures physical microphone inputs (ideal for in-person classroom lectures).

2. **Storage-Optimized Audio (Up to 98% Space Saved)**
   * Recording creates raw, high-fidelity temporary `.wav` files.
   * Immediately after recording stops, the pipeline uses `ffmpeg` to compress the audio into a mono `.mp3` (16kHz, 32kbps), which keeps voice clarity perfect for transcription but reduces file sizes by up to 98%.
   * The original raw WAV is automatically deleted to reclaim disk space.

3. **Cloud-Based Transcription via Gemini**
   * Fast audio uploads and Cloud TPU-powered transcription in seconds.
   * Configurable model selection through the interactive pipeline or environment variable (`GEMINI_MODEL`).

4. **Transient Error Resilience**
   * Network requests are wrapped in retry loops with exponential backoff.
   * Gracefully handles transient API spikes like `503 Service Unavailable` or `429 Rate Limit/Quota Exceeded` without crashing mid-run.

5. **Auto-Generated DOCX Notes**
   * Leverages Gemini to filter filler words ("um", "uh", "like") and fix grammar.
   * Structuring prompts organize the transcript into clean sections including a Summary, Topics, and Action Items.
   * The text is styled directly into a beautiful Word document (`.notes.docx`) with styled Arial fonts, custom margins, colored headers, and parsed inline formatting (`**bold**`, `*italics*`).

6. **Automatic File Organization & Clean-up**
   * Automatically moves the final structured notes to `~/Desktop/notes/<session_name>.docx`.
   * Automatically moves the compressed audio recording to `~/Desktop/classrecordings/[online|offline]/<session_name>.mp3`.
   * Automatically deletes temporary transcript `.txt` files, markdown files, and temporary directories.

7. **Standalone CLI Commands**
   * Manually compress historical WAV folders or files to MP3 using `class-notes compress <path>`.
   * Manually compile a compiled PDF/DOCX report of multiple files using `class-notes report <dir>`.

---

## 🛠️ Requirements & Setup

### System Dependencies
Ensure `ffmpeg` and audio capture packages are installed on your Linux system:
```bash
sudo apt update
sudo apt install ffmpeg pulseaudio-utils alsa-utils -y
```

### Python Dependencies
Install the required Python packages:
```bash
pip install google-genai python-docx pandas matplotlib seaborn --break-system-packages
```

### Environment Variables
Export your Gemini API Key in your shell or add it to `~/.bashrc`:
```bash
export GEMINI_API_KEY="your_api_key_here"
```
Optional: You can also pre-define a default Gemini model (defaults to `gemini-2.5-flash`):
```bash
export GEMINI_MODEL="gemini-2.5-pro"
```

---

## 🚀 Usage

### 1. Interactive Mode (Recording + Transcribing + Note-taking)
Run the script without arguments to start the guided wizard:
```bash
bash class_notes.sh
```
Follow the prompts to select recording modes (Online/Offline), input the session name, control recording capture (press `Ctrl+C` to stop recording), choose your Gemini model, and watch the pipeline automatically record, compress, transcribe, format, and organize your files!

### 2. Manual Audio Compression
If you have old recordings eating up disk space, optimize them retroactively:
* Compress all large WAV files in a directory:
  ```bash
  bash class_notes.sh compress ~/Desktop/notes/my_session
  ```
* Compress a single WAV file:
  ```bash
  bash class_notes.sh compress /path/to/recording.wav
  ```

### 3. Compile DOCX & PDF Reports
Compile all notes, text, CSVs, and images in a session directory into a unified DOCX/PDF report (generating Matplotlib charts where data is present):
```bash
bash class_notes.sh report ~/Desktop/notes/my_session
```

### 4. Transcribe a File Directly
```bash
bash class_notes.sh transcribe <file.wav/mp3> [--local]
```

### 5. Format Transcript to Notes Directly
```bash
bash class_notes.sh make-notes <transcript.txt> [context]
```

---

## 🏁 Windows Compatibility & Setup

Yes, it is absolutely possible to run this pipeline on Windows! You have two main routes:

### Route A: WSL (Windows Subsystem for Linux) — Recommended
Since WSL runs a native Linux kernel (like Ubuntu), this pipeline works **out of the box** with minor adjustments to audio recording:
1. Install WSL from PowerShell: `wsl --install`
2. Open your WSL terminal and follow the **Linux Ubuntu setup instructions** above to install `ffmpeg`, `python3`, and python packages.
3. PulseAudio in WSL can capture Windows audio sinks. Alternatively, you can record using a native Windows terminal and run the transcription/note-taking scripts on the recorded files in WSL.

### Route B: Native Windows (PowerShell + WASAPI)
To run natively without WSL, you can port the Bash script (`class_notes.sh`) to a PowerShell script (`class_notes.ps1`):
1. **Python Dependencies**: Install Python for Windows and run `pip install google-genai python-docx pandas matplotlib seaborn`.
2. **FFmpeg for Windows**: Download the Windows builds of FFmpeg and add the `bin` folder to your Windows system Environment variables PATH.
3. **Native Audio Capture**: On Windows, `ffmpeg` can capture speaker output (desktop loopback) natively using **WASAPI** (Windows Audio Session API) or microphone devices via **DirectShow**:
   * **Capture Zoom / System Audio**:
     ```powershell
     ffmpeg -f wasapi -i audio="Speakers (Loopback)" output.wav
     ```
   * **Capture Microphone**:
     ```powershell
     ffmpeg -f dshow -i audio="Microphone (Your Device Name)" output.wav
     ```
4. **PowerShell Flow**: Replace bash variables with PowerShell script flow to run `python scripts\class_transcriber.py` and `python scripts\gemini_note_taker.py`.

---

## 📁 Repository Structure

```
.
├── README.md
├── class_notes.sh
└── scripts/
    ├── class_transcriber.py
    ├── gemini_note_taker.py
    └── gemini_report_maker.py
```

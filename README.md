# Class Notes Pipeline

This project is a self-hosted alternative to paid subscription transcription wrappers (such as WisprFlow, Otter.ai, Plaud, and Fathom). It was developed collaboratively using conversational agent-assisted development (colloquially referred to as "vibe coding") to bypass API rate limits and avoid subscription fees.

The system is an automated command-line pipeline designed to record class lectures or online meetings, compress audio on-the-fly to minimize storage consumption, transcribe the recordings using Google Gemini on Cloud TPUs (utilizing Gemini's developer free tier), and format the raw text transcripts into structured Microsoft Word (`.docx`) documents.

The pipeline is self-contained and automatically handles directories, file paths, and post-recording cleanup.

---

## Key Features

1. **Dual Recording Modes**
   * **Online Class**: Captures desktop/system audio directly from loopback sinks (designed for Zoom, Teams, or web browser streams).
   * **Offline Class**: Captures physical microphone input (designed for in-person classroom lectures).

2. **Storage-Optimized Audio**
   * The recording process creates temporary, high-fidelity `.wav` files.
   * Immediately upon recording termination, the pipeline uses `ffmpeg` to compress the audio into a mono `.mp3` file (16kHz, 32kbps). This preserves vocal clarity for transcription while reducing the file size by up to 98%.
   * The raw WAV file is deleted immediately to reclaim disk space.

3. **Cloud-Based Transcription**
   * Leverages Gemini APIs for rapid transcription using Cloud TPUs.
   * Supports dynamic model selection via the interactive pipeline prompt or the `GEMINI_MODEL` environment variable.

4. **Transient Error Resilience**
   * API requests (upload and content generation) are wrapped in retry loops with exponential backoff.
   * Automatically handles transient API exceptions such as `503 Service Unavailable` or `429 Rate Limit/Quota Exceeded` without terminating the execution.

5. **Auto-Generated DOCX Notes**
   * Uses Gemini to clean transcripts, removing filler words and correcting grammatical structures.
   * Structures the transcript into logical sections, including a Summary, Topics, and Action Items.
   * Formats the content directly into a styled Word document (`.notes.docx`) using custom margins, custom heading colors, and parsed inline formatting (`**bold**`, `*italics*`).

6. **Automatic File Organization & Clean-up**
   * Moves the final Word document to `~/Desktop/notes/<session_name>.docx`.
   * Moves the compressed MP3 recording to `~/Desktop/classrecordings/[online|offline]/<session_name>.mp3`.
   * Deletes the temporary `.txt` transcript file, temporary markdown files, and empty workspace folders.

7. **Standalone CLI Commands**
   * Manually compress old WAV files to MP3 using `class-notes compress <path>`.
   * Manually compile session resources into a unified report using `class-notes report <dir>`.

---

## Requirements & Setup

### System Dependencies
Ensure `ffmpeg` and audio capture utilities are installed:
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
Set the Gemini API Key in your shell configuration or `~/.bashrc`:
```bash
export GEMINI_API_KEY="your_api_key_here"
```
Optional: You can also specify a default Gemini model (defaults to `gemini-2.5-flash`):
```bash
export GEMINI_MODEL="gemini-2.5-pro"
```

---

## Usage

### 1. Interactive Mode (Recording + Transcribing + Note-taking)
Execute the script without arguments to start the interactive workflow:
```bash
bash class_notes.sh
```
Follow the console prompts to select the recording mode, name the session, control audio capture (terminate using `Ctrl+C`), and select the target Gemini model.

### 2. Manual Audio Compression
To compress existing large WAV files to MP3:
* Compress all WAV files in a directory:
  ```bash
  bash class_notes.sh compress ~/Desktop/notes/my_session
  ```
* Compress a single WAV file:
  ```bash
  bash class_notes.sh compress /path/to/recording.wav
  ```

### 3. Compile DOCX & PDF Reports
Compile note files, transcripts, CSV data, and images in a directory into a unified DOCX/PDF report:
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

## Windows Compatibility & Setup

This pipeline can be run on Windows systems using one of two methods:

### Method A: WSL (Windows Subsystem for Linux)
Because WSL runs a native Linux kernel, this pipeline works with minor configuration of the audio recording inputs:
1. Install WSL from PowerShell: `wsl --install`
2. Launch the WSL Ubuntu instance and install `ffmpeg`, `python3`, and python dependencies.
3. Configure PulseAudio or record using a native Windows terminal, then copy files to the WSL environment.

### Method B: Native Windows (PowerShell + WASAPI)
To run natively on Windows, port the controller script (`class_notes.sh`) to a PowerShell script (`class_notes.ps1`):
1. **Python Dependencies**: Install Python for Windows and run `pip install google-genai python-docx pandas matplotlib seaborn`.
2. **FFmpeg for Windows**: Download the Windows builds of FFmpeg and add the executable to the system PATH.
3. **Audio Capture Devices**: Use FFmpeg to capture audio inputs natively via **WASAPI** (Windows Audio Session API) or **DirectShow**:
   * **System Audio Capture**:
     ```powershell
     ffmpeg -f wasapi -i audio="Speakers (Loopback)" output.wav
     ```
   * **Microphone Input Capture**:
     ```powershell
     ffmpeg -f dshow -i audio="Microphone (Device Name)" output.wav
     ```
4. **PowerShell execution**: Port shell commands to run Python scripts natively using Windows path structures.

---

## Repository Structure

```
.
├── README.md
├── class_notes.sh
└── scripts/
    ├── class_transcriber.py
    ├── gemini_note_taker.py
    └── gemini_report_maker.py
```

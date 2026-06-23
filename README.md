# Class Notes Pipeline

This project was **100% Vibe-Coded using AI** as a self-hosted alternative to paid subscription transcription tools (such as WisprFlow, Otter.ai, Plaud, and Fathom) to bypass usage limits and avoid monthly subscription fees.

### Everything is Automatic

You do not need to memorize or use any of the manual subcommands. By simply running the main script, the interactive guide takes care of everything automatically:
1. Guides you through starting and stopping the recording.
2. Compresses the audio automatically to save disk space.
3. Automatically transcribes the recording (using cloud Gemini or local Whisper).
4. Automatically formats the transcript into a beautifully styled Microsoft Word notes document.
5. Neatly moves the final notes and recording files to your Desktop folders and deletes all temporary files automatically.

One command is all you need:
```bash
bash class_notes.sh
```

---

## Key Features

1. **Two Recording Options**
   * **Online Class**: Records computer audio (for Zoom, Teams, or web browser streams).
   * **Offline Class**: Records your microphone (for in-person classroom lectures).

2. **Storage Optimization**
   * Recording creates large raw audio files (.wav).
   * As soon as recording stops, the tool converts the audio to a much smaller MP3 file to save space without losing the vocal clarity needed for transcription.
   * The original large recording file is deleted immediately to save disk space.

3. **Transcription**
   * Uploads the audio and transcribes it using Google Gemini.
   * Allows you to choose different Gemini models depending on your needs.

4. **Connection Resilience**
   * If the connection fails temporarily (due to high traffic or rate limits), the tool automatically waits and retries instead of crashing.

5. **Auto-Generated Word Notes**
   * Cleans the transcript by removing filler words (like "um" and "uh") and correcting grammar.
   * Organizes the transcript into logical sections, including a Summary, Topics, and Action Items.
   * Saves the notes directly as a styled Microsoft Word file (`.docx`) with custom margins, clean fonts, colored headings, and standard text formatting (bold and italics).

6. **File Organization & Clean-up**
   * Moves the final Word document to your Desktop notes folder (`~/Desktop/notes/`).
   * Moves the recording to your Desktop recordings folder (`~/Desktop/classrecordings/[online/offline]/`).
   * Deletes temporary text transcripts, markdown files, and empty workspace folders automatically.

7. **Standalone Commands**
   * Manually compress old audio files to MP3 to save space.
   * Manually compile session resources into a unified report.

---

## Requirements & Setup

### Option 1: Automatic Setup (Recommended)
You can run the interactive setup script which automatically checks system dependencies (like `ffmpeg`), installs python packages, and configures your Gemini API key:
```bash
bash setup.sh
```

### Option 2: Manual Setup
If you prefer to configure the environment manually:
1. **System Tools**: Ensure `ffmpeg` and audio utilities are installed:
   ```bash
   sudo apt update
   sudo apt install ffmpeg pulseaudio-utils alsa-utils -y
   ```
2. **Python Packages**: Install the python requirements:
   ```bash
   pip install -r requirements.txt --break-system-packages
   ```
3. **API Keys**: Export your Gemini API Key:
   ```bash
   export GEMINI_API_KEY="your_api_key_here"
   ```

---

## Usage

### 1. Interactive Recording
Start the guided setup (walks you through recording, transcribing, and note-taking):
```bash
bash class_notes.sh record
```
*(You can also run `bash class_notes.sh` without arguments to start the same guide).*

### 2. Record Offline (Microphone)
Record your physical microphone directly:
```bash
bash class_notes.sh recordoffline [output.wav]
```

### 3. Record Online (Speakers / Zoom)
Record your computer speakers directly:
```bash
bash class_notes.sh recordonline [output.wav]
```

### 4. Transcribe Locally (Offline)
Transcribe an audio file on your local machine without the internet:
```bash
bash class_notes.sh use_local <file.mp3/wav>
```

### 5. Compress Audio (Save Space)
Compress large WAV files to MP3 and delete the original to free up space:
```bash
bash class_notes.sh compress <folder_or_file> [--keep-wav]
```

### 6. Format Notes Directly
Turn a transcript text file into formatted Word notes:
```bash
bash class_notes.sh notes <transcript.txt>
```

### 7. Compile Reports
Compile notes, CSVs, and images in a folder into a final document:
```bash
bash class_notes.sh report <folder>
```

---

## Running Local AI (Offline Mode)

If you have a laptop with a powerful graphics card (GPU), you can run the entire pipeline completely offline without using Google Gemini or the internet.

### 1. Local Audio Transcription
Local transcription is already built directly into the tool using **Whisper** (specifically the `faster-whisper` package):
* When running the interactive recorder, select **Option 2 (Local Mode)** when prompted for transcription.
* When running via command line, append the `--local` flag:
  ```bash
  bash class_notes.sh transcribe recording.mp3 --local
  ```

### 2. Local Note-Taking
To clean and format notes without sending data to Google's servers:
1. Download and install **Ollama** (a free tool that lets you run models like Llama 3 or Mistral locally on your computer).
2. Start the local Ollama server.
3. Replace the Google Gemini API client setup in `gemini_note_taker.py` with Ollama's local python client to send the prompts to your local GPU.

---

## Windows Compatibility & Setup

Yes, it is possible to run this pipeline on Windows using **WSL (Windows Subsystem for Linux)**:

1. WSL lets you run a Linux environment inside Windows. Install it from PowerShell by running:
   ```powershell
   wsl --install
   ```
2. Open the WSL terminal (typically Ubuntu) and follow the **Requirements & Setup** instructions above to install Python, FFmpeg, and the required Python packages.
3. You can then run the pipeline scripts exactly as you would on a Linux system.

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

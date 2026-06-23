# Class Notes Pipeline

This project is a self-hosted alternative to paid subscription transcription tools (such as WisprFlow, Otter.ai, Plaud, and Fathom). It was built using AI-assisted development (colloquially called "vibe coding") to bypass usage limits and avoid monthly subscription fees.

The system is an automated tool designed to record class lectures or online meetings, compress the audio to save disk space, transcribe the speech using Google Gemini (free today under Gemini's developer free tier), and format the transcripts into structured Microsoft Word (`.docx`) notes.

The pipeline automatically handles directories, files, and cleans up temporary folders when finished.

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

### System Tools
Ensure `ffmpeg` and audio recording tools are installed on your Linux system:
```bash
sudo apt update
sudo apt install ffmpeg pulseaudio-utils alsa-utils -y
```

### Python Packages
Install the required Python packages:
```bash
pip install google-genai python-docx pandas matplotlib seaborn --break-system-packages
```

### API Configuration
Set your Gemini API Key in your shell configuration or `~/.bashrc`:
```bash
export GEMINI_API_KEY="your_api_key_here"
```
Optional: You can specify a default Gemini model (defaults to `gemini-2.5-flash`):
```bash
export GEMINI_MODEL="gemini-2.5-pro"
```

---

## Usage

### 1. Interactive Recording
Run the script without arguments to start:
```bash
bash class_notes.sh
```
Follow the screen prompts to select your recording mode, name the session, control capture (press `Ctrl+C` to stop), and choose the Gemini model.

### 2. Manual Audio Compression
To compress old recordings and delete the original large files:
* Compress all files in a folder:
  ```bash
  bash class_notes.sh compress ~/Desktop/notes/my_session
  ```
* Compress a single file:
  ```bash
  bash class_notes.sh compress /path/to/recording.wav
  ```

### 3. Compile Reports
Compile notes, transcripts, CSV data, and images in a folder into a unified report:
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

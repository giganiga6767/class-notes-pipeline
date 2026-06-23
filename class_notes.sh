#!/usr/bin/env bash
# class_notes.sh
# Main CLI wrapper for recording, transcribing, note-taking, and report generation.

# Auto-load API key from ~/.bashrc if not already exported in current shell session
if [ -z "$GEMINI_API_KEY" ]; then
  KEY_LINE=$(grep "export GEMINI_API_KEY=" /home/niranjan/.bashrc | head -n 1)
  if [ -n "$KEY_LINE" ]; then
    KEY_VAL=$(echo "$KEY_LINE" | cut -d'"' -f2)
    if [ -n "$KEY_VAL" ] && [ "$KEY_VAL" != "export GEMINI_API_KEY=" ]; then
      export GEMINI_API_KEY="$KEY_VAL"
    fi
  fi
fi

# Auto-load model from ~/.bashrc if not already defined in current shell session
if [ -z "$GEMINI_MODEL" ]; then
  MODEL_LINE=$(grep "export GEMINI_MODEL=" /home/niranjan/.bashrc | head -n 1)
  if [ -n "$MODEL_LINE" ]; then
    MODEL_VAL=$(echo "$MODEL_LINE" | cut -d'"' -f2)
    if [ -n "$MODEL_VAL" ] && [ "$MODEL_VAL" != "export GEMINI_MODEL=" ]; then
      export GEMINI_MODEL="$MODEL_VAL"
    fi
  fi
fi

# Set directories relative to the location of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TRANSCRIBER_SCRIPT="$SCRIPT_DIR/scripts/class_transcriber.py"
NOTE_TAKER_SCRIPT="$SCRIPT_DIR/scripts/gemini_note_taker.py"
REPORT_MAKER_SCRIPT="$SCRIPT_DIR/scripts/gemini_report_maker.py"


show_help() {
  echo "🎓 Class Notes Pipeline CLI"
  echo "Usage: class-notes [command] [arguments]"
  echo ""
  echo "If run without arguments, it starts the interactive session recorder."
  echo ""
  echo "Commands:"
  echo "  report <session_dir>           Compile all files in a session directory into a DOCX & PDF report"
  echo "  record-mic [output.wav]         Record audio from your physical microphone"
  echo "  record-system [output.wav]      Record audio from your computer (Zoom / Online Class)"
  echo "  transcribe <file.wav> [--local]  Transcribe audio to text (defaults to Gemini cloud, --local for Whisper)"
  echo "  make-notes <file.txt> [context] Turn transcript text into formatted Markdown notes (.notes.md)"
  echo "  compress <path>                Compress all WAV files in a directory (or a single WAV file) to MP3, deleting original WAVs to save space"
  echo ""
  echo "Environment Variables:"
  echo "  GEMINI_API_KEY  Your Google Gemini API Key"
  echo "  GEMINI_MODEL    Gemini model to use (default: gemini-2.5-flash)"
  echo ""
}

# ── Interactive Mode (No Arguments) ─────────────────────────────────────────
if [ -z "$1" ]; then
  echo "🎓 Welcome to the Class Notes Pipeline"
  echo "----------------------------------------"
  echo "Select Recording Mode:"
  echo "  1) Online Class (Zoom / Webcast / Computer Audio)"
  echo "  2) Offline Class (Microphone / In-person Lecture)"
  read -p "Enter choice [1-2]: " MODE_CHOICE
  
  read -p "Enter session name (e.g. biology_class_1): " SESSION_NAME
  # Clean session name: replace spaces with underscores, remove special chars
  SESSION_NAME=$(echo "$SESSION_NAME" | sed 's/ /_/g' | tr -cd '[:alnum:]_')
  if [ -z "$SESSION_NAME" ]; then
    SESSION_NAME="class_session_$(date +%Y%m%d_%H%M%S)"
  fi
  
  # Desktop notes directory
  TARGET_DIR="/home/niranjan/Desktop/notes/$SESSION_NAME"
  mkdir -p "$TARGET_DIR"
  
  AUDIO_FILE_WAV="$TARGET_DIR/${SESSION_NAME}.wav"
  AUDIO_FILE="$TARGET_DIR/${SESSION_NAME}.mp3"
  TXT_FILE="$TARGET_DIR/${SESSION_NAME}.txt"
  NOTES_FILE="$TARGET_DIR/${SESSION_NAME}.notes.md"
  
  if [ "$MODE_CHOICE" == "1" ]; then
    echo -e "\n💻 Recording system audio (Zoom) from default monitor output..."
    echo "🛑 Press Ctrl+C to STOP recording when the class ends."
    echo "--------------------------------------------------"
    if command -v parecord &> /dev/null; then
      # PulseAudio/PipeWire special device target '@DEFAULT_MONITOR@' records desktop output audio
      parecord -d @DEFAULT_MONITOR@ "$AUDIO_FILE_WAV"
    elif command -v pw-record &> /dev/null; then
      MONITOR=$(pactl get-default-sink 2>/dev/null).monitor
      if [ -z "$MONITOR" ] || [ "$MONITOR" == ".monitor" ]; then
        pw-record "$AUDIO_FILE_WAV"
      else
        pw-record --target "$MONITOR" "$AUDIO_FILE_WAV"
      fi
    else
      echo "❌  Error: Neither parecord nor pw-record is installed."
      exit 1
    fi
  else
    echo -e "\n🎙️ Recording physical microphone..."
    echo "🛑 Press Ctrl+C to STOP recording when the class ends."
    echo "--------------------------------------------------"
    arecord -f S16_LE -c 1 -r 16000 "$AUDIO_FILE_WAV"
  fi
  
  echo -e "\n⚡ Recording stopped. Saving audio..."
  
  if [ -f "$AUDIO_FILE_WAV" ]; then
    echo "📦 Optimizing storage: compressing WAV to MP3 (32kbps mono)..."
    if ffmpeg -y -i "$AUDIO_FILE_WAV" -ac 1 -ar 16000 -ab 32k "$AUDIO_FILE" &>/dev/null; then
      rm "$AUDIO_FILE_WAV"
      echo "✅ Compressed to $(du -h "$AUDIO_FILE" | cut -f1). Original WAV deleted to save space!"
    else
      echo "⚠️  Compression failed. Falling back to raw WAV."
      AUDIO_FILE="$AUDIO_FILE_WAV"
    fi
  fi

  echo -e "\nSelect Transcription Mode:"
  echo "  1) Cloud Mode (FREE, Google TPUs, ~30 seconds)"
  echo "  2) Local Mode (FREE, Offline Whisper CPU, ~6 minutes)"
  read -p "Enter choice [1-2]: " TRANS_CHOICE
  
  if [ "$TRANS_CHOICE" == "2" ]; then
    python3 "$TRANSCRIBER_SCRIPT" "$AUDIO_FILE" --local
  else
    DEFAULT_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"
    echo -e "\n☁️  Cloud transcription model options:"
    echo "  1) Gemini 2.5 Flash (Default) [fast, great for general use]"
    echo "  2) Gemini 2.5 Pro             [smartest, higher limits]"
    echo "  3) Gemini 1.5 Flash           [legacy flash]"
    echo "  4) Custom (Enter name manually)"
    read -p "Choose model [1-4, default 1]: " MODEL_CHOICE
    case "$MODEL_CHOICE" in
      2) export GEMINI_MODEL="gemini-2.5-pro" ;;
      3) export GEMINI_MODEL="gemini-1.5-flash" ;;
      4) read -p "Enter model name: " CUSTOM_MODEL
         if [ -n "$CUSTOM_MODEL" ]; then
           export GEMINI_MODEL="$CUSTOM_MODEL"
         fi
         ;;
      *) export GEMINI_MODEL="$DEFAULT_MODEL" ;;
    esac
    python3 "$TRANSCRIBER_SCRIPT" "$AUDIO_FILE"
  fi
  
  if [ -f "$TXT_FILE" ]; then
    echo -e "\n📝 Structuring notes with Note-Taker..."
    python3 "$NOTE_TAKER_SCRIPT" "$TXT_FILE"
    
    # ── Post-Processing & Storage Organization ──
    FINAL_DOCX="$TARGET_DIR/${SESSION_NAME}.notes.docx"
    FINAL_MD="$TARGET_DIR/${SESSION_NAME}.notes.md"
    
    # Move DOCX to /home/niranjan/Desktop/notes/
    DESKTOP_NOTES_DIR="/home/niranjan/Desktop/notes"
    mkdir -p "$DESKTOP_NOTES_DIR"
    
    if [ -f "$FINAL_DOCX" ]; then
      mv "$FINAL_DOCX" "$DESKTOP_NOTES_DIR/${SESSION_NAME}.docx"
      echo "✅ Moved structured notes to: $DESKTOP_NOTES_DIR/${SESSION_NAME}.docx"
    else
      echo "⚠️  Structured DOCX file not found!"
    fi
    
    # Move recording to /home/niranjan/Desktop/classrecordings/[online/offline]/
    if [ "$MODE_CHOICE" == "1" ]; then
      RECORDING_DEST="/home/niranjan/Desktop/classrecordings/online"
    else
      RECORDING_DEST="/home/niranjan/Desktop/classrecordings/offline"
    fi
    mkdir -p "$RECORDING_DEST"
    
    if [ -f "$AUDIO_FILE" ]; then
      mv "$AUDIO_FILE" "$RECORDING_DEST/${SESSION_NAME}.mp3"
      echo "✅ Moved recording to: $RECORDING_DEST/${SESSION_NAME}.mp3"
    fi
    
    # Delete temporary text and markdown files
    if [ -f "$TXT_FILE" ]; then
      rm "$TXT_FILE"
      echo "🗑️  Deleted temporary transcript file."
    fi
    
    if [ -f "$FINAL_MD" ]; then
      rm "$FINAL_MD"
      echo "🗑️  Deleted temporary markdown notes file."
    fi
    
    # Clean up temporary target directory if it's empty
    if [ -d "$TARGET_DIR" ]; then
      if [ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        rmdir "$TARGET_DIR"
      fi
    fi
    
    echo -e "\n🏆 Pipeline completed successfully!"
    echo "----------------------------------------"
    echo "✍️  Notes:      $DESKTOP_NOTES_DIR/${SESSION_NAME}.docx"
    echo "🔊 Recording:  $RECORDING_DEST/${SESSION_NAME}.mp3"
    echo ""
  else
    echo "❌ Transcription failed. Audio remains saved at: $AUDIO_FILE"
  fi
  exit 0
fi

# ── Command CLI Mode (Arguments Provided) ──────────────────────────────────
case "$1" in
  report)
    if [ -z "$2" ]; then
      echo "❌ Please specify the session directory (e.g. ~/Desktop/notes/session_name)"
      exit 1
    fi
    DIR_PATH=$(realpath "$2")
    if [ ! -d "$DIR_PATH" ]; then
      echo "❌ Directory not found: $DIR_PATH"
      exit 1
    fi
    
    # Collect files for the report
    FILES=()
    while IFS= read -r file; do
      FILES+=("$file")
    done < <(find "$DIR_PATH" -maxdepth 2 -type f \( -name "*.txt" -o -name "*.csv" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.notes.md" \))
    
    if [ ${#FILES[@]} -eq 0 ]; then
      echo "❌ No text, notes, CSV, or images found in $DIR_PATH to compile."
      exit 1
    fi
    
    SESSION_NAME=$(basename "$DIR_PATH")
    OUT_DOCX="$DIR_PATH/${SESSION_NAME}_report.docx"
    
    echo "📊 Compiling Report for session '$SESSION_NAME'..."
    python3 "$REPORT_MAKER_SCRIPT" "$OUT_DOCX" "Class Session Analysis & Notes for $SESSION_NAME" -- "${FILES[@]}"
    
    echo "🎉 Report finished!"
    echo "   📝 Word Doc: $OUT_DOCX"
    echo "   📕 PDF Doc:  ${OUT_DOCX%.docx}.pdf"
    ;;

  record-mic)
    OUT_FILE="${2:-mic_record.wav}"
    echo "🎙️ Recording from Microphone..."
    echo "🛑 Press Ctrl+C to STOP."
    arecord -f S16_LE -c 1 -r 16000 "$OUT_FILE"
    ;;

  record-system)
    OUT_FILE="${2:-system_record.wav}"
    echo "💻 Recording system audio (Zoom) from default monitor output..."
    echo "🛑 Press Ctrl+C to STOP."
    if command -v parecord &> /dev/null; then
      parecord -d @DEFAULT_MONITOR@ "$OUT_FILE"
    elif command -v pw-record &> /dev/null; then
      MONITOR=$(pactl get-default-sink 2>/dev/null).monitor
      if [ -z "$MONITOR" ] || [ "$MONITOR" == ".monitor" ]; then
        pw-record "$OUT_FILE"
      else
        pw-record --target "$MONITOR" "$OUT_FILE"
      fi
    else
      echo "❌  Error: Neither parecord nor pw-record is installed."
      exit 1
    fi
    ;;

  transcribe)
    if [ -z "$2" ]; then
      echo "❌ Please specify the audio file path."
      exit 1
    fi
    python3 "$TRANSCRIBER_SCRIPT" "$2" "$3"
    ;;

  make-notes)
    if [ -z "$2" ]; then
      echo "❌ Please specify the transcript text file path."
      exit 1
    fi
    python3 "$NOTE_TAKER_SCRIPT" "$2" "$3"
    ;;

  compress)
    if [ -z "$2" ]; then
      echo "❌ Please specify a session directory or a WAV file to compress."
      exit 1
    fi
    TARGET=$(realpath "$2")
    if [ -d "$TARGET" ]; then
      # Find WAV files larger than 10MB in the directory and compress them
      echo "🔍 Searching for large WAV files in $TARGET..."
      find "$TARGET" -type f -name "*.wav" -size +10M | while read -r wav_file; do
        mp3_file="${wav_file%.wav}.mp3"
        echo "⚡ Compressing $(basename "$wav_file") ($(du -h "$wav_file" | cut -f1)) to mono MP3..."
        if ffmpeg -y -i "$wav_file" -ac 1 -ar 16000 -ab 32k "$mp3_file" &>/dev/null; then
          rm "$wav_file"
          echo "✅ Compressed to $(du -h "$mp3_file" | cut -f1). Original WAV deleted!"
        else
          echo "❌ Failed to compress $(basename "$wav_file")"
        fi
      done
    elif [ -f "$TARGET" ] && [[ "$TARGET" == *.wav ]]; then
      mp3_file="${TARGET%.wav}.mp3"
      echo "⚡ Compressing $(basename "$TARGET") to mono MP3..."
      if ffmpeg -y -i "$TARGET" -ac 1 -ar 16000 -ab 32k "$mp3_file" &>/dev/null; then
        rm "$TARGET"
        echo "✅ Compressed to $(du -h "$mp3_file" | cut -f1). Original WAV deleted!"
      else
        echo "❌ Failed to compress $(basename "$TARGET")"
      fi
    else
      echo "❌ Invalid target. Must be a directory or a WAV file."
    fi
    ;;

  *)
    show_help
    exit 1
    ;;
esac

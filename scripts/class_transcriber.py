#!/usr/bin/env python3
"""
class_transcriber.py
Transcribes class audio files using local CPU-optimized Whisper or cloud-based Gemini.
"""

import sys
import os
import re
from pathlib import Path

def transcribe_whisper(audio_path: Path, model_size: str = "base") -> str:
    from faster_whisper import WhisperModel
    print(f"📦 Loading local Whisper model ({model_size}) on CPU...")
    # Run on CPU with int8 quantization for speed & low memory footprint
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    print("⚡ Transcribing audio file (offline mode)...")
    
    segments, info = model.transcribe(str(audio_path), beam_size=5)
    
    transcript = []
    for segment in segments:
        # Print progress inline
        timestamp = f"[{int(segment.start // 60):02d}:{int(segment.start % 60):02d}]"
        print(f"  {timestamp} {segment.text}")
        transcript.append(segment.text)
        
    return " ".join(transcript)

def compress_audio(audio_path: Path) -> Path:
    import subprocess
    # Compress large WAV files to 32kbps mono MP3 using ffmpeg to speed up uploads
    if audio_path.suffix.lower() == '.wav' and audio_path.stat().st_size > 10 * 1024 * 1024:
        compressed_path = audio_path.with_suffix('.mp3')
        if compressed_path.exists():
            print(f"🎵 Found existing compressed audio: {compressed_path.name}")
            return compressed_path
            
        print(f"⚡ Compressing large WAV file ({audio_path.stat().st_size / (1024*1024):.1f} MB) to mono MP3 to speed up upload...")
        try:
            subprocess.run([
                'ffmpeg', '-y', '-i', str(audio_path),
                '-ac', '1', '-ar', '16000', '-ab', '32k',
                str(compressed_path)
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            print(f"✅ Compression complete. New size: {compressed_path.stat().st_size / (1024*1024):.1f} MB")
            return compressed_path
        except Exception as e:
            print(f"⚠️ Compression failed ({e}). Proceeding with original WAV file.")
            return audio_path
    return audio_path

def transcribe_gemini(audio_path: Path) -> str:
    import time
    from google import genai
    from google.genai.errors import APIError
    
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        sys.exit("❌  GEMINI_API_KEY environment variable is not set. Please set it or run with --local.")
        
    client = genai.Client(api_key=api_key)
    
    # Compress audio if needed before upload
    audio_path_to_upload = compress_audio(audio_path)
    
    print("☁️  Uploading audio to Gemini (Free Tier)...")
    
    max_retries = 5
    backoff = 2.0
    
    audio_file = None
    delay = 2.0
    for attempt in range(max_retries):
        try:
            audio_file = client.files.upload(file=str(audio_path_to_upload))
            break
        except APIError as e:
            code = getattr(e, "code", None)
            is_transient = code in (429, 503) or any(err_str in str(e) for err_str in ("503", "429", "UNAVAILABLE", "Resource Exhausted", "RESOURCE_EXHAUSTED"))
            if is_transient and attempt < max_retries - 1:
                print(f"⚠️  Gemini upload temporary error ({code or '503/429'}). Retrying in {delay:.1f} seconds (attempt {attempt + 1}/{max_retries})...")
                time.sleep(delay)
                delay *= backoff
            else:
                raise
                
    model_name = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
    print(f"⚡ Transcribing with {model_name} on Google Cloud TPUs...")
    delay = 2.0
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=[
                    audio_file,
                    "Please transcribe this audio file word-for-word. Do not summarize or add markdown formatting."
                ]
            )
            return response.text
        except APIError as e:
            code = getattr(e, "code", None)
            is_transient = code in (429, 503) or any(err_str in str(e) for err_str in ("503", "429", "UNAVAILABLE", "Resource Exhausted", "RESOURCE_EXHAUSTED"))
            if is_transient and attempt < max_retries - 1:
                print(f"⚠️  Gemini API temporary error ({code or '503/429'}). Retrying in {delay:.1f} seconds (attempt {attempt + 1}/{max_retries})...")
                time.sleep(delay)
                delay *= backoff
            else:
                raise

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python class_transcriber.py <audio_path> [--local]")
        sys.exit(1)
        
    audio = Path(sys.argv[1])
    use_local = "--local" in sys.argv
    
    if not audio.exists():
        sys.exit(f"❌  Audio file not found: {audio}")
        
    if use_local:
        text = transcribe_whisper(audio)
    else:
        text = transcribe_gemini(audio)
        
    out_text_path = audio.with_suffix(".txt")
    out_text_path.write_text(text, encoding="utf-8")
    print(f"\n✅  Transcription completed and saved → {out_text_path}")

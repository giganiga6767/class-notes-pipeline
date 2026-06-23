#!/usr/bin/env bash
# setup.sh
# Installation and environment checks for the Class Notes Pipeline.

echo "🎓 Setting up Class Notes Pipeline..."
echo "--------------------------------------"

# 1. Check Python
if ! command -v python3 &>/dev/null; then
  echo "❌ Error: python3 is not installed. Please install it first."
  exit 1
fi

# 2. Check FFmpeg
if ! command -v ffmpeg &>/dev/null; then
  echo "⚠️  Warning: ffmpeg is not installed. Audio compression will not work."
  echo "   Please install it using: sudo apt install ffmpeg"
else
  echo "✅ ffmpeg is installed."
fi

# 3. Install Python Dependencies
echo "📦 Installing Python dependencies from requirements.txt..."
if python3 -m pip install -r requirements.txt --break-system-packages; then
  echo "✅ Python dependencies installed successfully."
else
  echo "❌ Error: Failed to install Python dependencies."
  exit 1
fi

# 4. Check GEMINI_API_KEY
if [ -z "$GEMINI_API_KEY" ]; then
  echo -e "\n🔑 GEMINI_API_KEY is not set in your current shell session."
  read -p "Would you like to save your API Key to ~/.bashrc? (y/n): " SAVE_KEY
  if [[ "$SAVE_KEY" =~ ^[Yy]$ ]]; then
    read -sp "Enter your Google Gemini API Key: " API_KEY
    echo ""
    if [ -n "$API_KEY" ]; then
      echo "export GEMINI_API_KEY=\"$API_KEY\"" >> ~/.bashrc
      echo "✅ API Key added to ~/.bashrc. Please restart your terminal or run: source ~/.bashrc"
    fi
  fi
else
  echo "✅ GEMINI_API_KEY is already configured in the environment."
fi

echo -e "\n🎉 Setup completed!"
echo "To start recording your classes, run:"
echo "   bash class_notes.sh"
echo ""

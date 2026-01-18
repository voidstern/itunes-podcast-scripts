#!/bin/bash

# ==============================================================================
# MP3 Artwork Embedder (Single File Mode)
# Features:
#   - Takes a specific file path as input
#   - Checks that file's parent folder for 'cover.png'
#   - Embeds only if the cover exists alongside the file
# ==============================================================================

# --- Colors ---
if [[ -t 1 ]]; then
	RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; CYAN=""; BOLD=""; RESET=""
fi

# 1. Input Validation
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_mp3_file>"
    exit 1
fi

MP3_FILE="$1"

if [ ! -f "$MP3_FILE" ]; then
    echo "❌ Error: File not found: $MP3_FILE"
    exit 1
fi

# 2. Locate FFmpeg
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FFMPEG_BIN=""

if command -v ffmpeg &> /dev/null; then
    FFMPEG_BIN="ffmpeg"
elif [ -x "$SCRIPT_DIR/ffmpeg" ]; then
    FFMPEG_BIN="$SCRIPT_DIR/ffmpeg"
else
    echo "❌ Error: ffmpeg not found."
    exit 1
fi

# 3. Context Check
# Get the folder where the MP3 lives
FILE_DIR=$(dirname "$MP3_FILE")
FILENAME=$(basename "$MP3_FILE")
COVER_FILE="$FILE_DIR/cover.png"

# Check if cover exists in that specific folder
if [ ! -f "$COVER_FILE" ]; then
    echo "⚠️  No 'cover.png' found in $(basename "$FILE_DIR"). Skipping."
    exit 0
fi

# 4. Process the file

TEMP_FILE="$FILE_DIR/temp_$FILENAME"

# EXECUTE FFMPEG
"$FFMPEG_BIN" -y -i "$MP3_FILE" -i "$COVER_FILE" \
    -map 0:0 -map 1:0 -c copy -id3v2_version 3 \
    -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
    "$TEMP_FILE" > /dev/null 2>&1

# Verify success
if [ -f "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$MP3_FILE"
      echo "   ✓ Coverart embedded for $MP3_FILE."
else
    echo "   ❌ Failed to process file $MP3_FILE."
    exit 1
fi
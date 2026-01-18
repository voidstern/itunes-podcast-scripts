#!/bin/bash

# --- FFMPEG DETECTION LOGIC ---

# 1. Get the directory where this script is physically located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Check for ffmpeg in system PATH, then fallback to local folder
if command -v ffmpeg &> /dev/null; then
    FFMPEG_CMD="ffmpeg"
elif [ -x "$SCRIPT_DIR/ffmpeg" ]; then
    FFMPEG_CMD="$SCRIPT_DIR/ffmpeg"
    # echo "Using local ffmpeg binary..." # Uncomment to see when it uses the local file
else
    echo "CRITICAL ERROR: ffmpeg not found."
    echo "1. It is not in your system PATH."
    echo "2. A valid binary named 'ffmpeg' was not found in: $SCRIPT_DIR"
    exit 1
fi

# --- FILE PROCESSING LOGIC ---

# Check if a file was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILE="$1"

# Check if file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' not found."
  exit 1
fi

EXT="${FILE##*.}"
BASENAME="${FILE%.*}"
TEMP_FILE="${BASENAME}_clean.${EXT}"

# Execute using the detected command variable "$FFMPEG_CMD"
"$FFMPEG_CMD" -i "$FILE" -map 0 -c copy \
  -metadata comment="" \
  -metadata lyrics="" \
  -metadata description="" \
  -metadata synopsis="" \
  -metadata longdesc="" \
  -metadata purl="" \
  -metadata copyright="" \
  -metadata encoder="" \
  -loglevel error \
  "$TEMP_FILE"

# Verify success
if [ $? -eq 0 ]; then
  mv "$TEMP_FILE" "$FILE"
  echo "   ${GREEN}✓ Metadata cleaned up for $FILE.${RESET}"
else
  echo "Error processing file."
  # Remove the temp file if it was created but failed
  [ -f "$TEMP_FILE" ] && rm "$TEMP_FILE"
  exit 1
fi
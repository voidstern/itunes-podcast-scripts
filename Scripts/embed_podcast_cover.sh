#!/bin/bash

# ==============================================================================
# MP3 Artwork Embedder (Portable Mode)
# Features:
#   - Checks system PATH for ffmpeg
#   - Fallback: Checks for local 'ffmpeg' binary in script folder
#   - Embeds cover.png into all mp3s in target folder
# ==============================================================================

# 1. Input Validation
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_folder>"
    exit 1
fi

TARGET_DIR="$1"
# Remove trailing slash
TARGET_DIR="${TARGET_DIR%/}"
COVER_FILE="$TARGET_DIR/cover.png"

# 2. Locate FFmpeg
# Get the directory where this script is actually saved
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FFMPEG_BIN=""

# Check System PATH
if command -v ffmpeg &> /dev/null; then
    FFMPEG_BIN="ffmpeg"
# Check Local Script Folder
elif [ -x "$SCRIPT_DIR/ffmpeg" ]; then
    FFMPEG_BIN="$SCRIPT_DIR/ffmpeg"
    echo "⚠️  System ffmpeg not found. Using local binary: $FFMPEG_BIN"
else
    echo "❌ Error: ffmpeg not found."
    echo "   Ensure 'ffmpeg' is installed or place the binary in: $SCRIPT_DIR"
    exit 1
fi

echo "📂 Target Folder: $(basename "$TARGET_DIR")"

# 3. Check for cover.png
if [ ! -f "$COVER_FILE" ]; then
    echo "❌ Error: 'cover.png' not found in this folder. Skipping."
    exit 0
fi

# 4. Process all MP3 files
MP3_COUNT=$(find "$TARGET_DIR" -maxdepth 1 -iname "*.mp3" | wc -l)

if [ "$MP3_COUNT" -eq 0 ]; then
    echo "⚠️  No MP3 files found in this folder."
    exit 0
fi

echo "✅ Found cover.png. Processing $MP3_COUNT file(s)..."

# Loop safely through files handling spaces
find "$TARGET_DIR" -maxdepth 1 -iname "*.mp3" -print0 | while IFS= read -r -d '' mp3_file; do
    filename=$(basename "$mp3_file")
    temp_file="$TARGET_DIR/temp_$filename"

    echo "   🔄 Embedding into: $filename..."

    # EXECUTE FFMPEG using the variable we set earlier
    "$FFMPEG_BIN" -y -i "$mp3_file" -i "$COVER_FILE" \
        -map 0:0 -map 1:0 -c copy -id3v2_version 3 \
        -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
        "$temp_file" > /dev/null 2>&1

    # Verify success
    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$mp3_file"
        echo "   ✅ Done."
    else
        echo "   ❌ Failed to process: $filename"
    fi
done

echo "---------------------------------------------------"
echo "✨ Artwork embedding complete."
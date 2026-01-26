#!/bin/bash

# ==============================================================================
# Configuration
# ==============================================================================

# 1. Determine the directory where this script resides
# This allows you to call this script from anywhere (e.g., /usr/local/bin) 
# and it will still find the AppleScript next to it.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APPLE_SCRIPT_NAME="update_station.scpt"
APPLE_SCRIPT_PATH="$SCRIPT_DIR/../Apple Scripts/$APPLE_SCRIPT_NAME"

# 2. Set Input Folder
# Priority: Command Line Argument > Hardcoded Default > Current Directory
DEFAULT_FOLDER="$HOME/Music/Stations"

if [ ! -z "$1" ]; then
    INPUT_FOLDER="$1"
else
    INPUT_FOLDER="$DEFAULT_FOLDER"
fi

# ==============================================================================
# Validation
# ==============================================================================

# Check if AppleScript exists
if [ ! -f "$APPLE_SCRIPT_PATH" ]; then
    echo "Error: AppleScript not found."
    echo "Expected at: $APPLE_SCRIPT_PATH"
    echo "Please ensure '$APPLE_SCRIPT_NAME' is in the same folder as this bash script."
    exit 1
fi

# Check if Input Folder exists
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "Error: Input directory does not exist: $INPUT_FOLDER"
    echo "Usage: $(basename "$0") [optional_path_to_txt_files]"
    exit 1
fi

# ==============================================================================
# Processing
# ==============================================================================

echo "Scanning for lists in: $INPUT_FOLDER"
echo "-----------------------------------"

# Enable nullglob so the loop doesn't run if no .txt files exist
shopt -s nullglob

# Loop through all text files in the folder
for file in "$INPUT_FOLDER"/*.txt; do
    
    # Get the Playlist Name from filename (remove extension and path)
    filename=$(basename -- "$file")
    playlist_name="${filename%.*}"
    
    echo "Processing Playlist: $playlist_name"
    
    # Read content preserving the user's manual order
    # Format: "Name",Count
    file_content=$(cat "$file")
    
    # Call AppleScript
    # We pass the Playlist Name and the full CSV blob as arguments
    osascript "$APPLE_SCRIPT_PATH" "$playlist_name" "$file_content"
    
    echo "Done."
    echo "-----------------------------------"
done

echo "All tasks completed."
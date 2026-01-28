#!/bin/bash

# ==============================================================================
# Configuration
# ==============================================================================

# 1. Determine the directory where this script resides
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APPLE_SCRIPT_NAME="update_station.scpt"
APPLE_SCRIPT_PATH="$SCRIPT_DIR/../Apple Scripts/$APPLE_SCRIPT_NAME"

# 2. Set Default Input Folder
DEFAULT_FOLDER="$HOME/Music/Stations"
INPUT_FOLDER="$DEFAULT_FOLDER"
TARGET_STATION=""

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RESET=""
fi

# ==============================================================================
# Argument Parsing
# ==============================================================================

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -s|--station)
        TARGET_STATION="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option, assume it is the input path
        POSITIONAL_ARGS+=("$1")
        shift # past argument
        ;;
    esac
done

# Restore positional parameters (the input folder, if provided)
set -- "${POSITIONAL_ARGS[@]}"

if [ ! -z "$1" ]; then
    INPUT_FOLDER="$1"
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
    echo "Usage: $(basename "$0") [-s StationName] [optional_path_to_txt_files]"
    exit 1
fi

# ==============================================================================
# Processing
# ==============================================================================

FILES_TO_PROCESS=()

if [ ! -z "$TARGET_STATION" ]; then
    # Handle specific station request
    # Append .txt if the user didn't supply it
    if [[ "$TARGET_STATION" != *.txt ]]; then
        TARGET_FILE="$INPUT_FOLDER/$TARGET_STATION.txt"
    else
        TARGET_FILE="$INPUT_FOLDER/$TARGET_STATION"
    fi

    if [ -f "$TARGET_FILE" ]; then
        FILES_TO_PROCESS+=("$TARGET_FILE")
    else
        echo "Error: Station file not found: $TARGET_FILE"
        exit 1
    fi
else
    # Enable nullglob so the wildcard doesn't return literal string if no match
    shopt -s nullglob
    for f in "$INPUT_FOLDER"/*.txt; do
        FILES_TO_PROCESS+=("$f")
    done
fi

# Check if we have anything to process
if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
    echo "No station files found to process."
    exit 0
fi

# Loop through the determined list of files
for file in "${FILES_TO_PROCESS[@]}"; do
    
    # Get the Playlist Name from filename (remove extension and path)
    filename=$(basename -- "$file")
    playlist_name="${filename%.*}"
    
    # Read content preserving the user's manual order
    file_content=$(cat "$file")
    
    # Call AppleScript
    # We pass the Playlist Name and the full CSV blob as arguments
    osascript "$APPLE_SCRIPT_PATH" "$playlist_name" "$file_content"

    echo "   ✓ Updated $playlist_name"
done


echo "   ${GREEN}✓ Stations updated.${RESET}"
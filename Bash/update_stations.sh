#!/bin/bash

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APPLE_SCRIPT_NAME="update_station.scpt"
APPLE_SCRIPT_PATH="$SCRIPT_DIR/../Apple Scripts/$APPLE_SCRIPT_NAME"

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
    case "$1" in
        -s|--station)
        TARGET_STATION="$2"
        shift 2
        ;;
        *)
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"
if [ ! -z "$1" ]; then
    INPUT_FOLDER="$1"
fi

# ==============================================================================
# Validation
# ==============================================================================

if [ ! -f "$APPLE_SCRIPT_PATH" ]; then
    echo "${RED}Error: AppleScript not found at:${RESET} $APPLE_SCRIPT_PATH"
    exit 1
fi

if [ ! -d "$INPUT_FOLDER" ]; then
    echo "${RED}Error: Input directory does not exist:${RESET} $INPUT_FOLDER"
    exit 1
fi

# ==============================================================================
# Processing
# ==============================================================================

FILES_TO_PROCESS=()
if [ ! -z "$TARGET_STATION" ]; then
    [[ "$TARGET_STATION" != *.txt ]] && TARGET_FILE="$INPUT_FOLDER/$TARGET_STATION.txt" || TARGET_FILE="$INPUT_FOLDER/$TARGET_STATION"
    
    if [ -f "$TARGET_FILE" ]; then
        FILES_TO_PROCESS+=("$TARGET_FILE")
    else
        echo "${RED}Error: Station file not found:${RESET} $TARGET_FILE"
        exit 1
    fi
else
    shopt -s nullglob
    for f in "$INPUT_FOLDER"/*.txt; do
        FILES_TO_PROCESS+=("$f")
    done
fi

if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
    echo "No station files found in $INPUT_FOLDER"
    exit 0
fi

for file in "${FILES_TO_PROCESS[@]}"; do
    filename=$(basename -- "$file")
    playlist_name="${filename%.*}"

	echo "${BLUE}→ Processing:${RESET} $playlist_name"
	
    # FIX: Use a heredoc or quoted variable to prevent shell expansion issues
    # and ensure osascript receives the content as a clean UTF-8 string.
    if osascript "$APPLE_SCRIPT_PATH" "$playlist_name" "$(cat "$file")"; then
        echo "   ${GREEN}✓ Updated $playlist_name${RESET}"
    else
        echo "   ${RED}✗ Failed to update $playlist_name${RESET}"
    fi
done

echo -e "\n${BOLD}${GREEN}All stations processed.${RESET}"
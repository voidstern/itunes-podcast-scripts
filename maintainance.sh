#!/usr/bin/env bash

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BOLD=""; RESET=""
fi

# 1. Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Argument Parsing ---
REFRESH_PODCASTS=false
SKIP_ITUNES=false
SKIP_FILES=false

for arg in "$@"; do
  case $arg in
    --refresh-podcasts)
      REFRESH_PODCASTS=true
      shift # Remove --refresh-podcasts from processing
      ;;
    --skip-itunes)
      SKIP_ITUNES=true
      shift # Remove --skip-itunes from processing
      ;;
    --skip-files)
      SKIP_FILES=true
      shift # Remove --skip-files from processing
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# --- Main Logic ---

# Only run the update and sleep if the flag was provided
if [ "$REFRESH_PODCASTS" = true ]; then
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Update flag detected. Refreshing podcasts..."
  echo
  
  # Update All Podcasts - there is no real status unfortunately
  osascript "$SCRIPT_DIR/Apple Scripts/update_podcasts.scpt"

  # Update All Podcasts - there is no real status unfortunately, assume that 60 seconds are enough
  "$SCRIPT_DIR/Bash/sleep.sh" -t 60
else
  echo "${BOLD}${YELLOW}[iTunes]${RESET} Skipping podcast refresh (use --refresh-podcasts to enable)."
fi


# Check if we should skip the file operations
if [ "$SKIP_FILES" = false ]; then

  # Download any missing cover art files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Loading required podcast cover artwork..."
  echo
  "$SCRIPT_DIR/Bash/get_podcast_cover.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

  # Adjust all newly added files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Adjusting audio files..."
  echo
  "$SCRIPT_DIR/Bash/adjust_folder.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

  # Remove markers of deleted files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Cleaning orphaned markers..."
  echo
  "$SCRIPT_DIR/Bash/cleanup_markers.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

else
  echo
  echo "${BOLD}${YELLOW}[Files]${RESET} Skipping file maintenance scripts (requested via --skip-files)."
  echo
fi


# Check if we should skip the final iTunes operations
if [ "$SKIP_ITUNES" = false ]; then

  # Refresh the duration in all podcasts added in the last 24hr - this assumes this script is run daily.
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing durations in iTunes..."
  echo
  osascript "$SCRIPT_DIR/Apple Scripts/refresh_latest.scpt"

  # Mark Episodes in the "Deletable" playlist as played
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Marking deletable episodes as played..."
  echo
  osascript "$SCRIPT_DIR/Apple Scripts/mark_played.scpt"

  # Update the stared books playlist
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started audiobooks..."
  echo
  osascript "$SCRIPT_DIR/Apple Scripts/started_books.scpt"

  # Update the started podcasts playlist
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started podcasts..."
  echo
  osascript "$SCRIPT_DIR/Apple Scripts/started_podcasts.scpt"

else
  echo
  echo "${BOLD}${YELLOW}[iTunes]${RESET} Skipping iTunes maintenance scripts (requested via --skip-itunes)."
fi
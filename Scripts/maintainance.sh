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

for arg in "$@"; do
  case $arg in
    --refresh-podcasts)
      REFRESH_PODCASTS=true
      shift # Remove --refresh-podcasts from processing
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
  
  # Update All Podcasts - there is no real status unfortunately
  osascript "$SCRIPT_DIR/Apple Scripts/update_podcasts.scpt"

  # Update All Podcasts - there is no real status unfortunately, assume that 60 seconds are enough
  "$SCRIPT_DIR/Bash/sleep.sh" -t 60
else
  echo "${BOLD}${YELLOW}[iTunes]${RESET} Skipping podcast refresh (use --refresh-podcasts to enable)."
fi



# Download any missing cover art files
echo
echo "${BOLD}${CYAN}[Files]${RESET} Loading required podcast cover artwork..."
"$SCRIPT_DIR/Bash/get_podcast_cover.sh" "$SCRIPT_DIR/../iTunes Media/Podcasts/"

# Adjust all newly added files
echo
echo "${BOLD}${CYAN}[Files]${RESET} Adjusting audio files..."
"$SCRIPT_DIR/Bash/adjust_folder.sh" "$SCRIPT_DIR/../iTunes Media/Podcasts/"

# Remove markers of deleted files
echo
echo "${BOLD}${CYAN}[Files]${RESET} Adjusting audio files..."
"$SCRIPT_DIR/Bash/cleanup_markers.sh" "$SCRIPT_DIR/../iTunes Media/Podcasts/"



# Refresh the duration in all podcasts added in the last 24hr - this assumes this script is run daily.
echo
echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing durations in iTunes..."
osascript "$SCRIPT_DIR/Apple Scripts/refresh_latest.scpt"

# Mark Episodes in the "Deletable" playlist as played
echo
echo "${BOLD}${CYAN}[iTunes]${RESET} Marking deletable episodes as played..."
osascript "$SCRIPT_DIR/Apple Scripts/mark_played.scpt"

# Update the stared books playlist
echo
echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started audiobooks..."
osascript "$SCRIPT_DIR/Apple Scripts/started_books.scpt"

# Update the started podcasts playlist
echo
echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started podcasts..."
osascript "$SCRIPT_DIR/Apple Scripts/started_podcasts.scpt"
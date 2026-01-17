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
  echo "${BOLD}${CYAN}[Podcasts]${RESET} Update flag detected. Refreshing podcasts..."
  
  # Update All Podcasts - there is no real status unfortunately
  "$SCRIPT_DIR/update_podcasts.sh"

  # Update All Podcasts - there is no real status unfortunately, assume that 60 seconds are enough
  "$SCRIPT_DIR/sleep.sh" -t 60
else
  echo "${BOLD}${YELLOW}[Podcasts]${RESET} Skipping podcast refresh (use --refresh-podcasts to enable)."
fi

# Speed up all required files
"$SCRIPT_DIR/speedup.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

# Download any missing cover art files
"$SCRIPT_DIR/get_podcast_cover.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

# Refresh the duration in all podcasts added in the last 24hr - this assumes this script is run daily.
echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing durations in iTunes..."
osascript "$SCRIPT_DIR/refresh_latest.scpt"

# Mark Episodes in the "Deletable" playlist as played
echo "${BOLD}${CYAN}[iTunes]${RESET} Marking deletable episodes as played..."
osascript "$SCRIPT_DIR/mark_played.scpt"

# Mark Episodes in the "Deletable" playlist as played
echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started audiobooks..."
osascript "$SCRIPT_DIR/started_books.scpt"

# Mark Episodes in the "Deletable" playlist as played
echo "${BOLD}${CYAN}[iTunes]${RESET} Updating remote podcasts..."
osascript "$SCRIPT_DIR/remote_podcasts.scpt"


# Restart iTunes - this updates all smart playlists that are set to NOT live update
# osascript Scripts/restart_itunes.scpt
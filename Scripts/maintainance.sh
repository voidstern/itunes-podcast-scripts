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

# Update All Podcasts - there is no real status unfortunately
"$SCRIPT_DIR/update_podcasts.sh"

# Update All Podcasts - there is no real status unfortunately, assume that 30 minutes are enough
"$SCRIPT_DIR/sleep.sh" -t 45

# Speed up all required files
"$SCRIPT_DIR/speedup.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"

# Refresh the duration in all podcasts added in the last 24hr - this assumes this script is run daily.

echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing durations in iTunes..."
osascript "$SCRIPT_DIR/refresh_latest.scpt"

# Mark Episodes in the "Deletable" playlist as played
echo "${BOLD}${CYAN}[iTunes]${RESET} Marking deletable Episodes as played..."
osascript "$SCRIPT_DIR/mark_played.scpt"

# Restart iTunes - this updates all smart playlists that are set to NOT live update
# osascript Scripts/restart_itunes.scpt

# Exit this terminal - Run this script as a cronjob in a new terminal window to see progress via
exit

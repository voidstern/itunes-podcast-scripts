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
LOAD_COVERS=false
ADJUST_FILES=false
CLEANUP_MARKERS=false
REFRESH_DURATIONS=false
MARK_PLAYED=false
STARTED_BOOKS=false
LOVE_RATINGS=false
RESET_GROUPINGS=false
UPDATE_STATIONS=false
STARTED_PODCASTS=false
SYNC_IPODS=false
RUN_ANY=false
HOURS=""

show_help() {
  echo "Usage: $(basename "$0") [STEPS] [OPTIONS]"
  echo ""
  echo "Steps:"
  echo "  -r  Refresh podcasts in iTunes"
  echo "  -c  Load missing podcast cover artwork"
  echo "  -a  Adjust audio files"
  echo "  -m  Clean orphaned markers"
  echo "  -d  Refresh recent podcast durations in iTunes"
  echo "  -p  Mark deletable episodes as played"
  echo "  -b  Update started audiobooks"
  echo "  -l  Sync loved status and ratings"
  echo "  -g  Reset podcast groupings"
  echo "  -s  Update podcast station playlists"
  echo "  -e  Update started podcasts"
  echo "  -i  Sync connected iPods"
  echo ""
  echo "Options:"
  echo "      --hours INT  Set the number of hours to check for recent podcasts"
  echo "  -h, --help       Show this help message"
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -r)
      REFRESH_PODCASTS=true
      RUN_ANY=true
      shift
      ;;
    -c)
      LOAD_COVERS=true
      RUN_ANY=true
      shift
      ;;
    -a)
      ADJUST_FILES=true
      RUN_ANY=true
      shift
      ;;
    -m)
      CLEANUP_MARKERS=true
      RUN_ANY=true
      shift
      ;;
    -d)
      REFRESH_DURATIONS=true
      RUN_ANY=true
      shift
      ;;
    -p)
      MARK_PLAYED=true
      RUN_ANY=true
      shift
      ;;
    -b)
      STARTED_BOOKS=true
      RUN_ANY=true
      shift
      ;;
    -l)
      LOVE_RATINGS=true
      RUN_ANY=true
      shift
      ;;
    -g)
      RESET_GROUPINGS=true
      RUN_ANY=true
      shift
      ;;
    -s)
      UPDATE_STATIONS=true
      RUN_ANY=true
      shift
      ;;
    -e)
      STARTED_PODCASTS=true
      RUN_ANY=true
      shift
      ;;
    -i)
      SYNC_IPODS=true
      RUN_ANY=true
      shift
      ;;
    --hours)
      HOURS="$2"
      shift 2
      ;;
    *)
      echo "${RED}Unknown option:${RESET} $1"
      show_help
      exit 1
      ;;
  esac
done

# --- Main Logic ---

if [ "$RUN_ANY" = false ]; then
  show_help
  exit 0
fi

if [ "$REFRESH_PODCASTS" = true ]; then
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing podcasts..."
  
  # Update All Podcasts - there is no real status unfortunately
  osascript "$SCRIPT_DIR/Apple Scripts/update_podcasts.scpt"

  # Update All Podcasts - there is no real status unfortunately, assume that 60 seconds are enough
  "$SCRIPT_DIR/Bash/sleep.sh" -t 15
fi

if [ "$LOAD_COVERS" = true ]; then
  # Download any missing cover art files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Loading required podcast cover artwork..."
  "$SCRIPT_DIR/Bash/get_podcast_cover.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"
fi

if [ "$ADJUST_FILES" = true ]; then
  # Adjust all newly added files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Adjusting audio files..."
  "$SCRIPT_DIR/Bash/adjust_folder.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"
fi

if [ "$CLEANUP_MARKERS" = true ]; then
  # Remove markers of deleted files
  echo
  echo "${BOLD}${CYAN}[Files]${RESET} Cleaning orphaned markers..."
  "$SCRIPT_DIR/Bash/cleanup_markers.sh" "$SCRIPT_DIR/../iTunes/iTunes Media/Podcasts/"
fi

if [ "$REFRESH_DURATIONS" = true ]; then
  # Refresh the duration in all podcasts added in the last 24hr - this assumes this script is run daily.
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Refreshing durations in iTunes..."
  if [ -n "$HOURS" ]; then
    osascript "$SCRIPT_DIR/Apple Scripts/refresh_latest.scpt" "$HOURS"
  else
    osascript "$SCRIPT_DIR/Apple Scripts/refresh_latest.scpt"
  fi
fi

if [ "$MARK_PLAYED" = true ]; then
  # Mark Episodes in the "Deletable" playlist as played
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Marking deletable episodes as played..."
  osascript "$SCRIPT_DIR/Apple Scripts/mark_played.scpt"
fi

if [ "$STARTED_BOOKS" = true ]; then
  # Update the stared books playlist
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started audiobooks..."
  osascript "$SCRIPT_DIR/Apple Scripts/started_books.scpt"
fi

if [ "$LOVE_RATINGS" = true ]; then
  # Update loved status and ratings (since the iPod classic doesn't know "Loved")
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Syncing loved status and ratings..."
  osascript "$SCRIPT_DIR/Apple Scripts/love_five_stars.scpt"
fi

if [ "$RESET_GROUPINGS" = true ]; then
  # Reset podcast groupings before rebuilding station and started groupings
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Resetting podcast groupings..."
  osascript "$SCRIPT_DIR/Apple Scripts/clear_podcast_groupings.scpt"
fi

if [ "$UPDATE_STATIONS" = true ]; then
  # Update podcast station playlists
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Updating podcast station playlists..."
  "$SCRIPT_DIR/Bash/update_stations.sh"
fi

if [ "$STARTED_PODCASTS" = true ]; then
  # Update the started podcasts playlist
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Updating started podcasts..."
  osascript "$SCRIPT_DIR/Apple Scripts/started_podcasts.scpt"
fi

if [ "$SYNC_IPODS" = true ]; then
  # Sync all connected iPods
  echo
  echo "${BOLD}${CYAN}[iTunes]${RESET} Syncing connected iPods..."
  osascript "$SCRIPT_DIR/Apple Scripts/update_ipods.scpt"
fi

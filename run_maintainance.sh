#!/usr/bin/env bash

# Resolve the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/maintainance.sh"

# Function to display help
show_help() {
  echo "Usage: $(basename "$0") [OPTIONS] [MODE]"
  echo ""
  echo "Modes (one required):"
  echo "  -t, --itunes             Run maintenance on iTunes only"
  echo "  -f, --files              Run maintenance on Files only"
  echo "  -a, --all                Run maintenance on everything (force refresh podcasts)"
  echo ""
  echo "Options:"
  echo "  -r, --refresh-podcasts   Refresh podcasts (flag forwarded to maintenance script)"
  echo "  -w, --window             Run in new terminal window (default: runs inline)"
  echo "  -k, --keep-open          Do not close the new terminal window after completion (only applies with -w)"
  echo "      --recent-only        Skip daily/global cleanup steps for a lighter recent podcast pass"
  echo "      --hours INT          Set the number of hours to check for recent podcasts (passed to refresh_latest.scpt)"
  echo "  -h, --help               Show this help message"
  echo ""
}

# 1. Check if no arguments provided
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Initialize variables
OPEN_NEW_WINDOW=false
REFRESH_PODCAST=false
MODE_SELECTED=false
SKIP_FILES=false
SKIP_ITUNES=false
KEEP_OPEN=false
RECENT_ONLY=false
HOURS=""

# 2. Parse Arguments
for arg in "$@"; do
  case $arg in
    -h|--help)
      show_help
      exit 0
      ;;
    -w|--window)
      OPEN_NEW_WINDOW=true
      shift
      ;;
    -k|--keep-open)
      KEEP_OPEN=true
      shift
      ;;
    --recent-only)
      RECENT_ONLY=true
      shift
      ;;
    --hours)
      HOURS="$2"
      shift 2
      ;;
    -r|--refresh-podcast|--refresh-podcasts)
      REFRESH_PODCAST=true
      shift
      ;;
    -t|--itunes)
      SKIP_FILES=true
      MODE_SELECTED=true
      shift
      ;;
    -f|--files)
      SKIP_ITUNES=true
      MODE_SELECTED=true
      shift
      ;;
    -a|--all)
      # --all means NO skips, but force refresh-podcast
      SKIP_FILES=false
      SKIP_ITUNES=false
      REFRESH_PODCAST=true
      MODE_SELECTED=true
      shift
      ;;
    *)
      # Shift unknown args
      shift
      ;;
  esac
done

# 3. Require Mode Selection
if [ "$MODE_SELECTED" = false ]; then
  echo "Error: No mode selected."
  show_help
  exit 1
fi

# 4. Build the flags for the target script
CMD_FLAGS=""

if [ "$SKIP_FILES" = true ]; then
  CMD_FLAGS="$CMD_FLAGS --skip-files"
fi

if [ "$SKIP_ITUNES" = true ]; then
  CMD_FLAGS="$CMD_FLAGS --skip-itunes"
fi

if [ "$REFRESH_PODCAST" = true ]; then
  CMD_FLAGS="$CMD_FLAGS --refresh-podcasts"
fi

if [ "$RECENT_ONLY" = true ]; then
  CMD_FLAGS="$CMD_FLAGS --recent-only"
fi

if [ -n "$HOURS" ]; then
  CMD_FLAGS="$CMD_FLAGS --hours $HOURS"
fi

# Construct full command
# We wrap TARGET_SCRIPT in single quotes to handle paths with spaces safely
FULL_COMMAND="'$TARGET_SCRIPT'$CMD_FLAGS"

# 5. Execute
if [ "$OPEN_NEW_WINDOW" = true ]; then
  if [ "$KEEP_OPEN" = true ]; then
    echo "Launching in new terminal (keeping open): $FULL_COMMAND"
    # We escape the quotes for the AppleScript string
    osascript -e "tell application \"Terminal\" to do script \"$FULL_COMMAND\""
  else
    echo "Launching in new terminal (will close when done): $FULL_COMMAND"
    # Appending 'exit' will terminate the shell session once the command finishes.
    # By default in macOS Terminal, this closes the window.
    osascript -e "tell application \"Terminal\" to do script \"$FULL_COMMAND; exit\""
  fi
else
  echo "Running inline: $FULL_COMMAND"
  eval "$FULL_COMMAND"
fi

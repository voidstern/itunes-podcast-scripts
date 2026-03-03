#!/usr/bin/env bash
# clean_all_metadata.sh
# Walks all audio files in the iTunes Media folder and strips verbose metadata
# (lyrics, descriptions, comments) using ffmpeg. Creates a .metaclean marker
# file after each successful clean so re-runs skip already-cleaned files.
#
# Usage:
#   clean_all_metadata.sh [OPTIONS]
#
# Options:
#   --folder <path>   Root folder to scan (default: ../iTunes/iTunes Media/)
#   --kind <type>     Restrict to: podcasts | music | audiobooks | all (default: all)
#   --dry-run         Preview files that would be processed without modifying them
#   --force           Re-clean files that already have a .metaclean marker
#   -h, --help        Show this help message

set -euo pipefail

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BOLD=""; RESET=""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_CLEAN="${SCRIPT_DIR}/clean_metadata.sh"
MARKER_EXT="metaclean"

# --- Defaults ---
ITUNES_MEDIA="$(cd "${SCRIPT_DIR}/../../iTunes/iTunes Media" 2>/dev/null && pwd)" || ITUNES_MEDIA=""
TARGET_FOLDER="$ITUNES_MEDIA"
KIND="all"
DRY_RUN=false
FORCE=false

# --- Help ---
show_help() {
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --folder <path>   Root folder to scan (default: iTunes Media next to Scripts dir)"
  echo "  --kind <type>     podcasts | music | audiobooks | all  (default: all)"
  echo "  --dry-run         Preview without modifying files"
  echo "  --force           Re-clean already-cleaned files"
  echo "  -h, --help        Show this help"
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --folder)
      TARGET_FOLDER="$2"; shift 2 ;;
    --kind)
      KIND="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=true; shift ;;
    --force)
      FORCE=true; shift ;;
    -h|--help)
      show_help; exit 0 ;;
    *)
      echo "${RED}Unknown option:${RESET} $1"; show_help; exit 1 ;;
  esac
done

# --- Validate folder ---
if [[ -z "$TARGET_FOLDER" || ! -d "$TARGET_FOLDER" ]]; then
  echo "${RED}Error:${RESET} iTunes Media folder not found."
  echo "Expected: ${ITUNES_MEDIA}"
  echo "Use --folder <path> to specify it manually."
  exit 1
fi

# --- Validate kind ---
case "$KIND" in
  all|podcasts|music|audiobooks) ;;
  *)
    echo "${RED}Error:${RESET} --kind must be one of: podcasts, music, audiobooks, all"
    exit 1 ;;
esac

# --- Validate clean_metadata.sh ---
if [[ ! -x "$SCRIPT_CLEAN" ]]; then
  echo "${RED}Error:${RESET} clean_metadata.sh not found or not executable at:"
  echo "  $SCRIPT_CLEAN"
  exit 1
fi

# --- Determine sub-folders to scan ---
declare -a SCAN_DIRS=()
case "$KIND" in
  all)
    SCAN_DIRS=("$TARGET_FOLDER") ;;
  podcasts)
    SCAN_DIRS=("$TARGET_FOLDER/Podcasts") ;;
  music)
    SCAN_DIRS=("$TARGET_FOLDER/Music") ;;
  audiobooks)
    SCAN_DIRS=("$TARGET_FOLDER/Audiobooks" "$TARGET_FOLDER/Books") ;;
esac

echo ""
echo "${BOLD}${CYAN}=== Clean All Metadata ===${RESET}"
echo "${CYAN}Folder:${RESET}  $TARGET_FOLDER"
echo "${CYAN}Kind:${RESET}    $KIND"
echo "${CYAN}Dry run:${RESET} $DRY_RUN"
echo "${CYAN}Force:${RESET}   $FORCE"
echo ""

# --- Main sweep ---
total=0
cleaned=0
skipped=0
failed=0

# Build the find command. We target common audio extensions.
while IFS= read -r -d '' FILE; do
  EXT_LOWER="$(echo "${FILE##*.}" | tr '[:upper:]' '[:lower:]')"

  # Only process audio files
  case "$EXT_LOWER" in
    mp3|m4a|m4b|aac|aiff|aif|wav|flac|ogg|opus) ;;
    *) continue ;;
  esac

  BASE="${FILE%.*}"
  MARKER="${BASE}.${MARKER_EXT}"

  total=$((total + 1))

  # Skip already-cleaned files unless --force
  if [[ -e "$MARKER" && "$FORCE" != "true" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "${BLUE}[dry-run]${RESET} $FILE"
    cleaned=$((cleaned + 1))
    continue
  fi

  # Run the cleaner
  if "$SCRIPT_CLEAN" "$FILE"; then
    # Mark as cleaned
    : > "$MARKER"
    cleaned=$((cleaned + 1))
  else
    echo "   ${RED}✗ Failed:${RESET} $FILE"
    failed=$((failed + 1))
  fi

done < <(find "${SCAN_DIRS[@]}" -type f -print0 2>/dev/null)

# --- Summary ---
echo ""
echo "${BOLD}=== Summary ===${RESET}"
echo "  Total audio files found : $total"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  Would clean             : $cleaned"
  echo "  Already clean (skip)   : $skipped"
else
  echo "  Cleaned                : ${GREEN}$cleaned${RESET}"
  echo "  Already clean (skip)   : $skipped"
  echo "  Failed                 : ${failed:+${RED}}$failed${RESET}"
fi
echo ""

if [[ $failed -gt 0 ]]; then
  exit 1
fi

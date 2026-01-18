#!/usr/bin/env bash
set -euo pipefail

# Marker extensions
PRIMARY_MARKER_EXT="adjusted"
SECONDARY_MARKER_EXT="adjust"
AUDIO_EXTENSIONS=("mp3" "m4a" "m4b" "aac" "wav" "aiff")

# --- Colors ---
if [[ -t 1 ]]; then
  YELLOW=$'\033[33m'; CYAN=$'\033[36m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  YELLOW=""; CYAN=""; GREEN=""; BOLD=""; RESET=""
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <directory>"
  exit 2
fi

INPUT_DIR="$1"

echo "${BOLD}${CYAN}Cleaning up orphaned marker files...${RESET}"

# --- Cleanup orphaned marker files ---
find "$INPUT_DIR" -type f \( \
  -name "*.${PRIMARY_MARKER_EXT}" -o \
  -name "*.${SECONDARY_MARKER_EXT}" \
\) -print0 | \
while IFS= read -r -d '' marker_file; do
  base="${marker_file%.*}"
  found=false

  for ext in "${AUDIO_EXTENSIONS[@]}"; do
    [[ -e "${base}.${ext}" ]] && found=true && break
  done

  if [[ "$found" == false ]]; then
    echo "${YELLOW}• Removing orphan marker:${RESET} $marker_file"
    rm -f "$marker_file"
  fi
done

echo
echo "${BOLD}${CYAN}Cleaning up orphaned temp files...${RESET}"

# --- Cleanup orphaned temp_* files ---
find "$INPUT_DIR" -type f -name "temp_*" -print0 | \
while IFS= read -r -d '' temp_file; do
  dir="$(dirname "$temp_file")"
  name="$(basename "$temp_file")"
  original="${dir}/${name#temp_}"

  if [[ ! -e "$original" ]]; then
    echo "${YELLOW}• Removing orphan temp file:${RESET} $temp_file"
    rm -f "$temp_file"
  fi
done

echo
echo "${BOLD}${GREEN}Cleanup complete.${RESET}"
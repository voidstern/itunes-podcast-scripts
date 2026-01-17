#!/usr/bin/env bash
set -euo pipefail

# Default speed (used when speedup.conf is missing or invalid)
SPEED_FACTOR="2.0"

# Marker extensions
PRIMARY_MARKER_EXT="adjusted"   # written by this script
SECONDARY_MARKER_EXT="adjust"   # accepted for compatibility

AUDIO_EXTENSIONS=("mp3" "m4a" "m4b" "aac" "wav" "aiff")

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

# --- Add script directory to PATH so a local ./ffmpeg can be found ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
PATH="$PATH:$SCRIPT_DIR"

if [[ $# -lt 1 ]]; then
  echo "${RED}Usage:${RESET} $(basename "$0") <directory>"
  exit 2
fi

INPUT_DIR="$1"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "${RED}Error:${RESET} '$INPUT_DIR' is not a directory"
  exit 3
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "${RED}Error:${RESET} ffmpeg not found in PATH (also not in script directory: $SCRIPT_DIR)"
  exit 1
fi

echo "${BOLD}${CYAN}Directory:${RESET} $INPUT_DIR"
echo "${BOLD}${CYAN}Default speed factor:${RESET} ${SPEED_FACTOR}x"
echo

# --- Main processing ---
find "$INPUT_DIR" -type f \( \
  -iname "*.mp3" -o \
  -iname "*.m4a" -o \
  -iname "*.m4b" -o \
  -iname "*.aac" -o \
  -iname "*.wav" -o \
  -iname "*.aiff" \
\) ! -name 'temp_*' -print0 | \
while IFS= read -r -d '' file; do

  base_without_ext="${file%.*}"

  primary_marker="${base_without_ext}.${PRIMARY_MARKER_EXT}"
  secondary_marker="${base_without_ext}.${SECONDARY_MARKER_EXT}"

  if [[ -e "$primary_marker" || -e "$secondary_marker" ]]; then
    # echo "${YELLOW}⊘ Skipping (marker exists):${RESET} $file"
    continue
  fi

  dir_of_file=$(dirname "$file")
  conf_file="${dir_of_file}/speedup.conf"
  effective_speed="$SPEED_FACTOR"

  if [[ -f "$conf_file" ]]; then
    conf_speed=$(grep -E '^speed=[0-9]*\.?[0-9]+' "$conf_file" 2>/dev/null | head -n1 | cut -d'=' -f2)
    [[ -n "$conf_speed" ]] && effective_speed="$conf_speed"
  fi

  echo "${BLUE}→ Processing:${RESET} $file"
  echo "   ${CYAN}Using speed factor:${RESET} ${effective_speed}x"

  tmp_file="${dir_of_file}/temp_$(basename "$file")"

  if ffmpeg -nostdin -i "$file" -filter:a "atempo=${effective_speed}" -vn -y -write_xing 0 "$tmp_file" > /dev/null 2>&1; then
    mv -f "$tmp_file" "$file"
    : > "$primary_marker"
    echo "   ${GREEN}✓ Done:${RESET} $file"
  else
    echo "   ${RED}✗ ffmpeg failed for:${RESET} $file" >&2
    rm -f "$tmp_file" 2>/dev/null || true
  fi
done

echo "${BOLD}${CYAN}Cleaning up orphaned marker files...${RESET}"

# --- Cleanup orphaned marker files (.adjusted and .adjust) ---
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
echo "${BOLD}${GREEN}All done.${RESET}"
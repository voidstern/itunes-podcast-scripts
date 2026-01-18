#!/usr/bin/env bash
set -euo pipefail

# Default speed
DEFAULT_SPEED="2.0"

# Marker extensions
PRIMARY_MARKER_EXT="adjusted"
SECONDARY_MARKER_EXT="adjust"

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  RED=""; BLUE=""; CYAN=""; RESET=""
fi

# Ensure an input file is provided
if [[ $# -lt 1 ]]; then
  echo "${RED}Error:${RESET} No input file provided."
  exit 1
fi

FILE="$1"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
PATH="$PATH:$SCRIPT_DIR"

# 1. Check for ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "${RED}Error:${RESET} ffmpeg not found in PATH (also not in script directory: $SCRIPT_DIR)"
  exit 1
fi

# 2. Safety Check for markers
base_without_ext="${FILE%.*}"
if [[ -e "${base_without_ext}.${PRIMARY_MARKER_EXT}" || -e "${base_without_ext}.${SECONDARY_MARKER_EXT}" ]]; then
  echo "${RED}Skipping (marker exists):${RESET} $FILE"
  exit 0
fi

# 3. Determine Speed Factor
dir_of_file=$(dirname "$FILE")
conf_file="${dir_of_file}/speedup.conf"
effective_speed="$DEFAULT_SPEED"

if [[ -f "$conf_file" ]]; then
  conf_speed=$(grep -E '^speed=[0-9]*\.?[0-9]+' "$conf_file" 2>/dev/null | head -n1 | cut -d'=' -f2)
  [[ -n "$conf_speed" ]] && effective_speed="$conf_speed"
fi

echo "${BLUE}→ Processing:${RESET} $FILE"
echo "   ${CYAN}Speed factor:${RESET} ${effective_speed}x"

# 4. Apply FFmpeg
tmp_file="${dir_of_file}/temp_$(basename "$FILE")"
ffmpeg_log=$(mktemp) # Create a temp file to capture ffmpeg output

# Run ffmpeg, redirecting both stdout and stderr to the log file
if ffmpeg -nostdin -i "$FILE" -filter:a "atempo=${effective_speed}" -vn -y -write_xing 0 "$tmp_file" > "$ffmpeg_log" 2>&1; then
  mv -f "$tmp_file" "$FILE"
  rm -f "$ffmpeg_log" # Clean up log on success
  exit 0
else
  echo "   ${RED}✗ ffmpeg failed.${RESET} Output:" >&2
  echo "----------------------------------------" >&2
  cat "$ffmpeg_log" >&2 # Print the error details
  echo "----------------------------------------" >&2
  
  rm -f "$tmp_file" 2>/dev/null || true
  rm -f "$ffmpeg_log" # Clean up log on failure
  exit 1
fi
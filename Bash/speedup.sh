#!/usr/bin/env bash
set -euo pipefail

# Default values
DEFAULT_SPEED="2.0"
DEFAULT_INTRO="0"
DEFAULT_OUTRO="0"

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

# 3. Determine adjustments from adjustments.conf
dir_of_file=$(dirname "$FILE")
conf_file="${dir_of_file}/adjustments.conf"

effective_speed="$DEFAULT_SPEED"
effective_intro="$DEFAULT_INTRO"
effective_outro="$DEFAULT_OUTRO"

if [[ -n "$conf_file" ]]; then
  conf_speed=$(grep -E '^speed=[0-9]*\.?[0-9]+' "$conf_file" 2>/dev/null | head -n1 | cut -d'=' -f2 || true)
  conf_intro=$(grep -E '^intro=[0-9]*\.?[0-9]+' "$conf_file" 2>/dev/null | head -n1 | cut -d'=' -f2 || true)
  conf_outro=$(grep -E '^outro=[0-9]*\.?[0-9]+' "$conf_file" 2>/dev/null | head -n1 | cut -d'=' -f2 || true)
  [[ -n "$conf_speed" ]] && effective_speed="$conf_speed"
  [[ -n "$conf_intro" ]] && effective_intro="$conf_intro"
  [[ -n "$conf_outro" ]] && effective_outro="$conf_outro"
fi

echo "   ${CYAN}Speed factor:${RESET} ${effective_speed}x"
[[ "$effective_intro" != "0" ]] && echo "   ${CYAN}Trim intro:${RESET} ${effective_intro}s"
[[ "$effective_outro" != "0" ]] && echo "   ${CYAN}Trim outro:${RESET} ${effective_outro}s"

# 4. Build ffmpeg filter
# Trim is applied BEFORE speedup (on original timestamps).
# -ss trims the start; -to sets the end in original time (duration - outro).
# Then atempo applies the speed change.
tmp_file="${dir_of_file}/temp_$(basename "$FILE")"
ffmpeg_log=$(mktemp) # Create a temp file to capture ffmpeg output

# Build input options for start trim (applied at input for efficiency)
INPUT_OPTS=()
if [[ "$effective_intro" != "0" && "$effective_intro" != "0.0" ]]; then
  INPUT_OPTS+=(-ss "$effective_intro")
fi

# Build output options for end trim (duration-based, in original time)
OUTPUT_OPTS=()
if [[ "$effective_outro" != "0" && "$effective_outro" != "0.0" ]]; then
  # Get duration of the file in seconds
  raw_duration=$(ffmpeg -nostdin -i "$FILE" 2>&1 | grep -oE 'Duration: [0-9:\.]+' | head -n1 | cut -d' ' -f2 || true)
  if [[ -n "$raw_duration" ]]; then
    # Convert HH:MM:SS.ss to seconds
    IFS=: read -r hh mm ss <<< "$raw_duration"
    total_seconds=$(echo "$hh * 3600 + $mm * 60 + $ss" | bc)
    end_time=$(echo "$total_seconds - $effective_outro - ${effective_intro:-0}" | bc)
    OUTPUT_OPTS+=(-t "$end_time")
  fi
fi

# Build atempo filter string.
# ffmpeg's atempo filter is limited to [0.5, 2.0], so for speeds above 2x
# we chain multiple atempo filters whose product equals the target speed.
# For speeds <= 2x this produces exactly "atempo=<speed>" (identical call).
ATEMPO_FILTER=""
remaining_speed="$effective_speed"
while (( $(echo "$remaining_speed > 2.0" | bc -l) )); do
  ATEMPO_FILTER+="${ATEMPO_FILTER:+,}atempo=2.0"
  remaining_speed=$(echo "scale=10; $remaining_speed / 2.0" | bc -l)
done
ATEMPO_FILTER+="${ATEMPO_FILTER:+,}atempo=${remaining_speed}"

# Run ffmpeg, redirecting both stdout and stderr to the log file
if ffmpeg -nostdin ${INPUT_OPTS[@]+"${INPUT_OPTS[@]}"} -i "$FILE" ${OUTPUT_OPTS[@]+"${OUTPUT_OPTS[@]}"} \
    -filter:a "${ATEMPO_FILTER}" -vn -y -write_xing 0 \
    "$tmp_file" >"$ffmpeg_log" 2>&1; then
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
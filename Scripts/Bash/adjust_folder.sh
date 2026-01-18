#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
if [[ -t 1 ]]; then
	RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; CYAN=""; BOLD=""; RESET=""
fi

# --- Argument Parsing ---
FORCE_FLAG=""
INPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_FLAG="--force"
      shift
      ;;
    -*)
      echo "${RED}Unknown option:${RESET} $1"
      exit 1
      ;;
    *)
      if [[ -z "$INPUT_DIR" ]]; then
        INPUT_DIR="$1"
      else
        echo "${RED}Error:${RESET} Multiple directories provided. Only one allowed."
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$INPUT_DIR" ]]; then
  echo "${RED}Usage:${RESET} $(basename "$0") [--force] <directory>"
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
WORKER_SCRIPT="${SCRIPT_DIR}/adjust_file.sh"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "${RED}Error:${RESET} '$INPUT_DIR' is not a directory"
  exit 3
fi

if [[ ! -x "$WORKER_SCRIPT" ]]; then
  echo "${RED}Error:${RESET} Worker script not found or not executable: $WORKER_SCRIPT"
  exit 1
fi

echo "${BOLD}${CYAN}Directory:${RESET} $INPUT_DIR"
if [[ -n "$FORCE_FLAG" ]]; then
  echo "${BOLD}${YELLOW}Mode:${RESET} Force enabled (re-running metadata scripts on marked files)"
fi

# Prepare the command array base
CMD=("${WORKER_SCRIPT}")
if [[ -n "$FORCE_FLAG" ]]; then
  CMD+=("$FORCE_FLAG")
fi

# Find all audio files and call the worker script for each
find "$INPUT_DIR" -type f \( \
  -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.m4b" -o \
  -iname "*.aac" -o -iname "*.wav" -o -iname "*.aiff" \
\) ! -name 'temp_*' -print0 | \
while IFS= read -r -d '' file; do
  # Execute the constructed command with the file appended
  "${CMD[@]}" "$file"
done

echo
echo "${BOLD}${GREEN}Folder scan complete.${RESET}"
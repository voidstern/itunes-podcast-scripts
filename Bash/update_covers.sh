#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BOLD=""; RESET=""
fi

# --- Argument Parsing ---
TARGET_DIR=""
IMAGE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      IMAGE_URL="$2"
      shift 2
      ;;
    -*)
      echo "${RED}Unknown option:${RESET} $1"
      exit 1
      ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        echo "${RED}Error:${RESET} Multiple directories provided. Only one directory allowed."
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  echo "${RED}Usage:${RESET} $(basename "$0") [--url <image_url>] <directory>"
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "${RED}Error:${RESET} Directory not found: $TARGET_DIR"
  exit 1
fi

# Resolve absolute path of directory
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
COVER_FILE="${TARGET_DIR}/cover.png"

# --- Download Image ---
if [[ -n "$IMAGE_URL" ]]; then
  echo "${BOLD}${CYAN}Downloading cover image...${RESET}"
  if curl -sSL "$IMAGE_URL" -o "$COVER_FILE"; then
    echo "   ${GREEN}✓ Downloaded cover to $COVER_FILE${RESET}"
  else
    echo "   ${RED}✗ Failed to download cover from $IMAGE_URL${RESET}"
    exit 1
  fi
fi

if [[ ! -f "$COVER_FILE" ]]; then
  echo "${YELLOW}No 'cover.png' found in $TARGET_DIR. Nothing to embed.${RESET}"
  exit 0
fi

# --- Find Audio Files and Embed ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
SCRIPT_EMBED="${SCRIPT_DIR}/embed_podcast_cover.sh"

echo "${BOLD}${CYAN}Updating covers in: $TARGET_DIR...${RESET}"

# Use exact extensions common in the scripts
AUDIO_EXTENSIONS=("mp3" "m4a" "m4b" "aac" "wav" "aiff")
FOUND_ANY=false

for ext in "${AUDIO_EXTENSIONS[@]}"; do
  shopt -s nullglob
  for audio_file in "$TARGET_DIR"/*."$ext"; do
    FOUND_ANY=true
    echo "${BLUE}Processing:${RESET} $(basename "$audio_file")"
    if [[ -x "$SCRIPT_EMBED" ]]; then
      "$SCRIPT_EMBED" "$audio_file"
    else
      echo "   ${RED}Error:${RESET} Embed script not executable or not found: $SCRIPT_EMBED"
      exit 1
    fi
  done
  shopt -u nullglob
done

if [[ "$FOUND_ANY" == false ]]; then
  echo "${YELLOW}No supported audio files found in $TARGET_DIR.${RESET}"
fi

echo "${BOLD}${GREEN}Done updating covers.${RESET}"

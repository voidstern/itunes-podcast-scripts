#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
PRIMARY_MARKER_EXT="adjusted"
SECONDARY_MARKER_EXT="adjust"

# --- Colors ---
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RESET=""
fi

# --- Argument Parsing ---
FORCE_MODE=false
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE=true
      shift
      ;;
    -*)
      echo "${RED}Unknown option:${RESET} $1"
      exit 1
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
      else
        echo "${RED}Error:${RESET} Multiple files provided. Only one file allowed per call."
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "${RED}Usage:${RESET} $(basename "$0") [--force] <audio_file>"
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Define paths to sub-scripts
SCRIPT_SPEEDUP="${SCRIPT_DIR}/speedup.sh"
SCRIPT_EMBED="${SCRIPT_DIR}/embed_podcast_cover.sh"
SCRIPT_CLEAN="${SCRIPT_DIR}/clean_metadata.sh"

base_without_ext="${FILE%.*}"
primary_marker="${base_without_ext}.${PRIMARY_MARKER_EXT}"
secondary_marker="${base_without_ext}.${SECONDARY_MARKER_EXT}"

# 1. Check for existing markers
SKIP_SPEEDUP=false

echo "${BLUE}→ Processing:${RESET} $(basename "$FILE")"

if [[ -e "$primary_marker" || -e "$secondary_marker" ]]; then
  if [[ "$FORCE_MODE" == "true" ]]; then
    echo "   ${YELLOW}⚠ Marker exists, but --force used. Skipping speedup, but forcing embed and clean.${RESET}"
    SKIP_SPEEDUP=true
  else
    # Normal behavior: skip everything if marked
    exit 0
  fi
fi

# 2. Run Pipeline

# Step A: Speedup (Critical / Non-Idempotent)
if [[ "$SKIP_SPEEDUP" == "false" ]]; then
  if [[ -x "$SCRIPT_SPEEDUP" ]]; then
    if "$SCRIPT_SPEEDUP" "$FILE"; then
      # --- CRITICAL POINT ---
      # Speedup succeeded. We immediately mark the file.
      : > "$primary_marker"
      echo "   ${GREEN}✓ Speedup applied & marked.${RESET}"
    else
      echo "   ${RED}✗ Speedup failed.${RESET} Aborting." >&2
      exit 1
    fi
  else
    echo "   ${RED}Error:${RESET} speedup_file.sh not found." >&2
    exit 1
  fi
fi

# Step B: Embed Cover (Idempotent)
if [[ -x "$SCRIPT_EMBED" ]]; then
  if ! "$SCRIPT_EMBED" "$FILE"; then
    echo "   ${RED}✗ Embed failed.${RESET} (Continuing pipeline...)" >&2
  fi
fi

# Step C: Clean Metadata (Idempotent)
if [[ -x "$SCRIPT_CLEAN" ]]; then
  if ! "$SCRIPT_CLEAN" "$FILE"; then
    echo "   ${RED}✗ Clean metadata failed.${RESET} (Continuing pipeline...)" >&2
  fi
fi

echo "   ${GREEN}✓ File processing complete.${RESET}"
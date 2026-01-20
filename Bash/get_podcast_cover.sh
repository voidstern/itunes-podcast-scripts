#!/bin/bash

# ==============================================================================
# Recursive Podcast Cover Downloader (Universal Edition)
# Features:
#   - Recursive: Auto-detects subfolders
#   - Leaf-only: Skips parent folders, processes only the final folders
#   - Smart: Skips existing covers (unless --force is used)
#   - Compatible: Works on legacy macOS (Python 2) and modern macOS (Python 3)
# ==============================================================================

# Initialize variables
TARGET_ROOT=""
FORCE_MODE=false

# 1. Parse Arguments
for arg in "$@"; do
    case $arg in
        --force)
        FORCE_MODE=true
        shift # Remove --force from processing
        ;;
        *)
        if [ -z "$TARGET_ROOT" ]; then
            TARGET_ROOT="$arg"
        fi
        ;;
    esac
done

# Validation
if [ -z "$TARGET_ROOT" ]; then
    echo "Usage: $0 <path_to_folder> [--force]"
    exit 1
fi

# Ensure target exists
if [ ! -d "$TARGET_ROOT" ]; then
    echo "❌ Error: Directory not found: $TARGET_ROOT"
    exit 1
fi

# Remove trailing slash for consistency
TARGET_ROOT="${TARGET_ROOT%/}"

# ==============================================================================
# HELPER FUNCTIONS: Python Version Handling
# ==============================================================================

url_encode() {
    local string="$1"
    if command -v python3 &>/dev/null; then
        python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$string"
    elif command -v python &>/dev/null; then
        python -c "import sys, urllib; print urllib.quote(sys.argv[1])" "$string"
    else
        echo "❌ Error: Neither python3 nor python found." >&2
        return 1
    fi
}

extract_json_url() {
    local json_input="$1"
    if command -v python3 &>/dev/null; then
        echo "$json_input" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['results'][0]['artworkUrl600']) if data['resultCount'] > 0 else print('')"
    elif command -v python &>/dev/null; then
        echo "$json_input" | python -c "import sys, json; data = json.load(sys.stdin); print data['results'][0]['artworkUrl600'] if data['resultCount'] > 0 else ''"
    else
        return 1
    fi
}

# ==============================================================================
# FUNCTION: Download Logic (The Worker)
# ==============================================================================
download_art_for_folder() {
    local dir="$1"
    local cover_path="$dir/cover.png"
    local podcast_name=$(basename "$dir")

    # CHECK: Skip if exists (and not forcing)
    if [ -f "$cover_path" ] && [ "$FORCE_MODE" = false ]; then
        return
    fi

    echo "🔍 Processing: $podcast_name"

    # URL Encode (Version agnostic)
    local encoded_name=$(url_encode "$podcast_name")
    
    # Query Apple API
    local json_response=$(curl -s "https://itunes.apple.com/search?term=${encoded_name}&media=podcast&limit=1")
    
    # Extract URL (Version agnostic)
    local img_url=$(extract_json_url "$json_response")

    if [ -z "$img_url" ]; then
        echo "   ❌ Not found in Apple Directory."
        return
    fi

    echo "   ⬇️  Downloading artwork..."
    local temp_img="/tmp/podcast_dl_temp_$(date +%s)"
    
    curl -s "$img_url" -o "$temp_img"

    if [ -f "$temp_img" ]; then
        # Convert/Save as PNG
        sips -s format png "$temp_img" --out "$cover_path" > /dev/null 2>&1
        rm "$temp_img"
        echo "   ✅ Saved cover.png"
    else
        echo "   ❌ Download failed."
    fi
}

# ==============================================================================
# FUNCTION: Recursive Traversal
# ==============================================================================
traverse_tree() {
    local current_dir="$1"
    
    # Count subdirectories in the current folder
    local subdir_count=$(find "$current_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)

    if [ "$subdir_count" -gt 0 ]; then
        # BRANCH NODE
        find "$current_dir" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' sub_folder; do
            traverse_tree "$sub_folder"
        done
    else
        # LEAF NODE
        download_art_for_folder "$current_dir"
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

if [ "$FORCE_MODE" = true ]; then
    echo "⚠️  Force Mode Active: Overwriting existing covers."
fi

# Pre-flight check for Python availability
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo "❌ Critical Error: No Python interpreter found (python3 or python)."
    echo "   Please install Python 3 (e.g., 'brew install python') or Xcode command line tools."
    exit 1
fi

traverse_tree "$TARGET_ROOT"
#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <audiobook-file>" >&2
    exit 1
fi

input_file=$1

if [[ ! -f "$input_file" ]]; then
    echo "File not found: $input_file" >&2
    exit 1
fi

input_dir=$(dirname -- "$input_file")
input_name=$(basename -- "$input_file")

if [[ "$input_name" == *.* ]]; then
    output_name="${input_name%.*}_fixed.${input_name##*.}"
else
    output_name="${input_name}_fixed"
fi

output_file="$input_dir/$output_name"

ffmpeg -i "$input_file" -c:a aac -b:a 128k -c:v copy -map 0:a -map "0:v?" -map_chapters 0 -movflags +faststart "$output_file"

#!/bin/bash

# Check if the required tools are installed
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Function to process a single file
process_file() {
    local INPUT=$1
    local OUTPUT_DIR=$2
    local OUTPUT_FILE="${OUTPUT_DIR}/$(basename "${INPUT%.*}").webp"
    convert "${INPUT}" -strip -resize '1000x1000>' -quality 80 -define webp:lossless=false -define webp:method=6 "${OUTPUT_FILE}"
    echo "Generated thumbnail: $INPUT -> $OUTPUT_FILE"
}

# Save the first argument as the input
INPUT=$1

# Set output directory to current directory
OUTPUT_DIR="."

echo "Generating thumbnails..."

# Check if input is a directory or a file
if [[ -d "$INPUT" ]]; then
    # If it's a directory, iterate over the files
    for FILE in "$INPUT"/*
    do
        if [[ -f "$FILE" ]]; then
            process_file "$FILE" "$OUTPUT_DIR"
        fi
    done
elif [[ -f "$INPUT" ]]; then
    # If it's a file, process it directly
    process_file "$INPUT" "$OUTPUT_DIR"
else
    echo "Error: Input is neither a valid file nor a directory."
    exit 1
fi

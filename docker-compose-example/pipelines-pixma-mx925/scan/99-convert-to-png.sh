#!/bin/bash

# Check if the required tools are installed
command -v magick >/dev/null 2>&1 || { echo >&2 "Error: magick is not installed. Please install ImageMagick and try again."; exit 1; }

# Save the first argument as the input directory
INPUT_DIR=$1

# Set output directory to current directory
OUTPUT_DIR="."

echo "Converting files to PNG..."

# Iterate over the files in the input directory
for INPUT in "$INPUT_DIR"/*
do
  # Check if it's a file
  if [[ -f "$INPUT" ]]; then
    ORIGINAL=$INPUT

    BASENAME="${ORIGINAL##*/}"
    ORIGINAL_NAME="${BASENAME%.*}"

    #OUTPUT_FILENAME="$OUTPUT_DIR/${ORIGINAL_NAME}.webp"
    #convert "$INPUT" -define webp:lossless=true "$OUTPUT_FILENAME"

    OUTPUT_FILENAME="$OUTPUT_DIR/${ORIGINAL_NAME}.png"
    magick "$INPUT" "$OUTPUT_FILENAME"

    echo "Converted: $INPUT -> $OUTPUT_FILENAME"
  fi
done

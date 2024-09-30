#!/bin/bash

# Check if the required tools are installed
command -v magick >/dev/null 2>&1 || { echo >&2 "Error: magick is not installed. Please install it and try again."; exit 1; }

# Save the first argument as the input directory
INPUT_DIR=$1

# Set output directory to current directory
OUTPUT_DIR="."

echo "Discarding small files"

# Iterate over the files in the input directory
for INPUT in "$INPUT_DIR"/*; do
  # Check if it's a file
  if [[ -f "$INPUT" ]]; then
    ORIGINAL=$INPUT
    echo "Processing file: $INPUT"

    BASENAME="${ORIGINAL##*/}"
    ORIGINAL_NAME="${BASENAME%.*}"

    OUTPUT_FILENAME="$OUTPUT_DIR/${ORIGINAL_NAME}.TIFF"

    # Get file size in bytes using ls -l
    FILE_SIZE=$(ls -l "$INPUT" | awk '{print $5}')

    # Check if file size is greater than 10KB (10240 bytes)
    if [ $FILE_SIZE -gt 10240 ]; then
        cp "$INPUT" "$OUTPUT_FILENAME"
    else
        echo "  -> $ORIGINAL_NAME -> discard (file size <= 10KB)"
    fi
  fi
done

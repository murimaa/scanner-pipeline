#!/bin/bash

# Check if the required tools are installed
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Save the first argument as the input directory
INPUT_DIR=$1

# Set output directory to current directory
OUTPUT_DIR="."

echo "Flipping every other page (evens)..."

# Iterate over the files in the input directory
for INPUT in "$INPUT_DIR"/*; do
  # Check if it's a file
  if [[ -f "$INPUT" ]]; then
    ORIGINAL=$INPUT
    echo "Processing file: $INPUT"

    BASENAME="${ORIGINAL##*/}"
    ORIGINAL_NAME="${BASENAME%.*}"

    # file name is in the format of:
    # yyyymmdd-hhmmss-0024-0003.pnm
    # first number being a running number and second number page number of a scan

    # Extract the second number using the cut command
    # The -d option specifies the delimiter (in this case, a dash)
    # The -f option specifies the field to select (in this case, the second field)
    second_number=$((10#$(cut -d "-" -f 4 <<< "$ORIGINAL_NAME")))
    # Remove leading zeros (converts to 10 base number)
    PAGE_NUMBER=$((10#$second_number))

    OUTPUT_FILENAME="$OUTPUT_DIR/${ORIGINAL_NAME}.pnm"

    # Get file size in bytes using ls -l
    FILE_SIZE=$(ls -l "$INPUT" | awk '{print $5}')

    if [ $((PAGE_NUMBER % 2)) -eq 1 ]; then
      echo "  -> $ORIGINAL_NAME -> keep as-is $OUTPUT_FILENAME"
      cp "$INPUT" "$OUTPUT_FILENAME"
    else
      # Check if file size is greater than 10KB (10240 bytes)
      if [ $FILE_SIZE -gt 10240 ]; then
        echo "  -> $ORIGINAL_NAME -> flip $OUTPUT_FILENAME"
        convert "$INPUT" -rotate 180 "$OUTPUT_FILENAME"
      else
        echo "  -> $ORIGINAL_NAME -> copy (file size <= 10KB) $OUTPUT_FILENAME"
        cp "$INPUT" "$OUTPUT_FILENAME"
      fi
    fi
  fi
done

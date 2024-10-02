#!/bin/bash
# Check if the required tools are installed
command -v magick >/dev/null 2>&1 || { echo >&2 "Error: magick is not installed. Please install it and try again."; exit 1; }

# Save the first argument as the input directory
INPUT_DIR=$1

# Set output directory to current directory
OUTPUT_DIR="."

# Save the directory of script
CURRENT_DIR=$(dirname -- "$0")

for INPUT in "$INPUT_DIR"/*
do
  # Check if it's a file
  if [[ -f "$INPUT" ]]; then
    BASENAME="${INPUT##*/}"
    echo "  -> $INPUT -> $OUTPUT_DIR/$BASENAME"
    magick "$INPUT" -trim +repage "$OUTPUT_DIR/$BASENAME"
    retval=$?
    if [ $retval -ne 0 ]; then
      echo "Non-zero return value: $retval - exiting."
      exit $retval
    fi
  fi
done

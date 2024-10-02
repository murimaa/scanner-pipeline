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
    echo "  -> $INPUT"
    # "${CURRENT_DIR}/lib/textcleaner2" -g -e stretch -f 25 -o 10 -u -s 1 -T -p 10 "$INPUT" "$OUTPUT_DIR/$BASENAME"
    #magick "$INPUT" -deskew 40% -colorspace Gray -despeckle -contrast-stretch 0 -trim +repage -threshold 50% "$OUTPUT_DIR/$BASENAME"

    orientation=$(magick "$INPUT" -resize 100x100\! -format "%[fx:(w>h)?90:0]" info:)
    magick "$INPUT" -rotate "$orientation" -deskew 40% -gravity center -crop 2480x3508+0+0 -colorspace Gray -despeckle -contrast-stretch 2%x90% -trim +repage -threshold 60% "$OUTPUT_DIR/$BASENAME"


    retval=$?
    if [ $retval -ne 0 ]; then
      echo "Non-zero return value: $retval - exiting."
      exit $retval
    fi
  fi
done

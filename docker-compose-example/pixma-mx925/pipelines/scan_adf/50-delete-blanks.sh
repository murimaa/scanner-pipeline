#!/bin/bash
# Check if the required tools are installed
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Save the first argument as the input directory
INPUT_DIR=$1

# Set output directory to current directory
OUTPUT_DIR="."

DPI=300
for INPUT in "$INPUT_DIR"/*
do
  # Check if it's a file
  if [[ -f "$INPUT" ]]; then
    FILE_SIZE=$(du -k "$INPUT" | cut -f1)
    if [ $FILE_SIZE -gt 1000 ];
    then
      echo "  -> ${INPUT} ..."
      BLANK_CHECK_OUTPUT=$(convert "${INPUT}" -shave ${DPI}x${DPI} -density $(expr $DPI/2) -adaptive-resize 65% -virtual-pixel White -blur 0x15 -fuzz 15% -trim info: 2>/dev/null)
      # echo "     $BLANK_CHECK_OUTPUT"
      BLANK_CHECK_REGEX="^ *([a-zA-Z0-9\[_\/\\\.\-]+) +[a-zA-Z]+ +([0-9]+)x([0-9]+) "
      # example output: raw/page_0005.tiff PPM 1247x1950 1269x2340+6+5 8-bit sRGB 30.6656MiB 0.030u 0:00.019
      if [[ $BLANK_CHECK_OUTPUT =~ $BLANK_CHECK_REGEX ]];
      then
        X=${BASH_REMATCH[2]}
        Y=${BASH_REMATCH[3]}
        # echo "     Matches regex."
        THRESHOLD=$(expr $DPI / 2 \* 3 / 100)
        if [ $X -lt $THRESHOLD ]; # && [ $Y -gt $THRESHOLD ];
        then
          echo "     ${INPUT} blank, discarding"
          #rm "${INPUT}"
        else
          echo "     ${INPUT}, keeping"
          cp "${INPUT}" "$OUTPUT_DIR"
        fi
      fi
    else
      # not valid image
      echo "    ${INPUT} too small, discarding"
      # rm "${INPUT}"
    fi
  fi
done

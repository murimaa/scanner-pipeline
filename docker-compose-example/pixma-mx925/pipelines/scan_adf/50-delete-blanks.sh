#!/bin/bash

# Configuration
NEW_EXTENSION=""  # Keep original extension
FAIL_ON_ERROR=false  # Continue processing even if individual files fail
DPI=300
THRESHOLD=$(expr $DPI / 2 \* 3 / 100)

# Check for required tools
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Function to determine output filename
get_output_filename() {
    local input=$1
    local output_dir=$2
    local filename=$(basename "$input")

    if [ -n "$NEW_EXTENSION" ]; then
        echo "${output_dir}/${filename%.*}.${NEW_EXTENSION}"
    else
        echo "${output_dir}/${filename}"
    fi
}

# Function to process a single file
process_file() {
    local input=$1
    local output=$(get_output_filename "$input" "$OUTPUT_DIR")

    FILE_SIZE=$(du -k "$input" | cut -f1)
    if [ $FILE_SIZE -le 1000 ]; then
        echo "    ${input} too small, discarding"
        return 0
    fi

    echo "  -> ${input} ..."
    BLANK_CHECK_OUTPUT=$(convert "${input}" -shave ${DPI}x${DPI} -density $(expr $DPI/2) -adaptive-resize 65% -virtual-pixel White -blur 0x15 -fuzz 15% -trim info: 2>/dev/null)
    BLANK_CHECK_REGEX="^ *([a-zA-Z0-9\[_\/\\\.\-]+) +[a-zA-Z]+ +([0-9]+)x([0-9]+) "

    if [[ $BLANK_CHECK_OUTPUT =~ $BLANK_CHECK_REGEX ]]; then
        X=${BASH_REMATCH[2]}
        Y=${BASH_REMATCH[3]}
        if [ $X -lt $THRESHOLD ]; then
            echo "     ${input} blank, discarding"
        else
            echo "     ${input}, keeping"
            cp "${input}" "$output"
        fi
    else
        echo "     ${input}, regex didn't match, keeping"
        cp "${input}" "$output"
    fi

    return 0
}

# Main script
INPUT_DIR=$1
OUTPUT_DIR="."

echo "Processing files..."

if [[ -d "$INPUT_DIR" ]]; then
    for INPUT in "$INPUT_DIR"/*; do
        if [[ -f "$INPUT" ]]; then
            process_file "$INPUT"
            if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
                echo "Exiting due to error in processing $INPUT" >&2
                exit 1
            fi
        fi
    done
elif [[ -f "$INPUT_DIR" ]]; then
    process_file "$INPUT_DIR"
    if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
        echo "Exiting due to error in processing $INPUT_DIR" >&2
        exit 1
    fi
else
    echo "Error: Input is neither a valid file nor a directory." >&2
    exit 1
fi

echo "Processing complete. Output files are in: $OUTPUT_DIR"

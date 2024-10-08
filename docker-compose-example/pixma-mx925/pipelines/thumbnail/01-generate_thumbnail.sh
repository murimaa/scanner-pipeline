#!/bin/bash

# Configuration
NEW_EXTENSION="webp"  # Set output extension to webp
FAIL_ON_ERROR=true  # Exit on first error
PROCESS_COMMAND='convert "$input" -strip -resize "1000x1000>" -quality 80 -define webp:lossless=false -define webp:method=6 "$output"'

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
    local output=$(get_output_filename "$input" "$output_dir")

    echo "Generating thumbnail: $input -> $output"

    # Process the file using the configured command
    eval $PROCESS_COMMAND
    local command_status=$?

    if [ $command_status -ne 0 ]; then
        echo "Error: Convert failed for file: $input" >&2
        return 1
    fi

    return 0
}

# Main script
input=$1
output_dir=$(pwd)

echo "Generating thumbnails..."

if [[ -d "$input" ]]; then
    for file in "$input"/*; do
        if [[ -f "$file" ]]; then
            process_file "$file"
            if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
                echo "Exiting due to error in processing $file" >&2
                exit 1
            fi
        fi
    done
elif [[ -f "$input" ]]; then
    process_file "$input"
    if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
        echo "Exiting due to error in processing $input" >&2
        exit 1
    fi
else
    echo "Error: Input is neither a valid file nor a directory." >&2
    exit 1
fi

echo "Thumbnail generation complete. Output files are in: $output_dir"

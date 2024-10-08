#!/bin/bash

# When using duplex ADF scanning on a Canon Pixma, the backsides are rotated.
# This flips every second page 180 degrees to correct orientation.

# File name must be in the format "XXXXXX-XXXX-XXXX-XXXX.ZZZ" where the 4th field
# is a running number in the scan job. Even numbers are flipped.

# Configuration
NEW_EXTENSION=""  # Set to "pnm" to ensure all output files have .pnm extension
FAIL_ON_ERROR=true  # Set to false to continue processing even if individual files fail
PROCESS_COMMAND='process_and_flip "$input" "$output"'

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

# Function to process and flip file if necessary
process_and_flip() {
    local input=$1
    local output=$2
    local filename=$(basename "$input")
    local name_without_ext="${filename%.*}"

    local second_number=$((10#$(echo "$name_without_ext" | cut -d "-" -f 4)))
    local PAGE_NUMBER=$((10#$second_number))
    local FILE_SIZE=$(ls -l "$input" | awk '{print $5}')

    if [ $((PAGE_NUMBER % 2)) -eq 1 ]; then
        echo "  -> $name_without_ext -> keep as-is $output"
        cp "$input" "$output"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to copy file $input" >&2
            return 1
        fi
    else
        if [ $FILE_SIZE -gt 10240 ]; then
            echo "  -> $name_without_ext -> flip $output"
            convert "$input" -rotate 180 "$output"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to flip file $input" >&2
                return 1
            fi
        else
            echo "  -> $name_without_ext -> copy (file size <= 10KB) $output"
            cp "$input" "$output"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to copy file $input" >&2
                return 1
            fi
        fi
    fi
    return 0
}

# Function to process a single file
process_file() {
    local input=$1
    local output=$(get_output_filename "$input" "$output_dir")

    eval $PROCESS_COMMAND
    local command_status=$?

    if [ $command_status -ne 0 ]; then
        echo "Error processing file: $input" >&2
        return 1
    fi

    return 0
}

# Main script
input=$1
output_dir=$(pwd)

echo "Flipping every other page (evens)..."

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

echo "Processing complete. Output files are in: $output_dir"

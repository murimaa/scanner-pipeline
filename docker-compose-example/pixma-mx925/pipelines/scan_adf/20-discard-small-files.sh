#!/bin/bash

# Configuration
NEW_EXTENSION=""  # Set to "TIFF" to change the extension of output files
FAIL_ON_ERROR=true  # Continue processing even if individual files fail
MIN_FILE_SIZE=10240  # Minimum file size in bytes (10KB)
PROCESS_COMMAND='process_file_size "$input" "$output"'

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

# Function to process file based on size
process_file_size() {
    local input=$1
    local output=$2
    local file_size=$(ls -l "$input" | awk '{print $5}')

    if [ $file_size -gt $MIN_FILE_SIZE ]; then
        cp "$input" "$output"
        echo "Copied: $input -> $output"
    else
        echo "  -> $(basename "$input") -> discard (file size <= $MIN_FILE_SIZE bytes)"
    fi
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

echo "Discarding small files..."

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

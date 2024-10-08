#!/bin/bash

# Configuration
NEW_EXTENSION="webp"  # Leave empty to keep original extension, or set to change (e.g., "webp")
FAIL_ON_ERROR=true  # Set to false to continue processing even if individual files fail
PROCESS_COMMAND='convert "$input" "$output"'  # Command to process each file

# Check for required tools
# command -v REQUIRED_TOOL >/dev/null 2>&1 || { echo >&2 "Error: REQUIRED_TOOL is not installed."; exit 1; }

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

    # Process the file using the configured command
    eval $PROCESS_COMMAND
    local command_status=$?

    if [ $command_status -ne 0 ]; then
        echo "Error processing file: $input" >&2
        return 1
    fi

    echo "Processed: $input -> $output"
    return 0
}

process_directory() {
    local dir=$1
    for file in "$dir"/*; do
        if [[ -f "$file" ]]; then
            process_file "$file"
            if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
                echo "Exiting due to error in processing $file" >&2
                exit 1
            fi
        fi
    done
}

# Main script
input=$1
output_dir=$(pwd)

echo "Processing files..."

if [[ -d "$input" ]]; then
    process_directory "$input"
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

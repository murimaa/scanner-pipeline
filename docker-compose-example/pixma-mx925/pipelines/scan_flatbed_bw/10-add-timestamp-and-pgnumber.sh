#!/bin/bash

# Configuration
NEW_EXTENSION=""  # Leave empty to keep original extension
FAIL_ON_ERROR=true  # Exit on first error
PROCESS_COMMAND='add_timestamp_and_number "$input" "$output"'

# Function to add timestamp and page number
add_timestamp_and_number() {
    local input=$1
    local output=$2
    local basename=$(basename "$input")
    local extension="${basename##*.}"
    local name="${basename%.*}"

    # Increment the counter variable
    page_number=$((page_number+1))

    # Create new filename with timestamp, running number, and original name
    local new_filename="${timestamp}-$(printf "%04d" $page_number)-${name}.${extension}"
    cp "$input" "${output%/*}/$new_filename"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy file $input" >&2
        return 1
    fi

    echo "Processed: $input -> $new_filename"
    return 0
}

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

# Global variables
timestamp=$(date +"%Y%m%d-%H%M%S")
page_number=0

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

echo "Adding timestamp and running page number to file names..."

if [[ -d "$input" ]]; then
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            process_file "$file"
            if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
                echo "Exiting due to error in processing $file" >&2
                exit 1
            fi
        fi
    done < <(find "$input" -type f | sort)
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

#!/bin/bash

# Save the first argument as the input directory
INPUT_DIR=$1
# Set output directory to current directory
OUTPUT_DIR="."

echo "Add a timestamp and running page number to the file names"

page_number=0
# Get current timestamp
timestamp=$(date +"%Y%m%d-%H%M%S")

# Use find to get all files in subdirectories, then sort them
while IFS= read -r file; do
    # Check if it's a regular file (not a directory or symlink)
    if [[ -f "$file" ]]; then
        # Extract the basename of the file (with extension)
        basename="${file##*/}"
        # Extract the file extension
        extension="${basename##*.}"
        # Extract the basename without the extension
        name="${basename%.*}"

        # Increment the counter variable
        page_number=$((page_number+1))

        # Create new filename with timestamp, running number, and original name
        new_filename="${timestamp}-$(printf "%04d" $page_number)-${name}.${extension}"
        cp "$file" "$OUTPUT_DIR/$new_filename"

        echo "Processed: $file -> $new_filename"
    fi
done < <(find "$INPUT_DIR" -type f | sort)

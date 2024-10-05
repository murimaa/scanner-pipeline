#!/bin/bash
# Check if the required tools are installed
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Check if a directory argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide a directory path as an argument."
    exit 1
fi

# Save the argument as the input directory
INPUT_DIR="$1"

# Check if the provided path is a directory
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: $INPUT_DIR is not a valid directory."
    exit 1
fi

# Get the current date in the format YYYY-MM-DD
date=$(date +%F)

# Generate a random string of 8 characters
rand=$(echo $RANDOM$RANDOM | md5sum | cut -c 1-8)

# Combine the date and random string to create a unique filename in the current directory
OUTPUT_FILE="./${date}-${rand}.pdf"

# Set the extensions you want to filter by in an array
image_extensions=("tiff" "png" "webp" "jpg" "jpeg")

# Initialize an empty array to store the filtered list of files
IMAGE_PAGES=()

# Iterate through the files in the input directory
for file in "$INPUT_DIR"/*; do
    # Get the base name of the file (i.e., the file name without the directory path)
    base_name=$(basename "$file")
    # Get the extension of the file
    file_extension="${base_name##*.}"
    # Convert the file extension to lowercase
    file_extension=$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')

    # Check if we have an image
    for extension in "${image_extensions[@]}"; do
        # Convert the extension to lowercase
        extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        # Check if the extension of the file matches one of the extensions we want to filter by
        if [ "$file_extension" = "$extension" ]; then
            # If the extensions match, add the file to the filtered list
            IMAGE_PAGES+=("$file")
            # Break out of the inner loop
            break
        fi
    done
done

# Check if we found any images
if [ ${#IMAGE_PAGES[@]} -eq 0 ]; then
    echo "No image files found in the specified directory."
    exit 1
fi

echo "Making pdf $OUTPUT_FILE"
convert "${IMAGE_PAGES[@]}" -density 72 -page a4 pdf:"$OUTPUT_FILE"
retval=$?
if [ $retval -ne 0 ]; then
    echo "Non-zero return value: $retval - exiting."
    exit $retval
fi

echo "PDF created successfully: $OUTPUT_FILE"

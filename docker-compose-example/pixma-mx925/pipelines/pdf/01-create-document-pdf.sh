#!/bin/bash

# Configuration
OUTPUT_DIR="."
FAIL_ON_ERROR=true
IMAGE_EXTENSIONS=("tiff" "png" "webp" "jpg" "jpeg")

# Check for required tools
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: imagemagick is not installed. Please install it and try again."; exit 1; }

# Function to generate output filename
get_output_filename() {
    local date=$(date +%F)
    local rand=$(echo $RANDOM$RANDOM | md5sum | cut -c 1-8)
    echo "${OUTPUT_DIR}/${date}-${rand}.pdf"
}

# Function to filter image files
filter_image_files() {
    local input_dir=$1
    local image_pages=()

    for file in "$input_dir"/*; do
        local file_extension=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')
        for extension in "${IMAGE_EXTENSIONS[@]}"; do
            if [ "$file_extension" = "$extension" ]; then
                image_pages+=("$file")
                break
            fi
        done
    done

    if [ ${#image_pages[@]} -eq 0 ]; then
        echo "No image files found in the specified directory." >&2
        return 1
    fi

    echo "${image_pages[@]}"
}

# Function to create PDF
create_pdf() {
    local output_file=$1
    shift
    local image_pages=("$@")

    echo "Making pdf $output_file"
    convert "${image_pages[@]}" -density 72 -page a4 pdf:"$output_file"
    local convert_status=$?

    if [ $convert_status -ne 0 ]; then
        echo "Error: PDF creation failed with status $convert_status" >&2
        return 1
    fi

    echo "PDF created successfully: $output_file"
    return 0
}

# Main script
if [ $# -eq 0 ]; then
    echo "Please provide a directory path as an argument." >&2
    exit 1
fi

input_dir="$1"

if [ ! -d "$input_dir" ]; then
    echo "Error: $input_dir is not a valid directory." >&2
    exit 1
fi

output_file=$(get_output_filename)
image_pages=$(filter_image_files "$input_dir")

if [ $? -ne 0 ]; then
    [ "$FAIL_ON_ERROR" = true ] && exit 1
fi

create_pdf "$output_file" $image_pages

if [ $? -ne 0 ] && [ "$FAIL_ON_ERROR" = true ]; then
    exit 1
fi

exit 0

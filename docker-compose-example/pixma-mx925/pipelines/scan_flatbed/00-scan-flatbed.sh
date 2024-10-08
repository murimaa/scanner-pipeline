#!/bin/bash
scanimage -d pixma --source Flatbed --resolution 300 -o 0000.pnm
# Capture the exit status of scanimage
scan_status=$?

# Check if scanimage failed.
if [ $scan_status -ne 0 ]; then
    echo "Error: Scanning failed with exit code $scan_status" >&2
    # Don't fail the script so that the pipeline is allowed to continue.
    # For example, ADF stuck while some pages scanned successfully.
    exit $scan_status
fi

# If we reach here, scanning was successful
echo "Scanning completed successfully"

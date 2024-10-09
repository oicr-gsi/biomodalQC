#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

cd "$1"

# Function to process _dqsummary.html file
process_dqsummary() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Remove the line containing "Timestamp:" and save to temp file
    grep -v "Timestamp:" "$file" > "$temp_file"
    
    # Generate MD5 sum of the temp file
    md5sum "$temp_file" | awk -v fname="$file" '{print $1 "  " fname}' 
    
    # Clean up
    rm "$temp_file"
}

# Process Summary.csv files
find . -name "*_Summary.csv" -type f | xargs md5sum

# Process _dqsummary.html files
find . -name "*_dqsummary.html" -type f | while read -r file; do
    process_dqsummary "$file"
done

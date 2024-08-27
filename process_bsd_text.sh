#!/bin/bash

# Set strict mode
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Source file
SOURCE_FILE="/home/BSD.txt"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    print_message "$RED" "Error: Source file $SOURCE_FILE does not exist."
    exit 1
fi

# Delete lines containing "copyright"
print_message "$YELLOW" "Deleting lines containing 'copyright'..."
grep -v "copyright" "$SOURCE_FILE" > /home/BSD_DELETE.txt

# Replace "the" with "them"
print_message "$YELLOW" "Replacing 'the' with 'them'..."
sed 's/\bthe\b/them/g' "$SOURCE_FILE" > /home/BSD_REPLACE.txt

# Verify results
print_message "$YELLOW" "Verifying results..."
print_message "$GREEN" "Lines in original file: $(wc -l < $SOURCE_FILE)"
print_message "$GREEN" "Lines in BSD_DELETE.txt: $(wc -l < /home/BSD_DELETE.txt)"
print_message "$GREEN" "Lines in BSD_REPLACE.txt: $(wc -l < /home/BSD_REPLACE.txt)"

print_message "$GREEN" "Text processing completed successfully."

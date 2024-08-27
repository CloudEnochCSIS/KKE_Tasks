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

# Function to display usage
usage() {
    echo "Usage: $0 <app1_user>@<app1_ip> <app2_user>@<app2_ip> <app3_user>@<app3_ip>"
    echo "Example: $0 tony@x.x.x.x steve@x.x.x.x banner@x.x.x.x"
    exit 1
}

# Check if correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    usage
fi

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    print_message "$YELLOW" "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""
fi

# Array of server details from command line arguments
declare -A servers=(
    ["stapp01"]="$1"
    ["stapp02"]="$2"
    ["stapp03"]="$3"
)

# Copy SSH key to each server
for server in "${!servers[@]}"; do
    print_message "$YELLOW" "Copying SSH key to $server..."
    ssh-copy-id -i ~/.ssh/id_rsa.pub "${servers[$server]}"
done

# Test connections
for server in "${!servers[@]}"; do
    print_message "$YELLOW" "Testing connection to $server..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "${servers[$server]}" exit; then
        print_message "$GREEN" "Successfully connected to $server"
    else
        print_message "$RED" "Failed to connect to $server"
    fi
done

print_message "$GREEN" "Password-less SSH setup completed."
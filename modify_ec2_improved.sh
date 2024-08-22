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

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_message "$RED" "Error: AWS CLI is not installed. Please install it and configure your credentials."
        exit 1
    fi
}

# Function to get instance details
get_instance_details() {
    local instance_name=$1
    local instance_details
    instance_details=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' --output text)
    if [ -z "$instance_details" ]; then
        print_message "$RED" "Error: No instance found with name $instance_name"
        exit 1
    fi
    echo "$instance_details"
}

# Main script execution starts here
main() {
    local instance_name="xfusion-ec2"
    local new_instance_type="t2.nano"

    check_aws_cli

    print_message "$YELLOW" "Fetching instance details..."
    local instance_details
    instance_details=$(get_instance_details "$instance_name")
    local instance_id
    instance_id=$(echo "$instance_details" | awk '{print $1}')
    local current_type
    current_type=$(echo "$instance_details" | awk '{print $2}')
    local current_state
    current_state=$(echo "$instance_details" | awk '{print $3}')

    print_message "$GREEN" "Instance ID: $instance_id"
    print_message "$GREEN" "Current Type: $current_type"
    print_message "$GREEN" "Current State: $current_state"

    if [ "$current_type" = "$new_instance_type" ]; then
        print_message "$YELLOW" "Instance is already of type $new_instance_type. No action needed."
        exit 0
    fi

    if [ "$current_state" != "stopped" ]; then
        print_message "$YELLOW" "Stopping the instance..."
        aws ec2 stop-instances --instance-ids "$instance_id" > /dev/null
        aws ec2 wait instance-stopped --instance-ids "$instance_id"
    fi

    print_message "$YELLOW" "Changing instance type to $new_instance_type..."
    aws ec2 modify-instance-attribute --instance-id "$instance_id" --instance-type "{\"Value\": \"$new_instance_type\"}"

    print_message "$YELLOW" "Starting the instance..."
    aws ec2 start-instances --instance-ids "$instance_id" > /dev/null
    aws ec2 wait instance-running --instance-ids "$instance_id"

    print_message "$YELLOW" "Verifying the change..."
    local new_details
    new_details=$(get_instance_details "$instance_name")
    local new_type
    new_type=$(echo "$new_details" | awk '{print $2}')
    local new_state
    new_state=$(echo "$new_details" | awk '{print $3}')

    if [ "$new_type" = "$new_instance_type" ] && [ "$new_state" = "running" ]; then
        print_message "$GREEN" "Successfully changed instance type to $new_instance_type and instance is running."
    else
        print_message "$RED" "Error: Failed to change instance type or start the instance."
        print_message "$RED" "Current Type: $new_type"
        print_message "$RED" "Current State: $new_state"
        exit 1
    fi
}

# Run the main function
main

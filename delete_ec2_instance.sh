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

# Set the region
AWS_REGION="us-east-1"

# Get the instance ID
print_message "$YELLOW" "Fetching instance ID for nautilus-ec2..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --filters "Name=tag:Name,Values=nautilus-ec2" "Name=instance-state-name,Values=running,stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    print_message "$RED" "Error: No running or stopped instance found with name nautilus-ec2"
    exit 1
fi

print_message "$GREEN" "Found instance ID: $INSTANCE_ID"

# Terminate the instance
print_message "$YELLOW" "Terminating instance..."
aws ec2 terminate-instances --region $AWS_REGION --instance-ids $INSTANCE_ID

# Wait for the instance to be terminated
print_message "$YELLOW" "Waiting for instance to be terminated..."
aws ec2 wait instance-terminated --region $AWS_REGION --instance-ids $INSTANCE_ID

# Verify the instance state
print_message "$YELLOW" "Verifying instance state..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[].Instances[].State.Name" \
    --output text)

if [ "$INSTANCE_STATE" == "terminated" ]; then
    print_message "$GREEN" "Instance successfully terminated."
else
    print_message "$RED" "Error: Instance is not in 'terminated' state. Current state: $INSTANCE_STATE"
    exit 1
fi

#!/bin/bash

# Define colors for success and failure messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Check if a configuration file path is provided
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Usage: $0 <path-to-telegraf-conf>${NC}"
    exit 1
fi

CONFIG_FILE=$1

# Test the provided configuration file
if telegraf --config "$CONFIG_FILE" --test; then
    echo -e "${GREEN}Successfully tested configuration: $CONFIG_FILE${NC}"
else
    echo -e "${RED}Failed to test configuration: $CONFIG_FILE${NC}"
    exit 1
fi

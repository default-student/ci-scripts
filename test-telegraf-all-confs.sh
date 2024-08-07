#!/bin/bash

# Define colors for success and failure messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR="$SCRIPT_DIR/conf"  # Adjust this to the relative path

cd "$CONFIG_DIR"

# Arrays to store results
successful_tests=()
failed_tests=()

# Check if .conf files exist in the directory
if ls *.conf 1> /dev/null 2>&1; then
    # Iterate over each config file and test
    for config_file in *.conf; do
        telegraf --config "$config_file" --test
        if [ $? -eq 0 ]; then
            successful_tests+=("$config_file")
            echo -e "Test of $config_file ${GREEN}completed successfully${NC}." 
        else
            failed_tests+=("$config_file")
            echo -e "Test of $config_file ${RED}failed${NC}." 
        fi
    done
else
    echo "No configuration files found in $CONFIG_DIR"
    exit 1
fi

# Display successful tests
if [ ${#successful_tests[@]} -gt 0 ]; then
    echo -e "${GREEN}Successfully${NC} tested configurations:"
    for config in "${successful_tests[@]}"; do
        echo -e "  - ${GREEN}$config${NC}"
    done
fi

# Display failed tests
if [ ${#failed_tests[@]} -gt 0 ]; then
    echo -e "${RED}Failed${NC} configuration tests:"
    for config in "${failed_tests[@]}"; do
        echo -e "  - ${RED}$config${NC}"
    done
	exit 2
else
    echo -e "${GREEN}All configurations tested successfully.${NC}"
	exit 0
fi

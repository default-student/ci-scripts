#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-Dockerfile>"
  exit 1
fi

DOCKERFILE_PATH="$1"

# Extract the image name from the Dockerfile path
IMAGE_NAME=$(basename "$DOCKERFILE_PATH" | sed 's/Dockerfile.//')

# Stop the running container
docker stop "$IMAGE_NAME"

# Remove the running container
docker rm "$IMAGE_NAME"

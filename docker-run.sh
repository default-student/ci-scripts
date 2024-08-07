#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-Dockerfile> [env-file1] [env-file2] ..."
  exit 1
fi

DOCKERFILE_PATH="$1"

# Extract the image name from the Dockerfile name
IMAGE_NAME=$(basename "$DOCKERFILE_PATH" | sed 's/^Dockerfile\.//')

# Check if the image name extraction worked
if [ -z "$IMAGE_NAME" ]; then
  echo "Failed to extract image name from Dockerfile path."
  exit 1
fi

# Stop and remove the running container if it exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${IMAGE_NAME}$"; then
  docker stop "$IMAGE_NAME"
  docker rm "$IMAGE_NAME"
fi

# Build the Docker image
# docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$(dirname "$DOCKERFILE_PATH")"

# Prepare the environment file arguments
ENV_ARGS=()
if [ "$#" -gt 1 ]; then
  for ENV_FILE in "${@:2}"; do
    ENV_ARGS+=("--env-file" "$ENV_FILE")
  done
fi

# Run the Docker container with or without environment files
docker run --name "$IMAGE_NAME" "${ENV_ARGS[@]}" "$IMAGE_NAME"

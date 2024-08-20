#!/bin/bash
set -x

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-Dockerfile> [env-file1] [env-file2] ..."
  exit 1
fi

DOCKERFILE_PATH="$1"

# Extract the image name from the Dockerfile name
CONTAINER_NAME=$(basename "$DOCKERFILE_PATH" | sed 's/^Dockerfile\.//')

if [ -f docker.env ]; then
  export $(cat docker.env | grep -v '^#' | xargs)
  IMAGE_NAME="$BASE_IMAGE_NAME$CONTAINER_NAME:latest"
  echo "Running Image with Base Image Name $IMAGE_NAME"

  echo "Mapping Port '$PORT' to '$PORT' for the container"
else
  echo "Error: No ./docker.env file found"
  echo "Running Image without Base Image Name $IMAGE_NAME"
  IMAGE_NAME="$CONTAINER_NAME:latest"

  echo "Not Passing any Port"
fi

# Check if the image name extraction worked
if [ -z "$IMAGE_NAME" ]; then
  echo "Failed to extract image name from Dockerfile path."
  exit 1
fi

# Stop and remove the running container if it exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  echo "Stopping and removing the existing container '$CONTAINER_NAME'"
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
fi

# Build the Docker image
# docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$(dirname "$DOCKERFILE_PATH")"

# Prepare the environment file arguments
ENV_ARGS=()
if [ "$#" -gt 1 ]; then
  for ENV_FILE in "${@:2}"; do
    ENV_ARGS+=("--env-file" "$ENV_FILE")
  done
else
  echo "No environment files provided."
fi

# Run the Docker container with or without environment files
docker run --name "$CONTAINER_NAME" -p "$PORT:$PORT" "${ENV_ARGS[@]}" "$IMAGE_NAME"

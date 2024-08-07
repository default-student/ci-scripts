#!/bin/bash

# Check for the required Dockerfile path argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <path_to_dockerfile>"
  exit 1
fi

# Assign the Dockerfile path from the first argument
dockerfile_path="$1"

# Run the Docker build script and check for success
if ! ./bin/docker-build.sh "$dockerfile_path"; then
  echo "Some or all Docker Builds failed."
fi

# Initialize arrays for tracking push statuses
successful_pushes=()
failed_pushes=()
output_file="successful_builds.txt"

# Function to push Docker images
push_image() {
  local image=$1

  if docker push "$image"; then
    successful_pushes+=("$image")
    echo "Successfully pushed: $image"
  else
    failed_pushes+=("$image")
    echo "Failed to push: $image"
  fi
}

# Assuming docker-build.sh tags the images as needed, 
# you need a way to get these image tags. 
# This depends on how docker-build.sh works.
# Let's assume it writes them to a file named images.txt

if [ ! -f "$output_file" ]; then
  echo "No images to push. Exiting."
  exit 1
fi

# Read the file and push each image
while IFS= read -r image; do
  push_image "$image"
done < "$output_file"

# Define color codes for summary
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Summary of Docker image pushes
echo "Summary of Docker image pushes:"

# Process successful pushes
if [ ${#successful_pushes[@]} -gt 0 ]; then
  echo -e "${GREEN}Successfully pushed images:${NC}"
  for image in "${successful_pushes[@]}"; do
    echo -e "  - ${GREEN}$image${NC}"
  done
else
  echo -e "${RED}No images were successfully pushed.${NC}"
fi

# Process failed pushes
if [ ${#failed_pushes[@]} -gt 0 ]; then
  echo -e "${RED}Failed to push images:${NC}"
  for image in "${failed_pushes[@]}"; do
    echo -e "  - ${RED}$image${NC}"
  done
else
  echo -e "${GREEN}There were no push failures.${NC}"
fi

#!/bin/bash

echo "Running in '$PWD'"

echo "Getting environment variables from ./docker.env file"
# Load environment variables from .env file
if [ -f docker.env ]; then
  export $(cat docker.env | grep -v '^#' | xargs)
else
  echo "Error: No ./docker.env file found"
  return
fi

echo "BASE_IMAGE_NAME is: $BASE_IMAGE_NAME"

echo $PWD
echo ./telegraf/*

### doesnt work for now: issues with the dockerfile readout
# Read environment variables from .env file# Read lines from .env file that do not start with #
# mapfile -t BUILD_ENV_VARS < <(grep -v '^#' .env)
# # Iterate over the array and pass each variable to Docker using --build-arg
# DOCKER_BUILD_ARGS=""
# for VAR in "${BUILD_ENV_VARS[@]}"; do
#     DOCKER_BUILD_ARGS+=" --build-arg $VAR"
# done

# Check if a relative base directory is provided as an argument
if [ $# -eq 0 ]; then
	echo "Usage: $0 <relative_base_dir> (not file path of Dockerfile)"
	echo "Example: $0 ./telegraf"
	exit 1
fi

echo $pwd

# allow the custom docker syntax
export DOCKER_BUILDKIT=1

# Relative base directory for Dockerfiles
BASE_DIR="$1"

# Check if the provided base directory exists
if [ ! -d "$BASE_DIR" ]; then
	echo "Error: The specified relative base directory '$BASE_DIR' does not exist."
	exit 1
fi

# Arrays to track failed and successful builds
FAILED_BUILDS=()
SUCCESSFUL_BUILDS=()
output_file="${PWD}/successful_builds.txt"
> "$output_file"  # Clear the file or create it if it doesn't exist
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
# Get current git branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch is: $CURRENT_BRANCH"

# Function to build a Docker image and check the exit code
build_images() {
	local dockerfiles=("$BASE_DIR"/Dockerfile.*)

	for dockerfile in "${dockerfiles[@]}"; do
		local dockerfile_name=$(basename "$dockerfile" .Dockerfile)
		local tag="${BASE_IMAGE_NAME}${dockerfile_name#Dockerfile.}:${CURRENT_BRANCH}"

		# Change the working directory to the Dockerfile's directory
		cd "$BASE_DIR" || exit 1

		echo "Changed to directory: $PWD"

		# Remove the BASE_DIR from the dockerfile variable
		dockerfile="${dockerfile#$BASE_DIR/}"

		# echo dry-run with yellow color
		echo -e "${YELLOW}docker build $DOCKER_BUILD_ARGS -f "$dockerfile" -t "$tag" .${NC}"

		# echo before execution with yellow color
		echo -e "${YELLOW}Building Docker image with tag: $tag${NC}"

		# Use BUILD_ENVIRONMENT_VARS instead of catting from .env
		docker build --progress=plain --no-cache $DOCKER_BUILD_ARGS -f "$dockerfile" -t "$tag" .


		if [ $? -ne 0 ]; then
			FAILED_BUILDS+=("$dockerfile" "$tag")
			echo -e "${RED}Build of $tag failed${NC}."
		else
			SUCCESSFUL_BUILDS+=("$dockerfile" "$tag")
			echo -e "${GREEN}Build of $tag completed successfully${NC}."  
			echo "Appending $tag to $output_file"
			echo "$tag" >> "$output_file"  # Append the successful tag to the file
		fi

		# Return to the original working directory
		cd - || exit 1
	done
}

# Build the Docker images
build_images

# Message at the end
if [ ${#SUCCESSFUL_BUILDS[@]} -gt 0 ]; then
	echo -e "All Docker image builds completed ${GREEN}successfully${NC}."
	for ((i = 0; i < ${#SUCCESSFUL_BUILDS[@]}; i += 2)); do
		printf -- "- ${GREEN}%s\t%s${NC}\n" "${SUCCESSFUL_BUILDS[i]}" "${SUCCESSFUL_BUILDS[i + 1]}"
	done | column -t -s $'\t'
fi

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
	echo -e "\nDocker image builds ${RED}failed${NC} for the following images, maybe they aren't in this dir:"
	for ((i = 0; i < ${#FAILED_BUILDS[@]}; i += 2)); do
		printf -- "- ${RED}%s\t%s${NC}\n" "${FAILED_BUILDS[i]}" "${FAILED_BUILDS[i + 1]}"
	done | column -t -s $'\t'
	exit 1
elif [ ${#SUCCESSFUL_BUILDS[@]} -gt 0 ]; then
	echo -e "${GREEN}All images built successfully.${NC}"  # Print success message in green
else
  echo -e " ${RED}General Failure${NC}"
fi
# Read environment variables from .env file# Read lines from .env file that do not start with #
mapfile -t env_vars < <(grep -v '^#' .env)
# Iterate over the array and pass each variable to Docker using --build-arg
DOCKER_BUILD_ARGS=""
for VAR in "${env_vars[@]}"; do
    DOCKER_BUILD_ARGS+=" --build-arg $VAR"
done

# Build your Docker image with the environment variables
echo docker build $DOCKER_BUILD_ARGS ./telegraf
docker build $DOCKER_BUILD_ARGS ./telegraf
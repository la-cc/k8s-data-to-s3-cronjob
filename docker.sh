#! /bin/bash
REGISTRY="ghcr.io/la-cc"

# check if git is installed
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit -1
fi

# get current tag information
IS_DEV_BUILD=$(git tag -l --contains HEAD)
GIT_TAG=$(git describe --abbrev=0 --tags HEAD)

if [ -z "$IS_DEV_BUILD" ]; then
    TIMESTAMP=$(date +%s)
    TAG=$(echo "$GIT_TAG"-"$TIMESTAMP")
else
    TAG=$GIT_TAG
fi

# check for container runtime to build image
if [ -x "$(command -v podman)" ]; then
    cli_cmd="podman"
elif [ -x "$(command -v docker)" ]; then
    cli_cmd="docker"
else
    echo "No container cli tool found! Aborting."
    exit -1
fi

echo "Building image with tag $TAG"

${cli_cmd} build . \
    -f build/docker/Dockerfile \
    -t $(echo "$REGISTRY/k8s-data-to-s3-cronjob:$TAG")

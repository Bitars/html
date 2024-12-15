#!/bin/bash
set -e

LANGUAGES=("c" "javascript" "python" "java" "befunge")

source /var/lib/jenkins/jenkins_config.env
BASE_IMAGE_DIR="/var/lib/jenkins/images"

CONFIG_FILE="/var/lib/jenkins/jenkins_config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Loading Jenkins configuration from $CONFIG_FILE..."
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

if [[ "$DOCKER_REGISTRY" != localhost:* ]]; then
    docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"
fi

for LANGUAGE in "${LANGUAGES[@]}"; do
    DOCKERFILE_PATH="${BASE_IMAGE_DIR}/${LANGUAGE}/Dockerfile.base"
    IMAGE_NAME="${DOCKER_REGISTRY}/whanos-${LANGUAGE}:latest"

    echo "Checking for Dockerfile: ${DOCKERFILE_PATH}"
    ls -l "${DOCKERFILE_PATH}" || echo "File not found!"

    if [[ -f "${DOCKERFILE_PATH}" ]]; then
        echo "Building and pushing image for ${LANGUAGE}..."
        docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" "${BASE_IMAGE_DIR}/${LANGUAGE}"
        docker push "${IMAGE_NAME}"
    else
        echo "Warning: Dockerfile.base not found for ${LANGUAGE}. Skipping..."
    fi
done

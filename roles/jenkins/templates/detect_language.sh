#!/bin/bash
set -e

REPO_DIR="$1"

if [ -z "$REPO_DIR" ]; then
    echo "Usage: $0 <REPO_DIR>"
    exit 1
fi

CONFIG_FILE="/var/lib/jenkins/jenkins_config.env"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Loading Jenkins configuration from $CONFIG_FILE..."
    source "$CONFIG_FILE"
    echo "Loaded REGISTRY: $DOCKER_REGISTRY"
    echo "Loaded DOCKER_USER: $DOCKER_USER"
    echo "Loaded DOCKER_PASS: $DOCKER_PASS"
else
    echo "Error: Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

if [[ -z "$DOCKER_REGISTRY" || -z "$DOCKER_USER" || -z "$DOCKER_PASS" ]]; then
    echo "Error: Missing required variables in '$CONFIG_FILE'!"
    exit 1
fi


LANGUAGE=""
if [[ -f "$REPO_DIR/Makefile" ]]; then
    LANGUAGE="c"
elif [[ -f "$REPO_DIR/app/pom.xml" ]]; then
    LANGUAGE="java"
elif [[ -f "$REPO_DIR/package.json" ]]; then
    LANGUAGE="javascript"
elif [[ -f "$REPO_DIR/requirements.txt" ]]; then
    LANGUAGE="python"
elif [[ $(find "$REPO_DIR/app" -type f -name "main.bf") ]]; then
    LANGUAGE="befunge"
else
    echo "Error: Unsupported language or structure in the repository."
    exit 1
fi

echo "Detected Language: ${LANGUAGE}"

IMAGE_NAME_BASE="${DOCKER_REGISTRY}/whanos-${LANGUAGE}:latest"
IMAGE_NAME_STANDALONE="${DOCKER_REGISTRY}/whanos-standalone-${LANGUAGE}:latest"

DOCKERFILE_BASE="/var/lib/jenkins/images/${LANGUAGE}/Dockerfile.base"
DOCKERFILE_STANDALONE="/var/lib/jenkins/images/${LANGUAGE}/Dockerfile.standalone"

if [[ -f "$REPO_DIR/Dockerfile" ]]; then
    echo "Detected a custom Dockerfile in the repository. Building with the base image."
    DOCKERFILE_USED="$REPO_DIR/Dockerfile"
    IMAGE_NAME="${IMAGE_NAME_BASE}"
else
    echo "No custom Dockerfile found. Using the standalone Dockerfile."
    if [[ -f "$DOCKERFILE_STANDALONE" ]]; then
        cp "$DOCKERFILE_STANDALONE" "${REPO_DIR}/Dockerfile"
        DOCKERFILE_USED="${REPO_DIR}/Dockerfile"
        IMAGE_NAME="${IMAGE_NAME_STANDALONE}"
    else
        echo "Error: No standalone Dockerfile available for language '${LANGUAGE}'."
        exit 1
    fi
fi

echo "Image Nam: ${IMAGE_NAME}"
echo "Using Dockerfile: ${DOCKERFILE_USED}"

if [[ "$DOCKER_REGISTRY" != localhost:* ]]; then
    echo "Logging in to Docker Hub..."
    docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"
fi

echo "Building Docker image ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" "${REPO_DIR}"

echo "Pushing Docker image ${IMAGE_NAME}..."
docker push "${IMAGE_NAME}"

echo "Docker image pushed successfully: ${IMAGE_NAME}"


export KUBECONFIG="/var/lib/jenkins/.kube/config"

WHANOS_FILE="$REPO_DIR/whanos.yml"
chmod +x /var/lib/jenkins/k3s.sh

K3S_SCRIPT="/var/lib/jenkins/k3s.sh"

if [[ -f "$WHANOS_FILE" ]]; then
    echo "Applying Kubernetes deployment from $WHANOS_FILE..."

    REPLICAS=$(yq e '.deployment.replicas' "$WHANOS_FILE" || echo "1")
    PORTS=$(yq e '.deployment.ports[]' "$WHANOS_FILE" 2>/dev/null || echo "3000")
    LIMIT_MEM=$(yq e '.deployment.resources.limits.memory' "$WHANOS_FILE" || echo "128M")
    REQ_MEM=$(yq e '.deployment.resources.requests.memory' "$WHANOS_FILE" || echo "64M")

    "$K3S_SCRIPT" "$IMAGE_NAME" "$REPLICAS" "$PORTS" "$LIMIT_MEM" "$REQ_MEM"

else
    echo "No whanos.yml found in $REPO_DIR. Skipping Kubernetes deployment."
    exit 0
fi

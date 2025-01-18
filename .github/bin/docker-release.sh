#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define repository details (customize these for your project)
export DOCKER_ORG="ajaykumar4"
export DOCKER_PROJECT="gitops-tools"
export DOCKER_REPO="${DOCKER_ORG}/${DOCKER_PROJECT}"

export GHCR_ORG="ajaykumar4"
export GHCR_PROJECT="gitops-tools"
export GHCR_REPO="ghcr.io/${GHCR_ORG}/${GHCR_PROJECT}"

# Determine Git Tag or Branch
if [[ $GITHUB_REF == refs/tags/* ]]; then
  export GIT_TAG=${GITHUB_REF#refs/tags/}
elif [[ $GITHUB_REF == refs/heads/* ]]; then
  export GIT_BRANCH=${GITHUB_REF#refs/heads/}
fi

# Function to build and push the image
build_and_push() {
  local VERSION=$1
  docker buildx build \
    --progress plain \
    --pull \
    --push \
    --platform "${DOCKER_BUILD_PLATFORM}" \
    -t "${DOCKER_REPO}:${VERSION}" \
    -t "${GHCR_REPO}:${VERSION}" .

  echo "Image built and pushed with version: ${VERSION}"
}

if [[ -n "${GIT_TAG}" ]]; then
  # Tag builds - use the provided tag
  build_and_push "${GIT_TAG}"
elif [[ "${GIT_BRANCH}" == "main" ]]; then
  # Main branch build - increment patch version
  # Get the current latest version from GHCR (more reliable for initial version)
  LATEST_VERSION=$(crane ls "ghcr.io/$GHCR_ORG/$GHCR_PROJECT" 2>/dev/null | sort -r | head -n 1)

  # If no version is found, default to 1.0.0
  if [[ -z "$LATEST_VERSION" ]]; then
    LATEST_VERSION="1.0.0"
  fi

  IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST_VERSION"
  NEW_PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

  build_and_push "${NEW_VERSION}"
  build_and_push "latest"  # Also build and push the latest tag
elif [[ -n "${GIT_BRANCH}" ]]; then
  # Other branch builds - use the branch name as the tag
  build_and_push "${GIT_BRANCH}"
else
  echo "No relevant branch or tag found. Skipping build."
fi
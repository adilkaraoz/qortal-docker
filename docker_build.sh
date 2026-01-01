#!/usr/bin/env bash
set -euo pipefail

# Builds Qortal Docker images with dynamic version and date tags.
# QORTAL_VERSION can be set to override auto-detection.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REPO="Qortal/qortal"
IMAGE_BASE="structi/qortal"

QORTAL_VERSION="${QORTAL_VERSION:-}"

if [[ -z "$QORTAL_VERSION" ]]; then
  echo "Detecting latest Qortal version from GitHub..."
  latest_location="$(curl -sI "https://github.com/${REPO}/releases/latest" \
    | tr -d '\r' \
    | awk 'tolower($1) == "location:" {print $2}' \
    | tail -n1)"

  if [[ -z "$latest_location" ]]; then
    echo "Could not determine latest release URL from GitHub." >&2
    exit 1
  fi

  QORTAL_VERSION="${latest_location##*/}"
  QORTAL_VERSION="${QORTAL_VERSION#v}"
fi

DATE_STAMP="$(date +%Y-%m-%d)"
TAG_SUFFIX="${QORTAL_VERSION}_bootstrap_${DATE_STAMP}"

echo "Building images with tag suffix: ${TAG_SUFFIX}"

docker build -t "${IMAGE_BASE}:${TAG_SUFFIX}" .
docker build --platform=linux/amd64 -t "${IMAGE_BASE}:${TAG_SUFFIX}-amd64" .

DEFAULT_ARCH="$(docker image inspect "${IMAGE_BASE}:${TAG_SUFFIX}" --format '{{.Architecture}}')"
AMD_ARCH="$(docker image inspect "${IMAGE_BASE}:${TAG_SUFFIX}-amd64" --format '{{.Architecture}}')"

echo "Default image architecture: ${DEFAULT_ARCH}"
echo "AMD64 image architecture: ${AMD_ARCH}"

docker tag "${IMAGE_BASE}:${TAG_SUFFIX}" "${IMAGE_BASE}:latest"
docker tag "${IMAGE_BASE}:${TAG_SUFFIX}-amd64" "${IMAGE_BASE}:latest-amd64"

if [[ -z "${DOCKER_USER_NAME:-}" || -z "${DOCKER_PASSWORD:-}" ]]; then
  echo "DOCKER_USER_NAME and DOCKER_PASSWORD must be set for login/push." >&2
  exit 1
fi

echo "Logging into Docker Hub as ${DOCKER_USER_NAME}..."
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USER_NAME}" --password-stdin

push_tags=(
  "${IMAGE_BASE}:${TAG_SUFFIX}"
  "${IMAGE_BASE}:${TAG_SUFFIX}-amd64"
  "${IMAGE_BASE}:latest"
  "${IMAGE_BASE}:latest-amd64"
)

for tag in "${push_tags[@]}"; do
  echo "Pushing ${tag}..."
  docker push "${tag}"
done

manifest_sources=("${IMAGE_BASE}:${TAG_SUFFIX}")
if [[ "${AMD_ARCH}" != "${DEFAULT_ARCH}" ]]; then
  manifest_sources+=("${IMAGE_BASE}:${TAG_SUFFIX}-amd64")
else
  echo "AMD64 build matches default architecture; using single-image manifest."
fi

if docker manifest inspect "${IMAGE_BASE}:latest" >/dev/null 2>&1; then
  docker manifest rm "${IMAGE_BASE}:latest" >/dev/null 2>&1 || true
fi

docker manifest create "${IMAGE_BASE}:latest" "${manifest_sources[@]}"
docker manifest push "${IMAGE_BASE}:latest"

echo "Multi-arch manifest pushed for ${IMAGE_BASE}:latest with: ${manifest_sources[*]}"

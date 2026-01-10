#!/bin/bash
set -e

# Build and push OpenEMR to private registry
# Registry: https://registry.trancloud.work (192.168.10.25:5000)

REGISTRY="registry.trancloud.work"
IMAGE_NAME="openemr-homelab"
TAG="${1:-latest}"  # Default to 'latest', or use first argument

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "=================================================="
echo "Building Production OpenEMR Image"
echo "=================================================="
echo "Registry: ${REGISTRY}"
echo "Image:    ${IMAGE_NAME}"
echo "Tag:      ${TAG}"
echo "Full:     ${FULL_IMAGE}"
echo "=================================================="

# Navigate to repository root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

echo ""
echo "Working directory: $(pwd)"
echo "Dockerfile: infrastructure/homelab/docker/Dockerfile"
echo ""

echo "Step 1: Building Docker image..."
echo "  This will:"
echo "  - Extend openemr/openemr:flex (all dependencies included)"
echo "  - Copy your source code"
echo "  - Run composer install + npm install + npm run build"
echo "  - Create optimized, production-ready image"
echo ""

docker build \
    --platform linux/amd64 \
    -f infrastructure/homelab/docker/Dockerfile \
    -t "${FULL_IMAGE}" \
    .

echo ""
echo "Step 2: Pushing to registry..."
docker push "${FULL_IMAGE}"

echo ""
echo "=================================================="
echo "✅ Success!"
echo "=================================================="
echo "Image pushed: ${FULL_IMAGE}"
echo ""
echo "To deploy:"
echo "  1. Update infrastructure/homelab/k8s/base/deployment.yaml:"
echo "     Change:"
echo "       image: openemr/openemr:flex"
echo "     To:"
echo "       image: ${FULL_IMAGE}"
echo ""
echo "  2. Apply changes:"
echo "     cd infrastructure/homelab"
echo "     kubectl apply -k k8s/overlays/dev"
echo ""
echo "  3. Future pods will start in 10-30 seconds!"
echo "     (Instead of 10-15 minutes)"
echo "=================================================="

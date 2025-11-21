#!/bin/bash
# Build RapidYencSharp multi-platform artifacts using podman
# This script builds the Docker image, extracts the artifacts, and displays build information

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="rapidyencsharp-build"
IMAGE_TAG="latest"
ARTIFACTS_DIR="$SCRIPT_DIR/artifacts"
CONTAINER_NAME="rapidyencsharp-temp-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if podman is available
if ! command -v podman &> /dev/null; then
    log_error "podman is not installed or not in PATH"
    log_info "Please install podman: https://podman.io/getting-started/installation"
    exit 1
fi

log_info "Using podman version: $(podman --version)"

# Clean up function
cleanup() {
    if podman container exists "$CONTAINER_NAME" &> /dev/null; then
        log_info "Cleaning up temporary container..."
        podman rm "$CONTAINER_NAME" &> /dev/null || true
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Step 1: Build the Docker image
log_info "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
log_info "This may take several minutes on first build..."
echo ""

if podman build --target build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"; then
    log_success "Docker image built successfully"
else
    log_error "Failed to build Docker image"
    exit 1
fi

echo ""

# Step 2: Create temporary container
log_info "Creating temporary container..."
if podman create --name "$CONTAINER_NAME" "${IMAGE_NAME}:${IMAGE_TAG}" /bin/true &> /dev/null; then
    log_success "Temporary container created: $CONTAINER_NAME"
else
    log_error "Failed to create temporary container"
    exit 1
fi

# Step 3: Extract artifacts
log_info "Extracting artifacts to: $ARTIFACTS_DIR"
rm -rf "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"

if podman cp "${CONTAINER_NAME}:/dist/." "$ARTIFACTS_DIR/"; then
    log_success "Artifacts extracted successfully"
else
    log_error "Failed to extract artifacts"
    exit 1
fi

# Step 4: Display artifact information
echo ""
log_info "Build artifacts summary:"
echo ""

if [ -d "$ARTIFACTS_DIR/packages" ]; then
    echo "📦 NuGet Packages:"
    find "$ARTIFACTS_DIR/packages" -type f -name "*.nupkg" -exec ls -lh {} \; | awk '{printf "  - %s (%s)\n", $9, $5}'
fi

echo ""

if [ -d "$ARTIFACTS_DIR/runtimes" ]; then
    echo "🔧 Native Libraries:"
    find "$ARTIFACTS_DIR/runtimes" -type f \( -name "*.so" -o -name "*.dll" -o -name "*.dylib" \) | while read -r file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        platform=$(echo "$file" | grep -oP 'runtimes/\K[^/]+')
        filename=$(basename "$file")

        # Get file type
        if command -v file &> /dev/null; then
            filetype=$(file -b "$file")
            echo "  - $platform/$filename ($size) - $filetype"
        else
            echo "  - $platform/$filename ($size)"
        fi
    done
fi

echo ""

if [ -d "$ARTIFACTS_DIR/lib" ]; then
    echo "📚 Managed Libraries:"
    find "$ARTIFACTS_DIR/lib" -type f \( -name "*.dll" -o -name "*.xml" -o -name "*.pdb" \) | while read -r file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        filename=$(basename "$file")
        echo "  - $filename ($size)"
    done
fi

echo ""
log_success "Build complete! Artifacts are available in: $ARTIFACTS_DIR"

# Optional: Display total size
if command -v du &> /dev/null; then
    total_size=$(du -sh "$ARTIFACTS_DIR" | awk '{print $1}')
    log_info "Total artifacts size: $total_size"
fi

echo ""
log_info "To use the NuGet package locally:"
echo "  dotnet add package RapidYencSharp --source $ARTIFACTS_DIR/packages"
echo ""
log_info "Or copy the native libraries to your runtime directories:"
echo "  cp -r $ARTIFACTS_DIR/runtimes/* <your-project>/runtimes/"

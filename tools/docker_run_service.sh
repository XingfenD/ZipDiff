#!/bin/bash

# Script to build and run docker services with custom entrypoint
# Usage: ./run-service.sh <service-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options] <service-name>"
    echo ""
    echo "Options:"
    echo "  -t, --target TARGET    Specify the build target for docker build"
    echo ""
    echo "Available services:"
    # Use relative path from script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local parsers_dir="$(dirname "$script_dir")/parsers"
    if [ -f "$parsers_dir/docker-compose.yml" ]; then
        grep -E "^\s+[0-9]+-" "$parsers_dir/docker-compose.yml" | sed 's/://g' | sed 's/^/  /'
    fi
    echo ""
    echo "Examples:"
    echo "  $0 05-ada-zip-ada"
    echo "  $0 07-c-libarchive"
    echo "  $0 01-infozip"
}

# Default build target
BUILD_TARGET=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            BUILD_TARGET="$2"
            shift 2
            ;;
        -*)  # Invalid option
            print_error "Invalid option: $1"
            show_usage
            exit 1
            ;;
        *)   # Service name (positional argument)
            break
            ;;
    esac
done

# Check if service name is provided
if [ $# -eq 0 ]; then
    print_error "Service name is required"
    show_usage
    exit 1
fi

SERVICE_NAME="$1"

# Get the script directory and parsers directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSERS_DIR="$(dirname "$SCRIPT_DIR")/parsers"
COMPOSE_FILE="$PARSERS_DIR/docker-compose.yml"

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Check if service exists in docker-compose.yml
if ! grep -q "^\s*$SERVICE_NAME:" "$COMPOSE_FILE"; then
    print_error "Service '$SERVICE_NAME' not found in docker-compose.yml"
    print_info "Available services:"
    grep -E "^\s+[0-9]+-" "$COMPOSE_FILE" | sed 's/://g' | sed 's/^/  /'
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    print_error "docker is not installed or not in PATH"
    exit 1
fi

print_info "Building service: $SERVICE_NAME"

# Change to the parsers directory
cd "$PARSERS_DIR"

# Determine image tag (use BUILD_TARGET if provided, otherwise use latest)
IMAGE_TAG="${BUILD_TARGET:-latest}"

# Prepare build options
BUILD_OPTIONS=""
if [ ! -z "$BUILD_TARGET" ]; then
    BUILD_OPTIONS="--target $BUILD_TARGET"
    print_info "Build target: $BUILD_TARGET"
fi

# Build the image using docker directly
if docker build -f "$SERVICE_NAME/Dockerfile" -t "localhost/parsers_${SERVICE_NAME}:$IMAGE_TAG" $BUILD_OPTIONS "$PARSERS_DIR"/"$SERVICE_NAME"; then
    print_success "Build completed successfully"
else
    print_error "Build failed"
    exit 1
fi

# Get the image name
IMAGE_NAME="localhost/parsers_${SERVICE_NAME}:$IMAGE_TAG"

# Extract volume mappings from docker-compose.yml for specific service
VOLUMES=$(awk -v service="$SERVICE_NAME" '
    $0 ~ "^[ ]*" service ":" { found=1; next }
    found && $0 ~ "^[ ]*volumes:" {
        getline
        while ($0 ~ "^[ ]*-") {
            gsub(/^[ ]*-[ ]*/, "", $0)
            print $0
            if (getline <= 0) break
        }
        exit
    }
    found && $0 !~ "^[ ]*volumes:" && $0 !~ "^[ ]*$" && $0 !~ "^[ ]*build:" && $0 !~ "^[ ]*image:" && $0 !~ "^[ ]*ports:" && $0 !~ "^[ ]*environment:" { exit }
' "$COMPOSE_FILE" | tr '\n' ' ')

echo "Volumes: $VOLUMES"

# Create output directories if they don't exist
if [ ! -z "$VOLUMES" ]; then
    for volume in $VOLUMES; do
        # Parse volume format: /host/path:/container[:ro]
        # Extract container path (last field after splitting by ':')
        container_path=$(echo "$volume" | awk -F':' '{print $NF}')

        # Check if this is an output directory (starts with /output) and not read-only
        if [[ "$container_path" == /output* ]] && [[ "$volume" != *":ro" ]]; then
            # Extract host path (first field after splitting by ':')
            host_path=$(echo "$volume" | awk -F':' '{print $1}')

            # Create host directory if it doesn't exist
            if [ ! -d "$host_path" ]; then
                print_info "Creating output directory: $host_path"
                mkdir -p "$host_path"
            fi
        fi
    done
fi

# Build the docker run command
RUN_CMD="docker run --rm -it --entrypoint /bin/sh"
SHOW_CMD="docker run --rm"

# Add volume mappings
if [ ! -z "$VOLUMES" ]; then
    # Add -v flag for each volume mapping
    for volume in $VOLUMES; do
        RUN_CMD="$RUN_CMD -v $volume"
        SHOW_CMD="$SHOW_CMD -v $volume"
    done
fi

# Add the image name
RUN_CMD="$RUN_CMD $IMAGE_NAME"
SHOW_CMD="$SHOW_CMD $IMAGE_NAME"

print_success "Service built successfully!"
print_info "Image: $IMAGE_NAME"
echo ""
print_info "Generated run command:"
echo -e "${GREEN}$RUN_CMD${NC}"
print_info "Other useful command:"
echo -e "${GREEN}$SHOW_CMD${NC}"
echo ""
print_info "To run the command, copy and execute the above command"
print_info "Or let me run it for you? (y/n)"

read -r -p "Run the command now? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Executing command..."
    eval "$RUN_CMD"
fi
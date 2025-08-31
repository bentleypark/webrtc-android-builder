#!/bin/bash

# WebRTC AAR Automatic Download Script
# Downloads the latest build artifacts using GitHub CLI.

set -euo pipefail

# Color settings
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help message
show_help() {
    cat << EOF
WebRTC AAR Automatic Download Script

Usage: $0 [OPTIONS]

Options:
  -r, --repo REPO         GitHub Repository (e.e.g., username/webrtc-android-builder)
  -o, --output DIR        Output directory (default: current directory)
  -l, --list              Only list available artifacts
  -h, --help              Show this help message

Prerequisites:
  - GitHub CLI (gh) installed and authenticated
  - Repository access permissions required

Example:
  $0 -r username/webrtc-android-builder -o ~/Downloads
  $0 --list -r username/webrtc-android-builder

GitHub CLI Installation:
  brew install gh
  gh auth login

EOF
}

# Default values
REPO=""
OUTPUT_DIR="."
LIST_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Essential checks
if [[ -z "$REPO" ]]; then
    log_error "Repository must be specified. Use -r or --repo option."
    show_help
    exit 1
fi

# Check GitHub CLI installation
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed."
    log_info "Installation method: brew install gh"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI authentication is required."
    log_info "Authentication method: gh auth login"
    exit 1
fi

# Get workflow run list
log_info "Fetching workflow run list..."
RUNS=$(gh run list --repo "$REPO" --workflow "build-webrtc-android.yml" --status completed --limit 10 --json databaseId,headBranch,conclusion,createdAt,displayTitle)

if [[ -z "$RUNS" || "$RUNS" == "[]" ]]; then
    log_error "No completed workflow runs found."
    log_info "Please ensure there are successfully completed builds in the repository."
    exit 1
fi

# Filter for successful runs
SUCCESS_RUNS=$(echo "$RUNS" | jq '[.[] | select(.conclusion == "success")]')

if [[ "$SUCCESS_RUNS" == "[]" ]]; then
    log_error "No successful workflow runs found."
    exit 1
fi

# Get the latest successful run
LATEST_RUN_ID=$(echo "$SUCCESS_RUNS" | jq -r '.[0].databaseId')
LATEST_RUN_TITLE=$(echo "$SUCCESS_RUNS" | jq -r '.[0].displayTitle')
LATEST_RUN_DATE=$(echo "$SUCCESS_RUNS" | jq -r '.[0].createdAt')

log_info "Latest successful build info:"
echo "  📋 Title: $LATEST_RUN_TITLE"
echo "Artifact ID: $ARTIFACT_ID"  
echo "  📅 Date: $LATEST_RUN_DATE"

# Display artifact list only and exit
if [[ "$LIST_ONLY" == "true" ]]; then
    log_info "Available artifacts:"
    gh run view "$LATEST_RUN_ID" --repo "$REPO" --log-failed
    exit 0
fi

# Get artifact list
log_info "Fetching artifact list..."
ARTIFACTS=$(gh api "repos/$REPO/actions/runs/$LATEST_RUN_ID/artifacts" --jq '.artifacts[] | select(.name | startswith("webrtc-android-aar"))')

if [[ -z "$ARTIFACTS" ]]; then
    log_error "WebRTC AAR artifact not found."
    exit 1
fi

# Extract first artifact info
ARTIFACT_NAME=$(echo "$ARTIFACTS" | jq -r '.name' | head -1)
ARTIFACT_SIZE=$(echo "$ARTIFACTS" | jq -r '.size_in_bytes' | head -1)
ARTIFACT_SIZE_MB=$((ARTIFACT_SIZE / 1024 / 1024))

log_info "Artifact to download:"
echo "  📦 Name: $ARTIFACT_NAME"
echo "  📏 Size: ${ARTIFACT_SIZE_MB}MB"

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# Download artifact
log_info "Downloading artifact... (Location: $OUTPUT_DIR)"
if gh run download "$LATEST_RUN_ID" --repo "$REPO" --name "$ARTIFACT_NAME"; then
    log_info "✅ Download complete!"
    
    # Extract archive
    if [[ -f "${ARTIFACT_NAME}.zip" ]]; then
        log_info "Extracting archive..."
        unzip -o "${ARTIFACT_NAME}.zip"
        rm "${ARTIFACT_NAME}.zip"
    fi
    
    # Check result
    if [[ -f "libwebrtc.aar" ]]; then
        AAR_SIZE=$(stat -f%z "libwebrtc.aar" 2>/dev/null || stat -c%s "libwebrtc.aar" 2>/dev/null)
        AAR_SIZE_MB=$((AAR_SIZE / 1024 / 1024))
        
        log_info "🎉 WebRTC AAR download successful!"
        echo "  📁 Location: $(pwd)/libwebrtc.aar"
        echo "  📏 Size: ${AAR_SIZE_MB}MB"
        
        if [[ -f "build-info.txt" ]]; then
            echo "  📋 Build Info: $(pwd)/build-info.txt"
            echo ""
            echo "=== Build Info ==="
            head -20 build-info.txt
        fi
        
        echo ""
        log_info "How to integrate into Android project:"
        echo "  1. Copy AAR file to app/libs/ folder"
        echo "  2. Add dependency to build.gradle: implementation files('libs/libwebrtc.aar')"
        echo "  3. Set minSdk to 24 (for 16KB page support)"
        
    else
        log_error "libwebrtc.aar file not found."
        exit 1
    fi
else
    log_error "Download failed"
    exit 1
fi

#!/bin/bash
set -e

# Parse arguments
FLM_GIT_REF=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --git-ref|-r)
            FLM_GIT_REF="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--git-ref <ref>|-r <ref>]"
            exit 1
            ;;
    esac
done

# Get FastFlowLM version from GitHub API (with fallback) or specified git ref
if [ -n "$FLM_GIT_REF" ]; then
    # Use the specified git reference (commit hash, tag, or branch)
    FLM_VERSION="$FLM_GIT_REF"
    echo "Using specified git reference: ${FLM_VERSION}"
else
    FLM_VERSION=$(curl -s https://api.github.com/repos/FastFlowLM/FastFlowLM/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    FLM_VERSION=${FLM_VERSION:-v0.9.34}  # fallback if curl fails
fi

# Get GitHub username from gh CLI or use env variable
if command -v gh &> /dev/null; then
    USERNAME=$(gh config get user -h github.com)
else
    USERNAME=${GH_USERNAME:?Error: Set GH_USERNAME env var or install gh CLI}
fi

echo "Building FastFlowLM Docker image..."
echo "  Version: ${FLM_VERSION}"
echo "  Registry: ghcr.io/${USERNAME}/fastflowlm"

# Build and push with both version tag and latest tag
docker buildx build --push \
    --build-arg FLM_VERSION=${FLM_VERSION} \
    -t ghcr.io/${USERNAME}/fastflowlm:${FLM_VERSION} \
    -t ghcr.io/${USERNAME}/fastflowlm:latest \
    .

echo "✓ Pushed successfully!"
echo "  ghcr.io/${USERNAME}/fastflowlm:${FLM_VERSION}"
echo "  ghcr.io/${USERNAME}/fastflowlm:latest"

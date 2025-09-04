#!/bin/sh

check_latest_version() {
    response=$(curl -s -f https://api.github.com/repos/cloudflare/cloudflared/releases/latest)
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        echo "Error: Failed to fetch latest version info from GitHub." >&2
        exit 2
    fi
    latest_version=$(echo "$response" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    # Validate version string (should start with 'v' and contain digits)
    if ! echo "$latest_version" | grep -Eq '^v[0-9]+'; then
        echo "Error: Malformed or missing version string in GitHub response." >&2
        exit 3
    fi
    echo "$latest_version"
}

get_current_version() {
    if ! command -v cloudflared >/dev/null 2>&1; then
        echo "Error: cloudflared is not installed or not in PATH." >&2
        exit 2
    fi
    version_output=$(cloudflared -v 2>/dev/null | head -n 1)
    # Extract version using regex, expecting format like 'cloudflared version 2024.6.0 (build xyz)'
    version=$(echo "$version_output" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ -z "$version" ]; then
        echo "Error: Unable to determine cloudflared version from output: $version_output" >&2
        exit 3
    fi
    echo "$version"
}

update_cloudflared() {
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "amd64" ]; then
        curl -# -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    elif [ "$ARCH" = "arm64" ]; then
        curl -# -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
    dpkg -i cloudflared.deb
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install cloudflared.deb with dpkg."
        rm -f cloudflared.deb
        exit 1
    fi
    rm cloudflared.deb
}

# Main script logic
latest_version=$(check_latest_version)
current_version=$(get_current_version)

if [ "$latest_version" != "$current_version" ]; then
    echo "A new version of cloudflared is available: $latest_version (current version: $current_version)"
    
    # Check for auto-update environment variable or interactive mode
    if [ "$CLOUDFLARED_AUTO_UPDATE" = "true" ]; then
        echo "Auto-updating cloudflared to version $latest_version"
        update_cloudflared
        echo "cloudflared has been updated to version $latest_version"
    else
        echo "cloudflared update skipped. Set CLOUDFLARED_AUTO_UPDATE=true to enable automatic updates."
    fi
else
    echo "cloudflared is already up to date (version: $current_version)"
fi
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
    cloudflared -v | head -n 1 | awk '{print $3}'
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
        read -p "Would you like to update to the latest version? (y/n): " choice
        if [ "$choice" = "y" ]; then
            update_cloudflared
            echo "cloudflared has been updated to version $latest_version"
        else
            echo "cloudflared update skipped"
        fi
    fi
else
    echo "cloudflared is already up to date (version: $current_version)"
fi
#!/bin/sh

check_latest_version() {
    curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
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
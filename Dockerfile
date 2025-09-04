FROM nginx

# Install necessary packages
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 \
    ca-certificates \
    curl \
    iproute2 \
    vim-tiny \
  && apt-get upgrade -y \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists

# Determine architecture and download the appropriate cloudflared package
RUN ARCH=$(dpkg --print-architecture) \
  && if [ "$ARCH" = "amd64" ]; then \
       curl -# -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb; \
     elif [ "$ARCH" = "arm64" ]; then \
       curl -# -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb; \
     else \
       echo "Unsupported architecture: $ARCH"; exit 1; \
     fi \
  && dpkg -i cloudflared.deb \
  && rm cloudflared.deb

RUN mkdir -p /etc/nginx/templates
COPY 40-entrypoint-cloudflared.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/40-entrypoint-cloudflared.sh
COPY nginx-default.conf.template /etc/nginx/templates/default.conf.template

# Copy check-cloudflared-update.sh into the container
COPY check-cloudflared-update.sh /check-cloudflared-update.sh
RUN chmod +x /check-cloudflared-update.sh
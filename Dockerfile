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

RUN curl -# -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
  && dpkg -i cloudflared.deb \
  && rm cloudflared.deb

RUN mkdir -p /etc/nginx/templates
COPY 40-entrypoint-cloudflared.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoiny.d/40-entrypoint-cloudflared.sh
COPY nginx-default.conf.template /etc/nginx/templates/default.conf.template

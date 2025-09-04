# Ollama Proxy - GitHub Copilot Instructions

Ollama Proxy is a Dockerized Nginx reverse proxy that provides authenticated access to a local Ollama AI service through Cloudflare Tunnel. The proxy includes CORS support, authentication via Bearer tokens, and secure internet exposure.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Prerequisites and Dependencies
- **Docker and Docker Compose**: Required for building and running the proxy
- **Cloudflare Account**: Needed to obtain a Cloudflare Tunnel token (see `docs/cloudflare.md`)
- **Ollama Service**: Must be running on the host machine at port `11434`

### Quick Start Commands
1. **Clone and setup environment**:
   ```bash
   git clone https://github.com/kesor/ollama-proxy.git
   cd ollama-proxy
   cp .env.secret-example .env.secret
   # Edit .env.secret with your actual tokens
   ```

2. **Build the Docker image**:
   ```bash
   docker compose build
   ```
   **IMPORTANT**: The default Dockerfile has an SSL certificate issue when downloading cloudflared. **NEVER CANCEL** the build process - it will fail within 10-15 seconds due to SSL cert issues.

   **WORKAROUND**: If the build fails with SSL certificate errors, modify the curl command in the Dockerfile temporarily by adding the `-k` flag:
   ```bash
   # Change line ~19 in Dockerfile from:
   curl -# -L --output cloudflared.deb https://...
   # To:
   curl -k -# -L --output cloudflared.deb https://...
   ```

### Expected Build Behavior
**IMPORTANT**: The default `docker compose build` **WILL FAIL** due to SSL certificate issues. This is expected behavior.

**Working Build Process**:
1. First build attempt will fail with SSL errors (expected)
2. Modify Dockerfile to add `-k` flag to curl commands
3. Rebuild successfully

3. **Run the service**:
   ```bash
   docker compose up -d
   ```

4. **Check logs**:
   ```bash
   docker compose logs
   ```

### Build Process Details
- **Docker build time**: 2-3 seconds (with layer caching), 5-10 seconds (fresh build)
- **NEVER CANCEL**: While builds are generally fast, always set timeout to 120+ seconds for Docker commands
- **Common failure**: SSL certificate issues when downloading cloudflared from GitHub releases

### Known Build Issues and Solutions
1. **SSL Certificate Error**: The original Dockerfile fails with SSL certificate validation errors:
   ```
   curl: (60) SSL certificate problem: self-signed certificate in certificate chain
   ```
   **Solution**: Add `-k` flag to curl commands in Dockerfile lines 19 and 21:
   ```dockerfile
   curl -k -# -L --output cloudflared.deb https://github.com/...
   ```

2. **Environment File Missing**: Docker Compose fails if `.env.secret` doesn't exist:
   ```
   env file .env.secret not found
   ```
   **Solution**: Always create `.env.secret` from `.env.secret-example` before running

3. **Environment Variable Caching**: Docker Compose may cache environment values between runs:
   ```
   # After changing .env.secret, always restart completely
   docker compose down
   docker compose up -d
   ```

### Environment Configuration
- **Required file**: `.env.secret` (copy from `.env.secret-example`)
- **Required variables**:
  ```bash
  CLOUDFLARE_TUNNEL_TOKEN="your_actual_tunnel_token"
  OLLAMA_SECRET_API_KEY="sk-your_custom_secret_key"
  ```
- **Security**: The `.env.secret` file is in `.gitignore` and should never be committed

### Running and Testing
1. **Start the service**:
   ```bash
   docker compose up -d
   ```

2. **Test basic connectivity** (requires valid tokens):
   ```bash
   curl https://your-domain.com/api/version \
     -H "Authorization: Bearer your_secret_api_key"
   ```

3. **Test authentication** (should return 401):
   ```bash
   curl https://your-domain.com/api/version \
     -H "Authorization: Bearer wrong_key"
   ```

4. **Test full API functionality**:
   ```bash
   curl -i https://your-domain.com/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer your_secret_api_key" \
     -d '{
       "model":"llama3.2",
       "messages":[
         {"role":"system","content":"You are a helpful assistant."},
         {"role":"user","content":"Test prompt."}
       ],
       "temperature":1,
       "max_tokens":10,
       "stream":false
     }'
   ```

## Validation Scenarios

**ALWAYS test these scenarios after making changes:**

1. **Authentication Test**:
   - Valid token should return 502 (if no Ollama backend) or 200 (if Ollama is running)
   - Invalid token should return 401 Unauthorized
   - Missing token should return 401 Unauthorized

2. **CORS Test**:
   - OPTIONS requests should work without authentication
   - Proper CORS headers should be present in responses

3. **Container Health**:
   - Check logs for nginx startup messages
   - Verify cloudflared connection (will show token errors with dummy tokens)
   - Ensure no nginx configuration errors

4. **Template Processing**:
   - Verify that `${OLLAMA_SECRET_API_KEY}` gets replaced in nginx config
   - Check `/etc/nginx/conf.d/default.conf` inside container for proper substitution

## Architecture and Key Files

### Core Components
- **`Dockerfile`**: Multi-stage build with nginx base, cloudflared installation, and configuration
- **`docker-compose.yml`**: Service orchestration with networking and capabilities
- **`nginx-default.conf.template`**: Nginx configuration template with environment variable substitution
- **`40-entrypoint-cloudflared.sh`**: Script to start cloudflared tunnel process
- **`.env.secret-example`**: Template for required environment variables

### Directory Structure
```
.
├── Dockerfile                    # Container definition
├── docker-compose.yml            # Service orchestration
├── nginx-default.conf.template   # Nginx config template
├── 40-entrypoint-cloudflared.sh  # Cloudflared startup script
├── .env.secret-example            # Environment variables template
├── README.md                     # Main documentation
├── docs/                         # Additional documentation
│   ├── cloudflare.md            # Cloudflare tunnel setup guide
│   └── *.png                    # Cloudflare setup diagrams
└── .github/                     # GitHub configuration
    └── copilot-instructions.md  # This file
```

### Nginx Configuration Details
- **Authentication**: Bearer token validation using nginx map directives
- **CORS**: Full CORS support for web clients
- **Proxy**: Forwards requests to `host.docker.internal:11434` (Ollama service)
- **Timeouts**: 600-second timeouts for long-running AI requests

## Common Tasks and Troubleshooting

### Debugging Build Issues
1. **SSL Certificate Errors**:
   ```bash
   # Add -k flag to curl commands in Dockerfile
   curl -k -# -L --output cloudflared.deb https://...
   ```

2. **Check Docker Images**:
   ```bash
   docker images | grep ollama-proxy
   docker inspect ollama-proxy
   ```

### Debugging Runtime Issues
1. **Check container logs**:
   ```bash
   docker compose logs ollama-proxy
   ```

2. **Check nginx configuration**:
   ```bash
   docker compose exec ollama-proxy cat /etc/nginx/conf.d/default.conf
   ```

3. **Test nginx config syntax**:
   ```bash
   docker compose exec ollama-proxy nginx -t
   ```

4. **Check cloudflared status**:
   ```bash
   docker compose exec ollama-proxy ps aux | grep cloudflared
   ```

### Environment Issues
1. **Missing .env.secret**: Copy from `.env.secret-example` and populate with real values
2. **Invalid Cloudflare token**: Check token format and tunnel configuration
3. **Invalid API key**: Ensure consistent format (typically starts with `sk-`)

### Network Issues
1. **502 Bad Gateway**: Usually means Ollama is not running on host port 11434
2. **401 Unauthorized**: Check API key format and nginx template processing
3. **Connection refused**: Verify Docker networking and host.docker.internal resolution

## Development Workflow

### Making Changes
1. **Always test locally first**:
   ```bash
   # Build with your changes
   docker compose build
   # Test with dummy tokens
   docker compose up
   ```

2. **Validate configuration**:
   ```bash
   # Check generated nginx config
   docker compose exec ollama-proxy nginx -t
   ```

3. **Test authentication flow**:
   ```bash
   # Test valid token (should get 502 if no Ollama backend)
   curl -i localhost:8080/api/version -H "Authorization: Bearer sk-test"
   # Test invalid token (should get 401)
   curl -i localhost:8080/api/version -H "Authorization: Bearer wrong"
   ```

### File Modification Guidelines
- **Dockerfile**: Be careful with curl SSL flags; test thoroughly
- **nginx template**: Remember that `${VARIABLE}` gets substituted by Docker
- **docker-compose.yml**: Maintain networking configuration for host.docker.internal
- **Environment files**: Never commit actual secrets

## Expected Timings and Timeouts

### Build Operations
- **Docker build**: 2-3 seconds (cached), 5-10 seconds (fresh build)
- **Docker compose up**: 1-2 seconds for startup
- **TIMEOUT RECOMMENDATION**: Always use 120+ seconds for Docker operations to handle network delays

### Runtime Operations
- **Nginx startup**: 1-2 seconds
- **Cloudflared connection**: 2-5 seconds (with valid token)
- **API response**: 1-30 seconds (depending on Ollama model and request)

### NEVER CANCEL Operations
- **Docker builds**: Even if they seem slow, let them complete
- **Container startup**: Allow full initialization cycle
- **API requests**: AI model responses can take 10-30 seconds

## Security Considerations

### Authentication
- Proxy requires valid Bearer token in Authorization header
- OPTIONS requests allowed without authentication (for CORS preflight)
- Invalid requests return 401 Unauthorized

### Network Security
- All external traffic encrypted via Cloudflare Tunnel
- Local container communication over HTTP (isolated network)
- Host machine Ollama service accessed via Docker networking

### Token Management
- API keys should start with `sk-` by convention
- Cloudflare tunnel tokens are long base64-encoded strings
- Never commit real tokens to version control (.env.secret is gitignored)
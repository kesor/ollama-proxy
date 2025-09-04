# Ollama Proxy with Nginx and Cloudflare Tunnel

This project provides a Dockerized Nginx server configured to act as a
reverse proxy for [Ollama](https://github.com/jmorganca/ollama), a local
AI model serving platform. The proxy includes built-in authentication
using a custom `Authorization` header and exposes the Ollama service
over the internet using a Cloudflare Tunnel.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Authorization Token](#authorization-token)
  - [Cloudflare Tunnel Token](#cloudflare-tunnel-token)
  - [Environment Variables](#environment-variables)
- [Usage](#usage)
- [Testing the Service](#testing-the-service)
- [Renaming Ollama Models](#renaming-ollama-models)
- [Files in this Project](#files-in-this-project)
- [License](#license)

## Features

- **Nginx Reverse Proxy**: Proxies requests to Ollama running on the host machine at port `11434`.
- **Authentication**: Requires clients to provide a specific `Authorization` header to access the service.
- **CORS Support**: Configured to handle Cross-Origin Resource Sharing (CORS) for web-based clients.
- **Cloudflare Tunnel Integration**: Exposes the local Ollama service securely over the internet using Cloudflare Tunnel.
- **Dockerized Setup**: Easily deployable using Docker and Docker Compose.

## Prerequisites

- **Docker and Docker Compose**: Ensure Docker and Docker Compose are installed on your system.
- **Cloudflare Account**: Required to get a Cloudflare Tunnel token. Review the [cloudflare doc](./docs/cloudflare.md) for more details.
- **Ollama**: Install and run [Ollama](https://github.com/jmorganca/ollama) on your host machine at port `11434`.

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/kesor/ollama-proxy.git
   cd ollama-proxy
   ```

2. **Copy and Configure Environment Variables**

   Copy the example environment file and modify it with your own values:

   ```bash
   cp .env.secret-example .env.secret
   ```

   Edit `.env.secret` and set your Cloudflare Tunnel token and Ollama secret API key:

   ```bash
   CLOUDFLARE_TUNNEL_TOKEN="your_cloudflare_tunnel_token"
   OLLAMA_SECRET_API_KEY="your_made_up_ollama_secret_api_key"
   ```

## Configuration

### Authorization Token

- **Environment Variable**: `OLLAMA_SECRET_API_KEY`
- **Usage**: This token is required in the `Authorization` header for clients to access the Ollama service through the proxy.
- **Format**: Typically starts with `sk-` followed by your made-up secret key.

### Cloudflare Tunnel Token

- **Environment Variable**: `CLOUDFLARE_TUNNEL_TOKEN`
- **How to Obtain**: Log in to your Cloudflare Zero Trust account and [create a tunnel](https://www.cloudflare.com/products/tunnel/) to get the token.

### Environment Variables

The project uses a `.env.secret` file to manage sensitive environment variables.

- **`.env.secret`**: Contains the following variables:

  ```bash
  CLOUDFLARE_TUNNEL_TOKEN="your_cloudflare_tunnel_token"
  OLLAMA_SECRET_API_KEY="your_made_up_ollama_secret_api_key"
  ```

## Usage

1. **Build and Run the Docker Container Using Docker Compose**

   ```bash
   docker-compose up -d
   ```

   This command will build the Docker image and start the container defined in `docker-compose.yml`.

2. **Look at the logs for signs of any errors**

   ```bash
   docker-compose logs
   ```

3. **Access the Ollama Service**

   - The service is now exposed over the internet via the Cloudflare Tunnel.
   - Clients must include the correct `Authorization` header in their requests.

## Testing the Service

You can test the setup using the following methods:

### Basic Connectivity Test

For a simple connectivity test, you can use the `/api/version` endpoint:

```bash
curl https://opxy.example.net/api/version \
  -H "Authorization: Bearer your_made_up_ollama_secret_api_key"
```

This endpoint provides a quick way to verify that the proxy is working and can connect to the Ollama service.

### Full API Test

For a complete API functionality test, you can use the `/v1/chat/completions` endpoint:

```bash
curl -i https://opxy.example.net/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_made_up_ollama_secret_api_key" \
  -d '{
    "model":"llama3.2",
    "messages":[
      {"role":"system","content":"You are a helpful assistant."},
      {"role":"user","content":"Test prompt to check your response."}
    ],
    "temperature":1,
    "max_tokens":10,
    "stream":false
  }'
```

Replace `your_made_up_ollama_secret_api_key` with your made-up secret API key in both examples.

## Renaming Ollama Models

For systems that expect OpenAI's models to "be there," it is useful to
rename Ollama models by copying them to a new name using the Ollama CLI.

For example:

```bash
ollama cp llama3.2:3b-instruct-fp16 gpt-4o
```

This command copies the model `llama3.2:3b-instruct-fp16` to a new model
named `gpt-4o`, making it easier to reference in API requests.

## Files in this Project

- **`Dockerfile`**: The Dockerfile used to build the Docker image.
- **`docker-compose.yml`**: Docker Compose configuration file to set up the container.
- **`nginx-default.conf.template`**: Template for the Nginx configuration file.
- **`40-entrypoint-cloudflared.sh`**: Entry point script to install and start Cloudflare Tunnel.
- **`.env.secret-example`**: Example environment file containing placeholders for sensitive variables.

## Privacy Considerations

This project relies on Cloudflare as a middleman for the Cloudflare Tunnel. If you trust Cloudflare, the setup ensures that no one else can eavesdrop on your traffic or access your data.

- **SSL Encryption**: The public endpoint opened by Cloudflare has SSL enabled, meaning that any communication between your computer and this endpoint is encrypted.
- **Cloudflare Tunnel Encryption**: Requests received at the Cloudflare endpoint are securely forwarded to your local Nginx instance through Cloudflare's tunnel service, which also encrypts this communication.
- **Local Network Traffic**: Inside the container, requests between the Cloudflare tunnel process and Nginx, as well as between Nginx and the Ollama process, occur over the local device network in clear text over HTTP. Since this traffic stays within the local network, it is not exposed externally.

If privacy beyond this is a concern, note that local traffic within the container is not encrypted, although it is isolated from external networks.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Note**: The Nginx configuration has been carefully set up to handle CORS
headers appropriately. You can refer to the `nginx-default.conf.template`
file to understand the specifics.

**Disclaimer**: Replace placeholders like `your_cloudflare_tunnel_token`,
`your_ollama_secret_api_key`, and `opxy.example.net` with your actual values.

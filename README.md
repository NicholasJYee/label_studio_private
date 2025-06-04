# Private Label Studio with online access

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/label-studio-private)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

This project provides a free, secure, containerized setup of Label Studio with NGINX reverse proxy and ngrok tunneling for public access. It's designed for secure data labeling workflows with proper authentication and HTTPS support.

> This project is a privacy-focused fork of [Label Studio](https://github.com/HumanSignal/label-studio), a multi-type data labeling and annotation tool with standardized output format.

## Privacy-Preserving Architecture

This Label Studio setup is designed for installation on a single, protected workstation where all source images and annotations remain resident on the local disk. Nothing is synchronized to external cloud storage (unless explicitly configured). Authenticated collaborators reach the application through a short-lived, TLS-encrypted ngrok tunnel, so the browser session is streamed, not copied. Bulk file download endpoints are disabled, preventing wholesale export of sensitive data.

Consequently, apart from ad-hoc screen captures performed by end-users, protected data never leaves the host computer, satisfying strict data-sovereignty requirements while still permitting global, permission-gated access to the labeling interface.

No liability is assumed for any data loss or security breaches. Use at your own risk.

## Features

- 🔒 Secure setup with NGINX reverse proxy and basic authentication
- 🌐 Public access via ngrok tunneling with HTTPS
- 📦 Containerized deployment using Docker/Podman
- 📁 Local file serving support
- 🛡️ CSRF protection and secure origins
- 🔐 Local-first architecture
- 🚫 Disabled bulk data export functionality (annotations can be exported)
- 🔄 Short-lived, encrypted tunnels for secure access

## Prerequisites

- Docker or Podman installed
- [ngrok account](https://ngrok.com/signup) (minimum requirement: free tier)
  - Sign up for a free account at ngrok.com
  - Get your authtoken from the ngrok dashboard

## Environment Setup

Create the data directory and .env file:
```bash
mkdir -p data
touch .env
```

Update the .env file with the following variables:

```bash
# Label Studio admin credentials
LS_ADMIN_EMAIL=your-email@example.com
LS_ADMIN_PASSWORD=your-secure-password

# ngrok configuration (optional)
NGROK_AUTHTOKEN=your-ngrok-authtoken
```

## Building and Running

### Build the Image

```bash
podman build -t labelstudio .
```

### Run the Container

```bash
podman run -d \
  --replace \
  --name ls \
  --env-file .env \
  -p 8080:8080 \
  -v "$PWD/data:/home/secureuser/data:rw" \
  labelstudio
```

### Container Management

- **Start container:**
  ```bash
  podman start ls
  ```

- **Stop container:**
  ```bash
  podman stop ls
  ```

- **View logs (to find the ngrok public URL):**
  ```bash
  podman logs ls
  ```

## Accessing Label Studio

1. The container exposes Label Studio on port 8080
2. Access is protected by basic authentication (username: `admin`, password: from `.env`)
3. The dynamically generated public URL is available in the container logs (ngrok)
4. The URL changes each time the container is restarted
5. Local storage is available at `./data` (image regex: `^.*\.(jpg|JPG|jpeg|JPEG|png|PNG)$` + click checkbox)

## Layers of Security

- ngrok: new HTTPS tunnel is created each time the container is restarted
- NGINX: only permit HTTPS requests from the dynamically generated ngrok URL with basic authentication
- Label Studio: account registration only via invitation link (no public signup)
- Podman/Docker: container is isolated from the host
- Local Storage: all data remains on the host machine
- Disabled Exports: bulk download functionality is disabled
- TLS Encryption: all traffic is encrypted from the client to the container's NGINX proxy

### File Storage

The container mounts a local `./data` directory for file storage.

## Troubleshooting

1. If the container fails to start, check the logs:
   ```bash
   podman logs ls
   ```

2. Ensure the `.env` file contains all required variables
3. Verify that port 8080 is not in use by another application
4. Check that the data directory has proper permissions

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Acknowledgments

- Built on top of [Label Studio](https://github.com/HumanSignal/label-studio) by HumanSignal
- Original Label Studio is licensed under the Apache 2.0 License © Heartex. 2020-2025
# Label Studio with NGINX and ngrok

This project provides a free secure, containerized setup of Label Studio with NGINX reverse proxy and ngrok tunneling for public access. It's designed for secure data labeling workflows with proper authentication and HTTPS support.

In other words, you can keep your data on a private computer and access it from anywhere with a public URL.

## Features

- 🔒 Secure setup with NGINX reverse proxy and basic authentication
- 🌐 Public access via ngrok tunneling with HTTPS
- 📦 Containerized deployment using Docker/Podman
- 📁 Local file serving support
- 🛡️ CSRF protection and secure origins

## Prerequisites

- Docker or Podman installed
- ngrok account (free)

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

- **View logs (to find the ngrokpublic URL):**
  ```bash
  podman logs ls
  ```

## Accessing Label Studio

1. The container exposes Label Studio on port 8080
2. Access is protected by basic authentication (username: `admin`, password: from `.env`)
3. The dynamically generated public URL is available in the container logs (ngrok)
4. The URL changes each time the container is restarted
5. Local storage is available at `./data` (image regex: `^.*\.(jpg|JPG|jpeg|JPEG|png|PNG)$` + click checkbox)

## Layers of security
- ngrok: new HTTPS tunnel is created each time the container is restarted
- NGINX: only permit HTTPS requests from the dynamically generated ngrok URL with basic authentication
- Label Studio: account registration only via invitation link (no public signup)
- Podman/Docker: container is isolated from the host


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

## License
This project is licensed under the MIT License - see the LICENSE file for details.
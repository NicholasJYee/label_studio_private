Re-build image:

`podman build -t labelstudio-nginx-ngrok .`

Re-build container:

`podman run -d \
  --replace \
  --name ls \
  --env-file .env \
  -p 8080:8080 \
  -v "$PWD/data:/home/secureuser/data:rw" \
  labelstudio-nginx-ngrok
`

---

Restart container:

`podman start ls`

Find public URL (it keeps changing):

`podman logs ls`

Close container:

`podman stop ls`
Re-build image:

`podman build -t labelstudio-nginx-ngrok .`

Re-build container:

`podman run -d \
  --replace
  --d
  --name labelstudio-nginx-ngrok \
  -p 8080:8080 \
  -v "$PWD/.env:/home/secureuser/.env:ro" \
  labelstudio-nginx-ngrok
`

---

Restart container:

`podman start labelstudio-nginx-ngrok`

Find public URL (it keeps changing):

`podman logs -f labelstudio-nginx-ngrok`

Close container:

`podman stop labelstudio-nginx-ngrok`
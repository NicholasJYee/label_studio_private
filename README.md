Re-build image:

`podman build -t labelstudio .`

Re-build container:

`podman run -d \
  --replace \
  --name ls \
  --env-file .env \
  -p 8080:8080 \
  -v "$PWD/data:/home/secureuser/data:rw" \
  labelstudio
`

---

Restart container:

`podman start ls`

Find public URL (it keeps changing):

`podman logs ls`

Close container:

`podman stop ls`

Create new superuser:

`podman exec -it ls label-studio createsuperuser`
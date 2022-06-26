### Underground Nexus deployment
> Current version 0.7.1

Build main Dockerfile with `dagger`. To note, this Dockerfile is using `nestybox/alpine-supervisord-docker:latest` which is an alternate version of Docker-in-Docker (dind).

`dagger do build`

Load your newly built docker image

`dagger do load`

To run with just Docker in `--privileged` mode.

```bash
docker run -itd --name=Underground-Nexus \
    -h Underground-Nexus \
    --privileged \
    --init \
    -p 1000:1000 -p 9050:9443 \
    -v underground-nexus-docker-socket:/var/run \
    -v underground-nexus-data:/var/lib/docker/volumes \
    -v nexus-bucket:/nexus-bucket nexus0:v0.7.1
```

Execute the `deploy-olympiad.sh` script

`docker exec Underground-Nexus sh deploy-olympiad.sh`

I am using Sigstore Cosign to generate key-pair and sign my docker images with the generated Cosign private key.

Cosign public key

```bash
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKEBgXjBv494co5Ko5KED3BDrC1+Z
v8gRvhT0mhF8anj95LSFVoSSfptc/oOQGVk4m+B24aCmYURIDCyaI8i6Kw==
-----END PUBLIC KEY-----
```

To verify the signed image with the about Cosign public key. You can also download `crane` to display the signed digest. It is also verifiable on my Dockerhub page.

```bash
docker pull pyrrhus/nexus0:v0.7.1-2564656654

cosign triangulate pyrrhus/nexus0:v0.7.1-2564656654
index.docker.io/pyrrhus/nexus0:sha256-42180f8cf5acd4ad0fdfdc6b0e8c371b65d40a6e05c77c546743e940b899bc78.sig

crane manifest $(cosign triangulate pyrrhus/nexus0:v0.7.1-2564656654) | jq .

{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 233,
    "digest": "sha256:16a370d651f6267e54d62173d3fb18f53db71d8637dca358434c9a5a628168fc"
  },
  "layers": [
    {
      "mediaType": "application/vnd.dev.cosign.simplesigning.v1+json",
      "size": 295,
      "digest": "sha256:85b872ee7ec8d0f50af531945d6b80d68123b23b90f5c1db9983bef3f58163a2",
      "annotations": {
        "dev.cosignproject.cosign/signature": "MEYCIQCHZr+SWZz7IX4zqrCJa2re6xOiJYiVy+1VqZ9wpbzWiwIhAPFQdUmauXXA7nQuwnecJ89P5977M+QWTU5mbjYhb+3Z"
      }
    }
  ]
}

cosign verify --check-claims=false --key cosign.pub pyrrhus/nexus0:v0.7.1-2564656654

Verification for index.docker.io/pyrrhus/nexus0:v0.7.1-2564656654 --
The following checks were performed on each of these signatures:
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"index.docker.io/pyrrhus/nexus0"},"image":{"docker-manifest-digest":"sha256:42180f8cf5acd4ad0fdfdc6b0e8c371b65d40a6e05c77c546743e940b899bc78"},"type":"cosign container image signature"},"optional":{"commit":"9f61e50b6bea20e188eaa720e159d612a24b22c3"}}]
```

***Experimental***

Since I built this particular Docker image with `sysbox`, you can use `sysbox` as the runtime. To run with `sysbox`, make sure that `sysbox` is installed.

```bash
docker run --runtime=sysbox-runc \
    -itd \
    --name=Underground-Nexus \
    --hostname=Underground-Nexus \
    --mount source=underground-nexus-data,target=/var/lib/docker/volumes \
    --mount source=underground-nexus-docker-socket,target=/var/run \
    --mount source=nexus-bucket,target=/nexus-bucket \
    -p 1000:1000 -p 9050:9443 nexus0:v0.7.0
```

ROADMAP

1. Re-establish usage of Cosign generated private key onto a KMS service or Kubernetes
2. Build arm64 version for Raspberry PI
3. Dagger plan needs to include docker#Push to publish the newly built docker image to a container registry
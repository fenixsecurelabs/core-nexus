### Underground Nexus deployment
> Current version 0.7.1

Build main Dockerfile with `dagger`

`dagger do build`

Load built docker image with your installed docker

`dagger do load`

To run with just docker

```bash
docker run -itd --name=Underground-Nexus \
    -h Underground-Nexus \
    --privileged \
    --init \
    -p 1000:1000 -p 9050:9443 \
    -v underground-nexus-docker-socket:/var/run -v underground-nexus-data:/var/lib/docker/volumes -v nexus-bucket:/nexus-bucket nexus0:v0.7.0
```

To run with `sysbox`, make sure that `sysbox` is installed

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

Run the `deploy-olympiad.sh` script

`docker exec Underground-Nexus sh deploy-olympiad.sh`
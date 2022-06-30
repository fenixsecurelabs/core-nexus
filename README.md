### Underground Nexus deployment
> Current version 1.0.0

To pull the latest Underground Nexus image.

`docker pull pyrrhus/nexus0:latest`

**Resources**
1. PI-Hole DNS that sits behind NGINX Reverse Proxy - Obtain the IP address of your running docker container. `docker inspect Underground-Nexus`
  - There is no password set, so you will have to change it
    - Access the Docker container once you're within the Underground-Nexus running container.
      - `docker exec -it Inner-DNS-Control /bin/sh`
      - `sudo pihole -a -p`
2. Linux webtop desktop - Alpine KDE - `http://10.20.0.30:3000` (optionally, only accessible from the Ubuntu MATE desktop)
3. Linux webtop desktop - Ubuntu MATE - `http://172.17.0.4:1000`
4. Kali Linux Bleeding Edge Repository - not publicly accessible
5. Portainer CE - `https://172.17.0.4:9443/`
6. Minio S3 Storage - `http://172.17.0.4:9001/login`
  - To access Minio S3, this server is deployed with the default credentials: `minioadmin:minioadmin`
7. Visual Studio Code - `http://10.20.0.73:3000` is not publicly accessible, this can be accessed from Ubuntu MATE desktop.
8. Kubernetes (k3d) cluster deployed on standby as a load-balancer

**Features that are missing:**

UPDATE: 
  - Added Visual Studio Code, there were issues with hardware acceleration when it is deployed via ARM64 distro.
  - Minio has been added back again, and the port has been fixed.
  - ~~There is a bash script now, and I took away the workbench.sh script for now.~~ Scratch that, it's added back in the Dockerfile.
  - Docker Swarm is initialized last at the end of the script to avoid conflicts with existing services.

1. ~~Minio is not being used right now because Minio has a conflicting port 9000 with Portainer. Future plan to redirect port usage or take away port 9000 on Portainer.~~
2. There isn't the best bash script to check for logic on when there are certain resources that are already available. A cli tool is coming soon.
3. Docker Swarm is not initialized first only because of the conflict that Portainer has while being deployed along with Docker Swarm turned on.

**ROADMAP**

1. Before, I generated `cosign` key and `cosign` public key, now it has been changed to use GitHub support. There is no local private key to verify. At this time, signing and verification is done with GitHub OIDC login.
2. Build an arm64 version of Underground Nexus.
3. Dagger plan is using `docker#Push`, looking for a better way to implement this steps through Github Actions.
4. So far, docker images are being built and pushed to DockerHub registry. Future plan is create an in-house self-hosted registry.

**Information**

The default Dockerfile has the original `docker:dind` base image to build the Underground Nexus from. The GitHub Action will build the main Dockerfile with `dagger`. Please note, there are two Dockerfiles. One is using `nestybox/alpine-supervisord-docker:latest` which is an alternate version of Docker-in-Docker (dind).

Before, I had multiple steps to build and load the newly built Docker images. I was able to change the Dagger actions to build with the Dockerfile contents.

To start, you will need to set some variables.

```bash
export REGISTRY_DOCKERIO_USER=<USERNAME>
export REGISTRY_DOCKERIO_PASS=<PASSWORD>
```

To build with the latest version or a specific version. Once built, it will push to Dockerhub.

```bash
dagger do versions <VERSION>
```

To run with just Docker in `--privileged` mode.

```bash
docker run -itd --name=Underground-Nexus \
    -h Underground-Nexus \
    --privileged \
    --init \
    -p 1000:1000 -p 9050:9443 \
    -v underground-nexus-docker-socket:/var/run \
    -v underground-nexus-data:/var/lib/docker/volumes \
    -v nexus-bucket:/nexus-bucket pyrrhus/nexus0:latest
```

Execute the `deploy-olympiad.sh` script

`docker exec Underground-Nexus sh deploy-olympiad.sh`

If you need to troubleshoot or access the running container. Do this below.

`docker exec -it Underground-Nexus /bin/sh`

**Details**

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
docker pull pyrrhus/nexus0:latest

cosign triangulate pyrrhus/nexus0:latest
index.docker.io/pyrrhus/nexus0:sha256-2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927.sig

crane manifest $(cosign triangulate pyrrhus/nexus0:latest) | jq .

{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 233,
    "digest": "sha256:342957a565a3133b864b091291dca2778d9f2735c2fc31404937cf1076b029a7"
  },
  "layers": [
    {
      "mediaType": "application/vnd.dev.cosign.simplesigning.v1+json",
      "size": 319,
      "digest": "sha256:863fd2246616b5842ec6dfaefa40ba91acb5627d4d1a0e16e136f75f5e25eaa6",
      "annotations": {
        "dev.cosignproject.cosign/signature": "MEQCIDnIHpAtsWKlc4Tlu0aCK8d/8jyF0nUZjPfaGbSwwZJqAiAteCPKYuG4na8KktWj48CxEMjKdSleIQS0NzKDAsO5CA=="
      }
    }
  ]
}

cosign verify --key cosign.pub pyrrhus/nexus0:latest

Verification for index.docker.io/pyrrhus/nexus0:latest --
The following checks were performed on each of these signatures:
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"index.docker.io/pyrrhus/nexus0"},"image":{"docker-manifest-digest":"sha256:2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927"},"type":"cosign container image signature"},"optional":{"commit":"fbc8d91acd7fac6a70a46d71d88b15b8550fe2d8","repo":"pyrrhus/nexus0"}}]
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
    -p 1000:1000 -p 9050:9443 nexus0:v0.7.1
```

Using `syft` to package the newly built docker image.

```bash
syft packages pyrrhus/nexus0:latest -o spdx > nexus0-dind-latest.spdx

# Cosign attach sbom to first docker built image
cosign attach sbom --sbom nexus0-dind-latest.spdx pyrrhus/nexus0:latest
WARNING: Attaching SBOMs this way does not sign them. If you want to sign them, use 'cosign attest -predicate nexus0-dind-latest.spdx -key <key path>' or 'cosign sign -key <key path> <sbom image>'.
Uploading SBOM file for [index.docker.io/pyrrhus/nexus0:latest] to [index.docker.io/pyrrhus/nexus0:sha256-2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927.sbom] with mediaType [text/spdx].

# Cosign sign sbom
cosign sign --key cosign.key index.docker.io/pyrrhus/nexus0:sha256-2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927.sbom
Enter password for private key: 
Pushing signature to: index.docker.io/pyrrhus/nexus0

# Cosign verify
cosign verify --key cosign.pub index.docker.io/pyrrhus/nexus0:sha256-2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927.sbom

Verification for index.docker.io/pyrrhus/nexus0:sha256-2370cc6b72bbeb73eab1f2edf3e22a5e30c785877b82a5d2ea79302742243927.sbom --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"index.docker.io/pyrrhus/nexus0"},"image":{"docker-manifest-digest":"sha256:fb55e6584d0c079eac55b4f58bb50809bc4438e31611715f0fac6579f764e0cf"},"type":"cosign container image signature"},"optional":null}]
```

You can also use `grype` to scan the new docker image.

```bash
grype pyrrhus/nexus0:latest --add-cpes-if-none     
 ✔ Vulnerability DB        [updated]
 ✔ Loaded image            
 ✔ Parsed image            
 ✔ Cataloged packages      [377 packages]
 ✔ Scanned image           [14 vulnerabilities]

NAME                              INSTALLED  FIXED-IN  TYPE       VULNERABILITY        SEVERITY 
docker                            5.0.3                python     CVE-2019-13139       High      
docker                            5.0.3                python     CVE-2020-27534       Medium    
docker                            5.0.3                python     CVE-2018-10892       Medium    
docker                            5.0.3                python     CVE-2019-13509       High      
docker                            5.0.3                python     CVE-2019-5736        High      
docker                            5.0.3                python     CVE-2021-21284       Medium    
docker                            5.0.3                python     CVE-2021-21285       Medium    
docker                            5.0.3                python     CVE-2019-16884       High      
github.com/containerd/containerd  v1.6.1     1.6.6     go-module  GHSA-5ffw-gxpp-mxpf  Medium    
github.com/opencontainers/runc    v1.1.0     1.1.2     go-module  GHSA-f3fp-gc8g-vw66  Medium    
google.golang.org/protobuf        v1.27.1              go-module  CVE-2015-5237        High      
google.golang.org/protobuf        v1.27.1              go-module  CVE-2021-22570       High 
```
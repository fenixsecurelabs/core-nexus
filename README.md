### Underground Nexus deployment
> Current version 0.8.0

**Features that are missing:**

1. Minio is not being used right now because Minio has a conflicting port 9000 with Portainer. Future plan to redirect port usage or take away port 9000 on Portainer
2. There isn't the best bash script to check for logic on when there are certain resources that are already available. A cli tool is coming soon.

**Information**

The default Dockerfile has the original `docker:dind` base image to build the Underground Nexus from. The GitHub Action will build the main Dockerfile with `dagger`. Please note, there are two Dockerfiles. One is using `nestybox/alpine-supervisord-docker:latest` which is an alternate version of Docker-in-Docker (dind).

`dagger do build`

Load your newly built docker image on your workstation.

`dagger do load`

After the docker image has been built, push it to your favorite registry.

`dagger do push`

To run with just Docker in `--privileged` mode.

```bash
docker run -itd --name=Underground-Nexus \
    -h Underground-Nexus \
    --privileged \
    --init \
    -p 1000:1000 -p 9050:9443 \
    -v underground-nexus-docker-socket:/var/run \
    -v underground-nexus-data:/var/lib/docker/volumes \
    -v nexus-bucket:/nexus-bucket nexus0:v0.8.0
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
docker pull pyrrhus/nexus0:v0.7.1-2564787928

cosign triangulate pyrrhus/nexus0:v0.7.1-2564787928
index.docker.io/pyrrhus/nexus0:sha256-364f0ac6703714341daeb162325414e88117c1665e749fecad3cb6324f122d65.sig

crane manifest $(cosign triangulate pyrrhus/nexus0:v0.7.1-2564787928) | jq .

{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 233,
    "digest": "sha256:2c7c04129ad044a5b37f2231fd3e427331efdb27fad92b2b0e06ecea10a88d5d"
  },
  "layers": [
    {
      "mediaType": "application/vnd.dev.cosign.simplesigning.v1+json",
      "size": 366,
      "digest": "sha256:bbaf460c4327955cd11e1477f9ae55f05347e890da54f10bba18f290ad4e66ec",
      "annotations": {
        "dev.cosignproject.cosign/signature": "MEQCIGrURDaQ3YjsNu/WIoD8amgdlPNwVccuzUlRtY+ZF9yZAiBvJIOjCxvSValG43YrecTvHEA3RUVoPy8iv/+e8HM9fw=="
      }
    }
  ]
}

cosign verify --check-claims=false --key cosign.pub pyrrhus/nexus0:v0.7.1-2564787928

Verification for index.docker.io/pyrrhus/nexus0:v0.7.1-2564787928 --
The following checks were performed on each of these signatures:
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"index.docker.io/pyrrhus/nexus0"},"image":{"docker-manifest-digest":"sha256:364f0ac6703714341daeb162325414e88117c1665e749fecad3cb6324f122d65"},"type":"cosign container image signature"},"optional":{"commit":"32967e0c1c3f21cd22bcbae29e8b18391136917c","repo":"acald-creator/underground-nexus-deployment","workflow":"nexus"}}]
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
syft packages pyrrhus/nexus0:v0.7.1-2564787928 -o spdx > nexus0-latest.spdx

# Cosign attach sbom to first docker built image
cosign attach sbom --sbom nexus0-latest.spdx pyrrhus/nexus0:v0.7.1
WARNING: Attaching SBOMs this way does not sign them. If you want to sign them, use 'cosign attest -predicate nexus0-latest.spdx -key <key path>' or 'cosign sign -key <key path> <sbom image>'.
Uploading SBOM file for [index.docker.io/pyrrhus/nexus0:v0.7.1] to [index.docker.io/pyrrhus/nexus0:sha256-72c8a646cda55e78f7eeccea923ae32ae03aeeac46b88fc82b2c52131f975c47.sbom] with mediaType [text/spdx].

# Cosign sign sbom
cosign sign --key cosign.key index.docker.io/pyrrhus/nexus0:sha256-72c8a646cda55e78f7eeccea923ae32ae03aeeac46b88fc82b2c52131f975c47.sbom
Enter password for private key: 
Pushing signature to: index.docker.io/pyrrhus/nexus0

# Cosign verify
cosign verify --key cosign.pub index.docker.io/pyrrhus/nexus0:sha256-72c8a646cda55e78f7eeccea923ae32ae03aeeac46b88fc82b2c52131f975c47.sbom

Verification for index.docker.io/pyrrhus/nexus0:sha256-72c8a646cda55e78f7eeccea923ae32ae03aeeac46b88fc82b2c52131f975c47.sbom --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"index.docker.io/pyrrhus/nexus0"},"image":{"docker-manifest-digest":"sha256:5374b94778798a21f482c1b98486ac076fd1d1193fb25de6c0b89c9c4a1bf306"},"type":"cosign container image signature"},"optional":null}]
```

You can also use `grype` to scan the new docker image.

```bash
grype pyrrhus/nexus0:v0.7.1 --add-cpes-if-none                                                              
 ✔ Vulnerability DB        [no update available]
 ✔ Loaded image            
 ✔ Parsed image            
 ✔ Cataloged packages      [355 packages]
 ✔ Scanned image           [61 vulnerabilities]
NAME                                 INSTALLED  FIXED-IN    TYPE       VULNERABILITY        SEVERITY 
docker                               5.0.3                  python     CVE-2021-21285       Medium    
docker                               5.0.3                  python     CVE-2018-10892       Medium    
docker                               5.0.3                  python     CVE-2019-16884       High      
docker                               5.0.3                  python     CVE-2020-27534       Medium    
docker                               5.0.3                  python     CVE-2019-5736        High      
docker                               5.0.3                  python     CVE-2019-13509       High      
docker                               5.0.3                  python     CVE-2019-13139       High      
docker                               5.0.3                  python     CVE-2021-21284       Medium    
github.com/containerd/containerd     (devel)    1.3.9       go-module  GHSA-36xw-fx78-c5r4  Medium    
github.com/containerd/containerd     (devel)    1.5.13      go-module  GHSA-5ffw-gxpp-mxpf  Medium    
github.com/containerd/containerd     (devel)    1.2.14      go-module  GHSA-742w-89gc-8m9c  Medium    
github.com/containerd/containerd     (devel)    1.4.8       go-module  GHSA-c72p-9xmj-rx3w  Medium    
github.com/containerd/containerd     (devel)    1.4.11      go-module  GHSA-c2h3-6mxw-7mvq  Medium    
github.com/containerd/containerd     (devel)    1.4.13      go-module  GHSA-crp2-qrr5-8pq7  High      
github.com/containerd/containerd     (devel)    1.4.12      go-module  GHSA-5j5w-g665-5m35  Low       
github.com/containerd/imgcrypt       v1.1.1                 go-module  CVE-2022-24778       High      
github.com/containerd/imgcrypt       v1.1.1     1.1.4       go-module  GHSA-8v99-48m9-c8pm  High      
github.com/opencontainers/runc       (devel)    1.0.0-rc9   go-module  GHSA-fgv8-vj5c-2ppq  High      
github.com/opencontainers/runc       (devel)    1.0.0-rc91  go-module  GHSA-g54h-m393-cpwq  Low       
github.com/opencontainers/runc       v1.0.2     1.0.3       go-module  GHSA-v95c-p5hm-xq8f  Medium    
github.com/opencontainers/runc       (devel)    1.0.0-rc95  go-module  GHSA-c3xm-pvg7-gh7r  High      
github.com/opencontainers/runc       (devel)    1.0.3       go-module  GHSA-v95c-p5hm-xq8f  Medium    
github.com/opencontainers/runc       (devel)    1.0.0-rc3   go-module  GHSA-gp4j-w3vj-7299  Medium    
github.com/opencontainers/runc       v1.0.2     1.1.2       go-module  GHSA-f3fp-gc8g-vw66  Medium    
github.com/opencontainers/runc       (devel)    1.1.2       go-module  GHSA-f3fp-gc8g-vw66  Medium    
github.com/opencontainers/runc       (devel)    0.1.0       go-module  GHSA-q3j5-32m5-58c2  High      
github.com/prometheus/client_golang  v1.7.1                 go-module  CVE-2022-21698       High      
google.golang.org/protobuf           v1.27.1                go-module  CVE-2021-22570       High      
google.golang.org/protobuf           v1.27.1                go-module  CVE-2015-5237        High      
paramiko                             2.7.2                  python     CVE-2022-24302       Medium    
paramiko                             2.7.2      2.10.1      python     GHSA-f8q4-jwww-x3wv  Medium
```

**ROADMAP**

1. Re-establish usage of Cosign generated private key onto a KMS service or Kubernetes
2. Build arm64 version for Raspberry PI
3. Dagger plan needs to include docker#Push to publish the newly built docker image to a container registry
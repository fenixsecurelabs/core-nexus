#!/bin/sh

set -e

export PIHOLE_IMAGE=pihole/pihole:latest
export PORTAINER_IMAGE=portainer/portainer-ce:2.14.0
export MINIO_IMAGE=quay.io/minio/minio
export VAULT_IMAGE=vault
export KALI_LINUX_IMAGE=registry.gitlab.com/cyberphxv/nexus-athena0:latest.amd64
export WORKBENCH_WEBTOP_IMAGE=pyrrhus/webtop-workbench:amd64-latest
export SOC_WEBTOP_IMAGE=pyrrhus/soc-admin-webtop:amd64-latest
export VISUAL_STUDIO_IMAGE=lscr.io/linuxserver/openvscode-server

echo "Creating volumes for persistence..."
docker volume create pihole_dns_data && \
    docker volume create portainer_data

echo "Pull necessary images"
docker pull $PIHOLE_IMAGE
docker pull $PORTAINER_IMAGE
docker pull $MINIO_IMAGE
docker pull $VAULT_IMAGE
docker pull $KALI_LINUX_IMAGE
docker pull $WORKBENCH_WEBTOP_IMAGE
docker pull $SOC_WEBTOP_IMAGE

echo "Create Docker network - Inner-Athena"

export DOCKER_NETWORK=Inner-Athena
export SUBNET_NETWORK=10.20.0.20/24

if docker network ls | grep $DOCKER_NETWORK;
then
    echo "Docker's network Inner-Athena is already created."
else
    docker network create -d bridge --subnet=$SUBNET_NETWORK $DOCKER_NETWORK 2> /dev/null
fi

sleep 5

echo "Deploy Pi-Hole DNS Server"

export PIHOLE=Inner-DNS-Control
export PIHOLE_IPADDRESS=10.20.0.20

if docker ps --format "{{.Names}}" | grep -w $PIHOLE;
then
    echo "Inner-DNS-Control is already created."
else
    docker compose -f docker-compose.yml up -d
fi

echo "Build Olympiad0 Portainer node"

sleep 30

export PORTAINER_NAME=Olympiad0

if docker volume ls | grep -w portainer_data;
then
    echo "Portainer data volume exists"
else
    docker compose -f portainer-deploy.yml up -d
fi

echo "Build Cyber Life Torpedo"

sleep 5

export MINIO_NAME=torpedo

if docker ps --format "{{.Names}}" | grep -w $MINIO_NAME;
then
    echo "torpedo is already created."
else
    docker run \
        -itd \
        --privileged \
        -p 9000:9000 \
        -p 9001:9001 \
        --name=$MINIO_NAME \
        --hostname $MINIO_NAME \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        --restart=always \
        -v /nexus-bucket:/nexus-bucket \
        -v /nexus-bucket/s3-torpedo:/data $MINIO_IMAGE server /data --console-address ":9001" 2> /dev/null
fi

echo "Build Development Vault server"

sleep 5

export SECRET_VAULT_NAME=Nexus-Secret-Vault

if docker ps --format "{{.Names}}" | grep -w $SECRET_VAULT_NAME;
then
    echo "Nexus Secret Vault is already created."
else
    docker run \
        -itd -p 8200:1234 \
        --name=$SECRET_VAULT_NAME \
        --hostname $SECRET_VAULT_NAME \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        --restart=always \
        --cap-add=IPC_LOCK \
        -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:1234' $VAULT_IMAGE 2> /dev/null
fi

echo "Build Athena0 Stack"

sleep 5

export KALI_LINUX_NAME=Athena0

if docker ps --format "{{.Names}}" | grep -w $KALI_LINUX_NAME;
then
    echo "Athena0 is already created."
else
    docker run \
        -itd \
        -p 22:22 \
        --name=$KALI_LINUX_NAME \
        --hostname $KALI_LINUX_NAME \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        --restart=always \
        -v athena0:/home/ \
        -v /nexus-bucket:/nexus-bucket \
        -v /etc/docker:/etc/docker \
        -v /usr/local/bin/docker:/usr/local/bin/docker \
        -v /var/run/docker.sock:/var/run/docker.sock $KALI_LINUX_IMAGE 2> /dev/null
fi

echo "Build Workbench"

sleep 5

export WORKBENCH_NAME=workbench

if docker ps --format "{{.Names}}" | grep -w $WORKBENCH_NAME;
then
    echo "workbench is already created."
else
    docker run \
        -itd \
        --name=$WORKBENCH_NAME \
        --hostname $WORKBENCH_NAME \
        --privileged \
        --init \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=America/Chicago \
        -p 1000:3000 \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        --restart=always \
        -v workbench0:/config \
        -v /nexus-bucket:/config/Desktop/nexus-bucket \
        -v /var/run/docker.sock:/var/run/docker.sock $WORKBENCH_WEBTOP_IMAGE 2> /dev/null
fi

echo "Build Security Operation Center"

sleep 5

export SOC_NAME=Security-Operation-Center
export SOC_IPADDRESS=10.20.0.30

if docker ps --format "{{.Names}}" | grep -w $SOC_NAME;
then
    echo "Security Operation Center is already created."
else
    docker run \
        -itd \
        --name=$SOC_NAME \
        --hostname $SOC_NAME \
        --privileged \
        --init \
        -e PUID=2000 \
        -e PGID=2000 \
        -e TZ=America/Chicago \
        -p 2000:3000 \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        --ip=$SOC_IPADDRESS \
        --restart=always \
        -v security-operation-center:/config \
        -v /nexus-bucket:/config/Desktop/nexus-bucket $SOC_WEBTOP_IMAGE 2> /dev/null
fi

echo "Install Visual Studio"

export VISUALSTUDIO_NAME=code-server

if docker ps --format "{{.Names}}" | grep -w $VISUALSTUDIO_NAME;
then
    echo "Security Operation Center is already created."
else
    docker run \
        -d \
        --name=$VISUALSTUDIO_NAME \
        -e PUID=1050 \
        -e PGID=1050 \
        -p 18443:3000 \
        --dns=$PIHOLE_IPADDRESS \
        --net=$DOCKER_NETWORK \
        -v /nexus-bucket:/nexus-bucket \
        -v /nexus-bucket/visual-studio-code:/config \
        -v /etc/docker:/etc/docker \
        -v /usr/local/bin/docker:/usr/local/bin/docker \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --restart unless-stopped $VISUAL_STUDIO_IMAGE 2> /dev/null
fi

echo "Intiating Docker Swarm"

sleep 3; docker swarm init

wget https://raw.githubusercontent.com/Underground-Ops/underground-nexus/main/Production%20Artifacts/firefox--hostnameomepage.sh && \
    sh firefox--hostnameomepage.sh

sleep 5

sh ./nexus-bucket/workbench.sh

echo "Deploy KuberNexus"

# Install Kubernetes on AMD64
echo "Install Kubectl"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

sleep 5

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create KuberNexus \
    -p 8080:80@loadbalancer \
    -p 8443:8443@loadbalancer \
    -p 2222:22@loadbalancer \
    -p 179:179@loadbalancer \
    -p 2375:2376@loadbalancer \
    -p 2378:2379@loadbalancer \
    -p 2381:2380@loadbalancer \
    -p 8472:8472@loadbalancer \
    -p 8843:443@loadbalancer \
    -p 4789:4789@loadbalancer \
    -p 9099:9099@loadbalancer \
    -p 9100:9100@loadbalancer \
    -p 7443:9443@loadbalancer \
    -p 9796:9796@loadbalancer \
    -p 6783:6783@loadbalancer \
    -p 10250:10250@loadbalancer \
    -p 10254:10254@loadbalancer \
    -p 31896:31896@loadbalancer

echo "Completed."
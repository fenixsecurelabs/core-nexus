#!/bin/sh

set -e

# Optional, this was conflicting with creating and deploying Portainer through docker-compose
# docker swarm init

docker network create -d bridge --subnet=10.20.0.0/24 Inner-Athena

sleep 5

# docker run -itd -p 53:53/tcp -p 53:53/udp -p 67:67 -p 80:80 -p 443:443 -h Inner-DNS-Control --name=Inner-DNS-Control --net=Inner-Athena --ip=10.20.0.20 --restart=always -v pihole_DNS_data:/etc/dnsmasq.d/ -v /var/lib/docker/volumes/pihole_DNS_data/_data/pihole/:/etc/pihole/ pihole/pihole:latest

docker volume create pihole_dns_data

docker compose -f docker-compose.yml up -d

sleep 30

ping 10.20.0.20 -c 10

sleep 10

docker volume create portainer_data && \
    docker compose -f portainer-deploy.yml up -d

# docker run -d -p 8000:8000 -p 9443:9443 --name=Olympiad0 --dns=10.20.0.20 --net=Inner-Athena --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data cr.portainer.io/portainer/portainer-ce

sleep 5

# docker run -itd --privileged -p 9000:9000 -p 9010:9001 --name=torpedo -h torpedo --dns=10.20.0.20 --net=Inner-Athena --restart=always -v /nexus-bucket:/nexus-bucket -v /nexus-bucket/s3-torpedo:/data quay.io/minio/minio server /data --console-address ":9001" && \

docker run -itd --name=workbench -h workbench --privileged --init -e PUID=1000 -e PGID=1000 -e TZ=America/Colorado -p 1000:3000 --dns=10.20.0.20 --net=Inner-Athena --restart=always -v workbench0:/config -v /nexus-bucket:/config/Desktop/nexus-bucket -v /var/run/docker.sock:/var/run/docker.sock linuxserver/webtop:ubuntu-mate  && \
    docker run -itd --name=Security-Operation-Center -h Security-Operation-Center --privileged --init -e PUID=2000 -e PGID=2000 -e TZ=America/Colorado -p 2000:3000 --dns=10.20.0.20 --net=Inner-Athena --ip=10.20.0.30 --restart=always -v security-operation-center:/config -v /nexus-bucket:/config/Desktop/nexus-bucket linuxserver/webtop:alpine-kde && \
    docker run -d --name=code-server -e PUID=1050 -e PGID=1050 -p 18443:3000 --dns=10.20.0.20 --net=Inner-Athena -v /nexus-bucket:/nexus-bucket -v /nexus-bucket/visual-studio-code:/config -v /etc/docker:/etc/docker -v /usr/local/bin/docker:/usr/local/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped lscr.io/linuxserver/openvscode-server && \
    docker run -itd -p 8200:1234 --name=Nexus-Secret-Vault -h Nexus-Secret-Vault --dns=10.20.0.20 --net=Inner-Athena --restart=always --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:1234' vault && \
    docker run -itd -p 2222:22 --name=Athena0 -h Athena0 --dns=10.20.0.20 --net=Inner-Athena --restart=always -v athena0:/home/ -v /nexus-bucket:/nexus-bucket -v /etc/docker:/etc/docker -v /usr/local/bin/docker:/usr/local/bin/docker -v /var/run/docker.sock:/var/run/docker.sock registry.gitlab.com/cyberphxv/nexus-athena0:latest.amd64

wget https://raw.githubusercontent.com/Underground-Ops/underground-nexus/main/Production%20Artifacts/firefox-homepage.sh && \
    sh firefox-homepage.sh

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash && \
    k3d cluster create KuberNexus \
        -p 8080:80@loadbalancer \
        -p 8443:8443@loadbalancer \
        -p 3333:22@loadbalancer \
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

sh ./nexus-bucket/workbench.sh
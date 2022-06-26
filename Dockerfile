FROM nestybox/alpine-supervisord-docker:latest

EXPOSE 22 53 80 443 1000 2375 2376 2377 9010 9443 18443

VOLUME ["/var/run", "/var/lib/docker/volumes", "/nexus-bucket"]

RUN apk update && \
    apk upgrade

RUN apk add bash \
    nano \
    curl \
    wget \
    docker-compose

WORKDIR /nexus-bucket

COPY workbench.sh /nexus-bucket

WORKDIR /

COPY deploy-olympiad.sh /

COPY docker-compose.yml /

COPY portainer-deploy.yml /
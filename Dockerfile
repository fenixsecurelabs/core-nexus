FROM docker:dind

ARG VERSION
ENV VERSION $VERSION
ARG BUILD_TIMESTAMP
ENV BUILD_TIMESTAMP $BUILD_TIMESTAMP

LABEL description="Custom Underground Nexus copy-paste script data center deployment."

VOLUME ["/var/run", "/var/lib/docker/volumes", "/nexus-bucket"]

RUN apk update && \
    apk upgrade

RUN apk add bash \
    nano \
    curl \
    wget \
    docker-compose

WORKDIR /

COPY deploy-olympiad.sh /

COPY docker-compose.yml /

COPY portainer-deploy.yml /

EXPOSE 22 53 80 443 1000 2375 2376 2377 9010 9443 18443
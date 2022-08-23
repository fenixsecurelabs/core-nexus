package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#SysboxBuild: docker.#Dockerfile & {
	dockerfile: contents: """
		FROM nestybox/alpine-supervisord-docker:latest
		ARG VERSION
		ENV VERSION $VERSION
		LABEL description="Custom Underground Nexus copy-paste script data center deployment."
		VOLUME ["/var/run", "/var/lib/docker/volumes", "/nexus-bucket"]
		RUN apk update && apk upgrade
		RUN apk add bash nano curl wget docker-compose
		WORKDIR /nexus-bucket
		COPY workbench.sh /nexus-bucket/
		WORKDIR /
		COPY deploy-olympiad.sh /
		COPY docker-compose.yml /
		COPY portainer-deploy.yml /
		EXPOSE 22 53 80 443 1000 2375 2376 2377 9010 9443 18443
		"""
}

dagger.#Plan & {
	client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	client: filesystem: ".": read: contents: dagger.#FS
	client: env: {
		REGISTRY_DOCKERIO_USER: string | *"_token_"
		OFFICIAL_REGISTRY_USER: string | *"_token_"
		REGISTRY_DOCKERIO_PASS: dagger.#Secret
	}

	actions: versions: {
		latest:   _
		"v1.2.6": _
		[tag=string]: {
			build: #SysboxBuild & {
				source: client.filesystem.".".read.contents
				auth: "index.docker.io": {
					username: client.env.REGISTRY_DOCKERIO_USER
					secret:   client.env.REGISTRY_DOCKERIO_PASS
				}
			}
			push: _op: docker.#Push & {
				image: build.output
				dest:  "\(client.env.REGISTRY_DOCKERIO_USER)/core-nexus:\(tag)-sysbox"
			}
		}
	}
}

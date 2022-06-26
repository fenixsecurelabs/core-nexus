package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {
	client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

	client: filesystem: ".": read: contents: dagger.#FS

	actions: {
		build: docker.#Dockerfile & {
			source: client.filesystem.".".read.contents
		}

		load: cli.#Load & {
			image: build.output
			host:  client.network."unix:///var/run/docker.sock".connect
			tag:   "nexus0:v0.7.1"
		}
	}
}

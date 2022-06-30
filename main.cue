package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {
	client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

	client: filesystem: ".": read: contents: dagger.#FS

	client: env: {
		//                       REGISTRY_GITLAB_USER:   string | "_token_"
		//                       REGISTRY_GITLAB_PASS:   dagger.#Secret
		REGISTRY_DOCKERIO_PASS: dagger.#Secret
	}

	actions: {
		build: docker.#Dockerfile & {
			source: client.filesystem.".".read.contents
			dockerfile: path: "Dockerfile"
			auth: {
				"index.docker.io": {
					username: "pyrrhus"
					secret:   client.env.REGISTRY_DOCKERIO_PASS
				}
				//    "registry.gitlab.com": {
				//     username: client.env.REGISTRY_GITLAB_USER
				//     secret:   client.env.REGISTRY_GITLAB_PASS
				//    }
			}
		}

		load: cli.#Load & {
			image: build.output
			host:  client.network."unix:///var/run/docker.sock".connect
			tag:   "nexus0:v0.9.0"
		}

		push: {
			_op: docker.#Push & {
				image: build.output
				dest:  "pyrrhus/nexus0:v0.9.0"
			}
			digest: _op.result
			path:   _op.image.config.env.PATH
			//        auth: {
			//         username: "pyrrhus"
			//         secret:   client.env.REGISTRY_DOCKERIO_PASS
			//        }
		}
	}
}

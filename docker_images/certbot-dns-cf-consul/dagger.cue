package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
    client: filesystem: ".": read: contents: dagger.#FS
	actions: {
        build: docker.#Dockerfile & {
            source: client.filesystem.".".read.contents
        }
        push: docker.#Push & {
            image: build.output
            dest: "docker-registry.efthymios.net/certbot-dns-cf-consul:latest"
        }
    }
}


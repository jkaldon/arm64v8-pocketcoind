#!/bin/sh
set -ex
DOCKER_TAG=0.20.19-4

docker build --progress plain -t "jkaldon/arm64v8-pocketcoind:${DOCKER_TAG}" .
docker push "jkaldon/arm64v8-pocketcoind:${DOCKER_TAG}"

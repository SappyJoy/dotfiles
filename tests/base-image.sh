#!/bin/sh
# Build (or reuse) the base image for the container tests and print its tag: IMAGE
# plus what any work PC has (curl, git, certificates, apt lists) and a plain user
# "tester". Run: sh tests/base-image.sh IMAGE

set -eu
image=$1
tag="dotfiles-test:$(printf '%s' "$image" | tr ':/' '--')"
docker build -q -t "$tag" - >/dev/null <<DOCKERFILE
FROM $image
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl git \
 && useradd -m -s /bin/bash tester
DOCKERFILE
echo "$tag"

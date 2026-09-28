#!/bin/sh
# Build (or reuse) the base image for the container tests and print its tag: IMAGE
# plus what any work PC has (curl, git, ssh, python3, certificates, apt lists), a user
# "tester" with sudo (no password), like the root the work PCs give, and a user
# "guest" without it, like a borrowed machine. Run: sh tests/base-image.sh IMAGE

set -eu
image=$1
tag="dotfiles-test:$(printf '%s' "$image" | tr ':/' '--')"
docker build -q -t "$tag" - >/dev/null <<DOCKERFILE
FROM $image
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl git openssh-client python3 sudo \
 && useradd -m -s /bin/bash -G sudo tester \
 && echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester \
 && useradd -m -s /bin/bash guest
DOCKERFILE
echo "$tag"

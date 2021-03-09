#!/usr/bin/env bash

mount bpffs -t bpf /sys/fs/bpf

apt-get install -y docker.io
systemctl enable docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
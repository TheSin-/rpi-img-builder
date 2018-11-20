#!/bin/bash
docker build --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" -t docker-rpi-builder .

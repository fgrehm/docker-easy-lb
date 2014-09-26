#!/bin/bash

if ! [ -S /var/run/docker.sock ]; then
  echo 'Docker socket not mounted'
  exit 1
fi

echo 'Cleaning up load balancer'
redis-cli del "frontend:${DOMAIN}"
redis-cli rpush "frontend:${DOMAIN}" default &>/dev/null
redis-cli rpush "frontend:${DOMAIN}" 'http://0.0.0.0:8080' &>/dev/null

redis-cli del "frontend:*.${DOMAIN}"
redis-cli rpush "frontend:*.${DOMAIN}" defsubdomain &>/dev/null
redis-cli rpush "frontend:*.${DOMAIN}" 'http://0.0.0.0:8080' &>/dev/null

docker events | auto-lb-handler

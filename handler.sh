#!/bin/bash

echo "Starting load balancer handler"

while read line; do
  # Slice and dice some container information
  EVENT=$(echo $line | cut -f5 -d' ')
  CID=$(echo $line | tr -d ':'  | cut -f2 -d' ')
  RUNNING=$(docker inspect -f '{{ .State.Running }}' ${CID} 2>/dev/null)
  if [ "${RUNNING}" = 'true' ]; then
    IP=$(docker inspect  -f '{{ .NetworkSettings.IPAddress }}' $CID)
  else
    IP='not running'
  fi
  HOST_NAME=$(docker inspect -f '{{ .Config.Hostname }}' ${CID} 2>/dev/null | sed 's/\///')
  if [ -z "${HOST_NAME}" ]; then
    HOST_NAME=$CID
  fi
  echo "----> Received '${EVENT}' for '${HOST_NAME}'"

  # When the container gets started, we register it on the load balancer
  if [ "${EVENT}" = 'start' ]; then
    echo '      Cleaning up load balancer'
    redis-cli del "frontend:${HOST_NAME}.${DOMAIN}" &>/dev/null

    PORTS=$(docker inspect ${CID} | jq -r -c '.[0].Config.ExposedPorts | keys | .[]' | grep tcp | sed 's/\/tcp//')
    if [ -n "${PORTS}" ]; then
      echo '      Registering alias'
      redis-cli rpush "frontend:${HOST_NAME}.${DOMAIN}" ${CID} &>/dev/null
      for port in $PORTS; do
        # REFACTOR: Use an equivalent of an `in_array` function
        if [ "${port}" = '80' ] || [ "${port}" = '3000' ] || [ "${port}" = '4000' ] || [ "${port}" = '8080' ] || [ "${port}" = '9292' ] || [ "${port}" = '4567' ]; then
          echo "      Registering ${port} for http://${IP}:${port}"
          redis-cli rpush "frontend:${HOST_NAME}.${DOMAIN}" "http://${IP}:${port}" &>/dev/null
        fi
      done
    else
      echo '      Nothing to do here...'
    fi
  elif [ "${EVENT}" = 'die' ]; then
    echo '      Cleaning up load balancer'
    ALL_LISTS=$(redis-cli --raw keys frontend:*)
    for list in $ALL_LISTS; do
      if $(redis-cli --raw lrange ${list} 0 -1 | head -n 1 | grep -q "${CID}"); then
        echo '      Removing container from load balancer'
        redis-cli del $list &>/dev/null
      fi
    done
  else
    echo '      Nothing to do here...'
  fi
done

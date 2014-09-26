# Based on https://raw.githubusercontent.com/hipache/hipache/master/Dockerfile

# Latest Ubuntu LTS
FROM    ubuntu:14.04

# Install some stuff
RUN apt-get -y update && \
    apt-get -y install supervisor nodejs npm redis-server && \
    npm install -g hipache

# Download the docker CLI
RUN apt-get install -y curl && \
    curl https://get.docker.io/builds/Linux/x86_64/docker-latest > /usr/bin/docker && \
    chmod +x /usr/bin/docker

# Download and install jq
RUN curl http://stedolan.github.io/jq/download/linux64/jq > /usr/bin/jq && \
    chmod +x /usr/bin/jq

# Install the static web server
RUN npm install -g node-static

# Add our supervisor configs
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add our custom hipache configs
ADD hipache.json /usr/local/lib/node_modules/hipache/config/config.json

# Our docker events handler
ADD ./service.sh /usr/bin/auto-lb
ADD ./handler.sh /usr/bin/auto-lb-handler

# The dummy app that handles unknown domains
ADD ./no-app-app /no-app-app

# Expose hipache
EXPOSE  80

# Start supervisor
CMD ["supervisord", "-n"]

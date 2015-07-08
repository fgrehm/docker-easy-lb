FROM gliderlabs/alpine:3.2
MAINTAINER Fabio Rehm "fgrehm@gmail.com"

RUN apk --update add bash nginx curl jq

RUN curl -Ls https://github.com/progrium/entrykit/releases/download/v0.2.0/entrykit_0.2.0_Linux_x86_64.tgz \
    | tar -zxC /bin \
  && curl -s https://get.docker.io/builds/Linux/x86_64/docker-1.7.0 > /bin/docker \
  && chmod +x /bin/docker \
  && entrykit --symlink

RUN mkdir -p /etc/nginx/sites-enabled \
    && mkdir -p /var/www

ADD ./scripts /bin/
ADD ./config/nginx.conf /etc/nginx/nginx.conf
ADD ./config/proxy-template.conf /etc/nginx/proxy-template.conf
ADD ./no-app-app /var/www/no-app-app/

ENTRYPOINT /bin/entrypoint
EXPOSE 80

FROM gliderlabs/alpine:3.2
MAINTAINER Fabio Rehm "fgrehm@gmail.com"

RUN apk --update add nodejs \
    && npm install -g node-static

ADD index.html /tmp/index.html
ADD start /bin/start
CMD /bin/start

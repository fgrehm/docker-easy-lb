build: Dockerfile
	docker build -t fgrehm/docker-easy-lb .

hack:
	docker run -ti \
						 -e DEBUG=1 \
						 --rm \
						 -v `pwd`/scripts/entrypoint:/bin/entrypoint \
						 -v `pwd`/scripts/event-listener:/bin/event-listener \
						 -v `pwd`/scripts/register-container:/bin/register-container \
						 -v `pwd`/config/nginx.conf:/etc/nginx/nginx.conf \
						 -v /var/run/docker.sock:/var/run/docker.sock \
						 -v /etc/hosts:/tmp/etc-hosts \
						 --name docker-easy-lb.dev \
						 fgrehm/docker-easy-lb

node-static-test-app-build: test/node-static/*
	cd test/node-static && docker build -t remove-node-static-container . && cd -

node-static-test-app: node-static-test-app-build
	docker run \
				 -ti \
				 --rm \
				 --expose 8080 \
				 --hostname 'node-static' \
				 --label "lb-host" \
				 --name node-static-test-app \
				 remove-node-static-container \
				 /bin/sh

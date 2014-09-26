# Docker Easy Load Balancer

Experimental _automagic_ load balancing for Docker web apps in less than 100 lines of bash.

![demo](http://i.imgur.com/yRrsaAM.gif)

## Initial setup

On Ubuntu 14.04 hosts, you'll need to install [libnss-resolver](https://github.com/azukiapp/libnss-resolver#installing)
and run:

```sh
apt-get install dnsmasq
echo "nameserver 127.0.0.1:5353" | sudo tee -a /etc/resolver/docker.dev
```

_I suppose you are able to do something similiar when using Macs + [Vagrant](http://www.vagrantup.com/)
/ [boot2docker](http://boot2docker.io/) but I don't own a Mac to put the pieces
together, LMK if you know how to make this work over there and I'll update the docs
accordingly_

## Try it

Launch the load balancer and DNS server:

```sh
git clone https://github.com/fgrehm/docker-easy-lb.git
cd docker-easy-lb
./launch-host
```

And verify if things are working:

```
# Is DNS working?
$ ping hello.docker.dev

PING hello.docker.dev (172.17.0.175) 56(84) bytes of data.
64 bytes from 172.17.0.175: icmp_seq=1 ttl=64 time=0.035 ms
64 bytes from 172.17.0.175: icmp_seq=2 ttl=64 time=0.072 ms
64 bytes from 172.17.0.175: icmp_seq=3 ttl=64 time=0.150 ms
^C

# Can we reach the load balancer?
$ curl hello.docker.dev

<html>
  <head>
    <title>404 - No application configured for this subdomain</title>
    <style>


# Lets start a web server exposing the 3000 port
$ docker run -d --name hello -h hello -p 3000 ubuntu:14.04 python3 -m 'http.server' 3000
4e2731f1d2919e9a1259d9c4439e8cfb9953e8d6debbe9f64f66b8455b2ea002

# And verify that the app has been addded to the load balancer
$ curl hello.docker.dev

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ascii">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
....

# Don't forget to clean up
$ docker rm -f hello
```

## How does it work?

When the [launch-host](launch-host) script gets run, it will start a `fgrehm/easy-lb`
container with the Docker socket `/var/run/docker.sock` bind mounted inside it. From
there it will use [supervisord](supervisord.conf) to kick off [Redis](http://redis.io/)
+ [Hipache](https://github.com/hipache/hipache) + [a "service"](service.sh) that will
register a Docker [events listener](https://docs.docker.com/reference/commandline/cli/#events)
that [responsible](handler.sh) for registering / deregistering containers that
expose a port normally used by web apps.

It does not depend on any other tool apart from Docker itself but it plays really
well with [devstep](http://fgrehm.viewdocs.io/devstep), [fig](http://www.fig.sh/)
and basically anything that creates Docker containers that is able to expose the
following ports:

- `80`
- `3000`
- `4000`
- `8080`
- `9292`
- `4567`

## Troubleshooting

For some reason that I don't know yet the DNS / load balancer combo stopped
working every now and then during the early days of this project when a container
got removed. Even my Chrome browser crashed sometimes when the `dnsmasq` started
misbehaving.

When that happens I first try restarting the `dnsmasq` server launched by the
`launch-host` script and if it still doesn't work I run:

```sh
sudo dpkg-reconfigure ubuntu14-libnss-resolver
docker rm -f easy-lb
./launch-host
```

If it still doesn't make things work please create an issue with as much information
as possible on how to consistently reproduce your problem.

## TODO

- Configurable domains
- Register existing containers when bringing the load balancer up
- Create a small app that lists configured apps from `docker.dev`
- Redirect to list of configured apps in case an invalid domain is accessed
- Provide an example of an init script
- Create an entrypoint that performs some validation before starting supervisord
- Clean up / document code
- Try to setup `dnsmasq` as part of the load balancer container

## Inspiration

https://github.com/crosbymichael/skydock

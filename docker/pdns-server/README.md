# docker-pdns

Alpine based Dockerfile running a powerdns authoritative and/or recursive DNS server.

## Usage

Following environment variables can be customized.

## Example

Build a docker image named "pdns".

```shell
$ docker build -t pdns .
```

Start a docker from this image.

```shell
$ docker run --net host pdns
```


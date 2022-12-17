# barman-docker

[![Docker](https://github.com/basalam/barman-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/basalam/barman-docker/actions/workflows/docker-publish.yml)

Automatically made [barman](https://github.com/EnterpriseDB/barman/) Docker images

Based on [ubc/barman-docker](https://github.com/ubc/barman-docker)

## Why?

Every barman Docker image made manually But we want to have something to be automatically built and ready to use

With the help of github actions `schedule` feature we are using we are check for realeses every night and if the relese is new we will build it.

Also we are taking care of nightly releses directly from source code of barman

## Usage

As for images goes we have a `nightly` tag that is up to date with the latest source code from barman
we have `latest` tag that is connected to the letest (stable) relese of barman and of course for each relese we have a tag if you want to make your barman deployment version fixed.

### Kubernetes

This image is tested with [adfinis barman Helm Chart](https://github.com/adfinis/helm-charts/tree/main/charts/barman)

and you can use it easly by setting the image

### Docker Compose

here is a sample docker-compose file that you can use ;)

> Note that comments are important

```yaml
version: "3.3"

services:
  barman:
    restart: always
    image: ghcr.io/basalam/barman-docker:latest
    ports:
      - 127.0.0.1:9780:9780 # Needed for barman exporter
    environment:
      - DB_HOST=172.17.1.1
      - DB_PORT=5432
      - DB_SUPERUSER=postgres
      - DB_SUPERUSER_PASSWORD=supersecret
      - DB_REPLICATION_USER=replication
      - DB_REPLICATION_PASSWORD=supersecretreplication
      ## Check out other envs from config files templates and entrypoint
      ## TODO: Make a complete list of envs
    volumes:
      - ./data:/var/lib/barman:rw # Barman Persistant data
      - ./recovery-data:/var/lib/barman/recover:rw # Baramn Recover path
      - /var/log/barman.log:/var/log/barman.log:rw # Barman Logs
      ## Or you can fully customize configs by making a volume for all of them
```

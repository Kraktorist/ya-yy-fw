Here's docker build for the app

```
docker build . -t bingo:1.0
```

### Run instance

```
docker run \
    --rm -it \
    -v ./build/bingo-config.yml:/opt/bingo/config.yaml \
    -v /var/logs/bingo:/opt/bongo/logs \
    --entrypoint=/bin/sh \
    bingo:1.0
```

### Run docker compose

```
docker-compose up -d
```

### Initial migration

See docker-compose
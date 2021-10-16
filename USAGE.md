### what does this image contains
This contains a working install for imapfilter & imapsync.

### Usage for imapfilter

Place your imapfilter configs inside ``./imapfilter``

#### test your config
Considering your config is name ``myconfig.lua``

```sh
docker-compose run --rm  app -- bash -ec "cd imapfilter;src/imapfilter -c configs/myconfig.lua"
```
#### Run in CRON MODE
```sh
sed "/IMAGE_MODE/d" .env
echo "IMAGE_MODE=cron">>.env
docker-compose up -d --force-recreate
```

### Start at boot
set prod set of config files

```sh
sed "/COMPOSE_FILE/d" .env
echo COMPOSE_FILE=docker-compose.yml:docker-compose-prod.yml>>.env
```

Remember that you can also make a systemd unit to autoreboot your service, see [this example](./sys/imaptools.service)

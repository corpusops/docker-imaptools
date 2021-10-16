# tools for working with imaptools

This repo builds [corpusops/imaptools](https://hub.docker.com/r/corpusops/imaptools) docker image bundling imapsync & imapfilter.

## Run in dev
### Configure
```bash
cp .env.dist .env
printf "USER_UID=$(id -u)\nUSER_GID=$(id -g)\n">>.env
```

### Build
```bash
eval $(egrep -hv '^#|^\s*$' .env|sed  -e "s/^/export /g"| sed -e "s/=/='/" -e "s/$/'/g"|xargs)
COMPOSE_FILE="docker-compose.yml:docker-compose-build.yml" docker-compose build
```

### Run

```bash
docker-compose run --rm app bash
```

```bash
sed "/COMPOSE_FILE/d" .env
echo COMPOSE_FILE=docker-compose.yml:docker-compose-dev.yml:docker-compose-build.yml>>.env
docker-compose up -d --force-recreate
docker-compose exec -u app app bash
```

## Doc
see also [USAGE](./USAGE.md) (or read below on pypi)


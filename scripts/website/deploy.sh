#!/usr/bin/env bash

working_directory=$(pwd)

# Pull the latest changes
cd "$working_directory"/nginx/public/website
git stash
git pull

# Deploy to docker container
COMMANDS="
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
chmod -R 777 bootstrap/cache
chmod -R 777 storage
"
docker exec -t website-service bash -c "$COMMANDS"

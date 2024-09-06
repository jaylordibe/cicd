#!/usr/bin/env bash
set -e

working_directory=$(pwd)

# Pull the latest changes
cd "$working_directory"/nginx/public/api
git stash
git pull

# Deploy to docker container
COMMANDS="
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
chmod -R 777 bootstrap/cache
chmod -R 777 storage
php artisan migrate --force
"
docker exec -t api-service bash -c "$COMMANDS"

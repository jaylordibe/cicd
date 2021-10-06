#!/usr/bin/env bash

SOURCE_DIRECTORY=~/nginx/public/dev-api.cicd.local

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

# Deploy to docker container
COMMANDS="
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
chmod -R 777 bootstrap/cache
chmod -R 777 storage
php artisan migrate
"
docker exec -t -w /var/www/html dev-api-service bash -c "$COMMANDS"

#!/usr/bin/env bash

# Setup API
COMMANDS="
chmod -R 777 bootstrap/cache
chmod -R 777 storage
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
php artisan migrate:fresh --seed
php artisan key:generate
php artisan passport:install
php artisan passport:keys
"
docker exec -t api-service bash -c "$COMMANDS"

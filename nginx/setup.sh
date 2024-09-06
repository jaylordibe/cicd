#!/usr/bin/env bash

# Setup API
COMMANDS="
chmod -R 777 bootstrap/cache
chmod -R 777 storage
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
php artisan migrate:fresh --seed --force
php artisan key:generate --force
php artisan passport:keys --force
echo 'y' | php artisan passport:client --personal --name='API Personal Access Client'
echo 'y' | php artisan passport:client --password --name='API Password Grant Client' --provider='users'
"
docker exec -t api-service bash -c "$COMMANDS"

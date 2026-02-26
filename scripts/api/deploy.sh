#!/usr/bin/env bash
set -e

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd "$script_dir"

# Pull the latest changes
cd ../../nginx/public/api
git stash
git pull

# Deploy to docker container
commands="
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
composer dump-autoload --optimize
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan migrate --force
php artisan horizon:terminate
"
docker exec -t api-service bash -c "$commands"

# Navigate back to the working directory
cd "$working_dir"

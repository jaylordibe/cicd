#!/usr/bin/env bash
set -e

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd $script_dir

# Pull the latest changes
cd ../../nginx/public/website
git stash
git pull

# Deploy to docker container
commands="
composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
chmod -R 777 bootstrap/cache
chmod -R 777 storage
"
docker exec -t website-service bash -c "$commands"

# Navigate back to the working directory
cd $working_dir

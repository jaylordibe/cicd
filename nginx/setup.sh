#!/usr/bin/env bash
set -e

working_directory=$(pwd)
current_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker_services_string="$1"

if [[ "$docker_services_string" == *"api-service"* ]]; then
  echo "Setting up api service..."
  commands="
  chmod -R 777 bootstrap/cache
  chmod -R 777 storage
  composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
  php artisan migrate:fresh --seed --force
  php artisan key:generate --force
  php artisan passport:keys --force
  echo 'y' | php artisan passport:client --personal --name='API Personal Access Client'
  echo 'y' | php artisan passport:client --password --name='API Password Grant Client' --provider='users'
  "
  docker exec -t api-service bash -c "$commands"
fi

if [[ "$docker_services_string" == *"webapp-service"* ]]; then
  echo "Setting up webapp service..."
  docker exec -t webapp-service bash -c "echo 'n' | ng analytics disable"
fi

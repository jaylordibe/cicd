#!/usr/bin/env bash
set -e

echo "Setting up docker services/containers..."

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd "$script_dir"

# Get the docker services string parameter
docker_services_string="$1"

# Setup the api service
if [[ "$docker_services_string" == *"api-service"* ]]; then
  echo "Setting up api service..."
  commands="
  composer install --no-ansi --no-interaction --no-progress --no-scripts --optimize-autoloader
  php artisan migrate:fresh --seed --force
  php artisan key:generate --force
  php artisan passport:keys --force
  php artisan passport:client --personal --name='API Personal Access Client' --provider=users --no-interaction
  php artisan passport:client --password --name='API Password Grant Client' --provider=users --no-interaction
  php artisan storage:link
  chmod -R 775 bootstrap/cache
  chmod -R 775 storage
  chown -R www-data:www-data storage
  chmod 600 storage/oauth-private.key
  chmod 600 storage/oauth-public.key
  "
  docker exec -t api-service bash -c "$commands"
fi

# Setup the webapp service
if [[ "$docker_services_string" == *"webapp-service"* ]]; then
  echo "Setting up webapp service..."
  docker exec -t webapp-service bash -c "echo 'n' | ng analytics disable"
fi

# Navigate back to the working directory
cd "$working_dir"

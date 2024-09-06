#!/usr/bin/env bash
set -e

echo "Starting docker services..."

working_directory=$(pwd)
current_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker_services_string="$1"

docker compose -f "$working_directory"/nginx/docker-compose.yml up -d $docker_services_string

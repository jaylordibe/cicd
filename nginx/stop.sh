#!/usr/bin/env bash
set -e

echo "Stopping docker services..."

working_directory=$(pwd)
current_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker compose -f "$working_directory"/nginx/docker-compose.yml down

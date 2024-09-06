#!/usr/bin/env bash
set -e

echo "Stopping docker services..."

working_directory=$(pwd)

docker compose -f "$working_directory"/nginx/docker-compose.yml down

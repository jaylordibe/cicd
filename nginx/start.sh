#!/usr/bin/env bash

echo "Starting docker services..."

working_directory=$(pwd)
docker_services_string="$1"

docker compose -f "$working_directory"/nginx/docker-compose.yml up -d $docker_services_string

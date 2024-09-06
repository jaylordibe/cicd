#!/usr/bin/env bash

# Declare the global variable
working_directory=$(pwd)

echo "Stopping docker services..."
docker compose -f "$working_directory"/nginx/docker-compose.yml down

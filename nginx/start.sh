#!/usr/bin/env bash

# Declare the global variable
working_directory=$(pwd)

echo "Starting docker services..."
docker compose -f "$working_directory"/nginx/docker-compose.yml up -d

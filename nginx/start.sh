#!/usr/bin/env bash
set -e

echo "Starting docker services/containers..."

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd "$script_dir"

# Get the docker services string parameter
docker_services_string="$1"

# Start the docker services/containers
docker compose up -d $docker_services_string

# Navigate back to the working directory
cd "$working_dir"

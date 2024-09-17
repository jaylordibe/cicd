#!/usr/bin/env bash
set -e

echo "Stopping docker services/containers..."

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd "$script_dir"

# Stop the docker services/containers
docker compose down

# Navigate back to the working directory
cd "$working_dir"

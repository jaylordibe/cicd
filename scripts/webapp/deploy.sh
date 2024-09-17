#!/usr/bin/env bash
set -e

working_dir=$(pwd)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the script directory
cd $script_dir

# Pull the latest changes
cd ../../nginx/public/webapp
git stash
git pull

# Deploy to docker container
commands="
[ -d public ] && rm -r public/
[ -d dist ] && rm -r dist/
npm install
echo 'n' | ng build --configuration=production --output-path=dist
mv dist/browser/ public/
"
docker exec -t webapp-service bash -c "$commands"
sudo chown -R $(whoami) public/
sudo chmod -R 775 public/
cp ../../../scripts/webapp/.htaccess public/

# Navigate back to the working directory
cd $working_dir

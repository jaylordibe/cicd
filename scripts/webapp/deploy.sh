#!/usr/bin/env bash

working_directory=$(pwd)

# Pull the latest changes
cd "$working_directory"/nginx/public/webapp
git stash
git pull

# Deploy to docker container
COMMANDS="
npm install
echo 'n' | ng build --configuration=production --output-path=dist
[ -d public ] && rm -r public
mv dist/browser/ public/
[ -d dist ] && rm -r dist/
"
docker exec -t webapp-service bash -c "$COMMANDS"
sudo chown -R $(whoami) public/
sudo chmod -R 775 public/
cp "$working_directory"/scripts/webapp/.htaccess public/

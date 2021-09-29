#!/usr/bin/env bash

WORKING_DIRECTORY=$(pwd)
SOURCE_DIRECTORY=~/nginx/public/app.site.local

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

# Deploy to docker container
COMMANDS="
npm install
ng build --configuration=staging
"
docker exec -t -w /var/www/html app-service bash -c "$COMMANDS"
sudo mv dist/app .
sudo rm -r dist
sudo mv app dist
sudo cp ${WORKING_DIRECTORY}/.htaccess dist/

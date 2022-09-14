#!/usr/bin/env bash

WORKING_DIRECTORY=$(pwd)
SOURCE_DIRECTORY=~/cicd/nginx/public/app

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
sudo rm -r public/
sudo mv dist/app/ public/
sudo rm -r dist/
sudo cp ${WORKING_DIRECTORY}/.htaccess public/

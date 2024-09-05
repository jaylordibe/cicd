#!/usr/bin/env bash

WORKING_DIRECTORY=$(pwd)
SOURCE_DIRECTORY=~/cicd/nginx/public/webapp

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

# Deploy to docker container
COMMANDS="
npm install
ng build --configuration=production
"
docker exec -t webapp-service bash -c "$COMMANDS"
sudo rm -r public/
sudo mv dist/cicd-webapp/browser public/
sudo rm -r dist/
sudo cp ${WORKING_DIRECTORY}/.htaccess public/

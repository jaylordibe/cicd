#!/usr/bin/env bash

WORKING_DIRECTORY=~/cicd/scripts/webapp
SOURCE_DIRECTORY=~/cicd/nginx/public/webapp

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

# Deploy to docker container
COMMANDS="
npm install
ng build --configuration=production
rm -r public/
mv dist/utakpro-app/browser/ public/
rm -r dist/
"
docker exec -t webapp-service bash -c "$COMMANDS"
sudo chown -R $(whoami):$(whoami) public/
sudo chmod -R 777 public/
cp ${WORKING_DIRECTORY}/.htaccess public/

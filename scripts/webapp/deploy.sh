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
rm -r public/
mv dist/cicd-webapp/browser/ public
rm -r dist
cp .htaccess public
"
docker exec -t webapp-service bash -c "$COMMANDS"

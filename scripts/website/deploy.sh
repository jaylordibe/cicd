#!/usr/bin/env bash

WORKING_DIRECTORY=$(pwd)
SOURCE_DIRECTORY=~/cicd/nginx/public/cicd-website

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

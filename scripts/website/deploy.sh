#!/usr/bin/env bash

WORKING_DIRECTORY=$(pwd)
SOURCE_DIRECTORY=~/nginx/public/www.site.local

# Pull the latest changes
cd ${SOURCE_DIRECTORY}
git stash
git pull

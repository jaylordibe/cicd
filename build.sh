#!/usr/bin/env bash

# Function to replace static string in a file with the value from config.json
replace_config_value() {
  local static_string="$1"
  local config_key="$2"
  local file_path="$3"

  # Step 1: Extract the value from config.json using grep and awk
  local config_value=$(grep "\"$config_key\"" config.json | awk -F'"' '{print $4}')

  # Check if extraction was successful
  if [[ -z "$config_value" ]]; then
    echo "Error: Failed to extract $config_key from config.json"
    return 1
  fi

  # Step 2: Replace the static string with the extracted config value in the specified file

  # Detect platform and use the appropriate sed syntax
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS uses a different sed syntax
    sed -i '' "s/$static_string/$config_value/g" "$file_path"
  else
    # Linux or other Unix-like OS
    sed -i "s/$static_string/$config_value/g" "$file_path"
  fi

  # Check if sed command succeeded
  if [[ $? -eq 0 ]]; then
    echo "Successfully replaced '$static_string' with '$config_value' in $file_path"
  else
    echo "Error: Failed to replace text in $file_path"
    return 1
  fi
}

# Function to clone repositories to nginx/public and rename the folders
clone_repositories() {
  local repo_key="$1"
  local destination_folder="$2"

  # Step 1: Extract the repository URL from config.json using grep and awk
  local repo_url=$(grep "\"$repo_key\"" config.json | awk -F'"' '{print $4}')

  # Check if the repository URL is not empty
  if [[ -z "$repo_url" ]]; then
    echo "Skipping clone for $repo_key because the value is empty in config.json."
    return 0
  fi

  # Check if the destination folder already exists
  if [[ -d "nginx/public/$destination_folder" ]]; then
    echo "The destination folder 'nginx/public/$destination_folder' already exists."
    echo "Proceeding to replace the contents with the repository $repo_key ($repo_url)."

    # Remove the existing folder to ensure a clean clone
    rm -rf "nginx/public/$destination_folder"
  fi

  # Step 2: Clone the repository to the nginx/public directory
  git clone "$repo_url" "nginx/public/$destination_folder"

  # Check if git clone succeeded
  if [[ $? -eq 0 ]]; then
    echo "Successfully cloned $repo_key ($repo_url) to nginx/public/$destination_folder"
  else
    echo "Error: Failed to clone repository $repo_url"
    return 1
  fi
}

# Replace the config values
replace_config_value "api.cicd.local" "apiDomain" "nginx/conf/sites-available/api.conf"
replace_config_value "webapp.cicd.local" "webappDomain" "nginx/conf/sites-available/webapp.conf"
replace_config_value "www.cicd.local" "websiteDomain" "nginx/conf/sites-available/website.conf"
replace_config_value "cicd.local" "rootDomain" "nginx/conf/sites-available/website.conf"

# Clone the repositories
clone_repositories "apiRepository" "api"
clone_repositories "webappRepository" "webapp"
clone_repositories "websiteRepository" "website"

#!/usr/bin/env bash

# Function to handle sed replacement depending on the operating system
sed_replace() {
  local pattern="$1"
  local file_path="$2"

  # Check the operating system type and use the appropriate sed syntax
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS uses a different sed syntax
    sed -i '' "$pattern" "$file_path"
  else
    # Linux or other Unix-like OS
    sed -i "$pattern" "$file_path"
  fi
}

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
  sed_replace "s/$static_string/$config_value/g" "$file_path"

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

# Function to create .env file from .env.example and update variables
create_and_update_api_env() {
  local env_example_path="nginx/public/api/.env.example"
  local env_path="nginx/public/api/.env"

  # Step 1: Check if .env.example file exists
  if [[ ! -f "$env_example_path" ]]; then
    echo "Error: .env.example file does not exist at $env_example_path"
    return 1
  fi

  # Step 2: Copy .env.example to .env
  cp "$env_example_path" "$env_path"

  # Step 3: Use the shared DB passwords
  local db_host="database-service"
  local db_root_password="$1"
  local db_password="$2"

  # Step 4: Extract appName from config.json
  local app_name=$(grep '"appName"' config.json | awk -F'"' '{print $4}')

  # Step 5: Update .env file with generated values and appName from config.json
  sed_replace "s/DB_HOST=.*/DB_HOST=\"$db_host\"/g" "$env_path"
  sed_replace "s/DB_DATABASE=.*/DB_DATABASE=\"$app_name\"/g" "$env_path"
  sed_replace "s/DB_USERNAME=.*/DB_USERNAME=\"$app_name\"/g" "$env_path"
  sed_replace "s/DB_PASSWORD=.*/DB_PASSWORD=\"$db_password\"/g" "$env_path"

  # Step 6: Check if DB_ROOT_PASSWORD is present in .env file; if not, insert it after DB_PASSWORD line
  if ! grep -q "DB_ROOT_PASSWORD" "$env_path"; then
    # Insert DB_ROOT_PASSWORD after DB_PASSWORD line and add a newline after it
    sed_replace "/DB_PASSWORD=.*/a\\
DB_ROOT_PASSWORD=\"$db_root_password\"\\
" "$env_path"
    echo "Inserted DB_ROOT_PASSWORD after DB_PASSWORD in $env_path"
  else
    # Update the DB_ROOT_PASSWORD if it already exists
    sed_replace "s/DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=\"$db_root_password\"/g" "$env_path"
  fi

  echo "Successfully created and updated .env file at $env_path"
}

# Function to create a docker .env file in the project directory
create_docker_env() {
  local docker_env_path="nginx/.env"

  # Step 1: Check if the docker .env file exists and remove it
  if [[ -f "$docker_env_path" ]]; then
    echo "Removing existing docker .env file at $docker_env_path"
    rm "$docker_env_path"
  fi

  # Step 2: Use the shared DB passwords
  local db_root_password="$1"
  local db_password="$2"

  # Step 2: Extract appName from config.json
  local app_name=$(grep '"appName"' config.json | awk -F'"' '{print $4}')

  # Step 3: Write the variables to the .env file
  cat <<EOL > "$docker_env_path"
DB_DATABASE="$app_name"
DB_USERNAME="$app_name"
DB_PASSWORD="$db_password"
DB_ROOT_PASSWORD="$db_root_password"
EOL

  echo "Successfully created docker .env file at $docker_env_path"
}

# Replace the config values
replace_config_value "api.cicd.local" "apiDomain" "nginx/conf/sites-available/api.conf"
replace_config_value "cicd.local" "rootDomain" "nginx/conf/sites-available/api.conf"
replace_config_value "webapp.cicd.local" "webappDomain" "nginx/conf/sites-available/webapp.conf"
replace_config_value "cicd.local" "rootDomain" "nginx/conf/sites-available/webapp.conf"
replace_config_value "www.cicd.local" "websiteDomain" "nginx/conf/sites-available/website.conf"
replace_config_value "cicd.local" "rootDomain" "nginx/conf/sites-available/website.conf"

# Clone the repositories
clone_repositories "apiRepository" "api"
clone_repositories "webappRepository" "webapp"
clone_repositories "websiteRepository" "website"

# Setup environment variables
db_root_password=$(openssl rand -base64 12)
db_password=$(openssl rand -base64 12)
create_and_update_api_env "$db_root_password" "$db_password"
create_docker_env "$db_root_password" "$db_password"

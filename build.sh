#!/usr/bin/env bash
set -e
set -a

# Declare the global variable
working_directory=$(pwd)

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

# Function to check if a config value is present in the config.json file
is_config_value_present() {
  local config_key="$1"
  local config_value=$(grep "\"$config_key\"" "$working_directory"/config.json | awk -F'"' '{print $4}')

  if [[ -z "$config_value" ]]; then
    echo "Empty $config_key value from config.json"
    return 1
  fi

  return 0
}

# Function to replace static string in a file with the value from config.json
replace_config_value() {
  local static_string="$1"
  local config_key="$2"
  local file_path="$3"

  # Step 1: Extract the value from config.json using grep and awk
  local config_value=$(grep "\"$config_key\"" "$working_directory"/config.json | awk -F'"' '{print $4}')

  # Check if extraction was successful
  if [[ -z "$config_value" ]]; then
    echo "Empty $config_key value from config.json. Skipping config update"
    return 0
  fi

  # Step 2: Replace the static string with the extracted config value in the specified file
  sed_replace "s/$static_string/$config_value/g" "$file_path"

  # Check if sed command succeeded
  if [[ $? -eq 0 ]]; then
    echo "Successfully replaced '$static_string' with '$config_value' in $file_path"
  else
    echo "Error: Failed to replace text in $file_path"
    return 0
  fi
}

# Function to clone repositories to nginx/public and rename the folders
clone_repositories() {
  local repo_key="$1"
  local destination_folder="$2"

  # Step 1: Extract the repository URL from config.json using grep and awk
  local repo_url=$(grep "\"$repo_key\"" "$working_directory"/config.json | awk -F'"' '{print $4}')

  # Check if the repository URL is not empty
  if [[ -z "$repo_url" ]]; then
    echo "Skipping clone for $repo_key because the value is empty in config.json."
    return 0
  fi

  # Check if the destination folder already exists
  if [[ -d "$working_directory/nginx/public/$destination_folder" ]]; then
    echo "The destination folder 'nginx/public/$destination_folder' already exists."
    echo "Proceeding to replace the contents with the repository $repo_key ($repo_url)."

    # Remove the existing folder to ensure a clean clone
    sudo rm -rf "$working_directory/nginx/public/$destination_folder"
  fi

  # Step 2: Clone the repository to the nginx/public directory
  git clone "$repo_url" "$working_directory/nginx/public/$destination_folder"

  # Check if git clone succeeded
  if [[ $? -eq 0 ]]; then
    echo "Successfully cloned $repo_key ($repo_url) to nginx/public/$destination_folder"
  else
    echo "Error: Failed to clone repository $repo_url"
    return 0
  fi
}

# Function to create .env file from .env.example and update variables
create_and_update_api_env() {
  local env_example_path="$working_directory/nginx/public/api/.env.example"
  local env_path="$working_directory/nginx/public/api/.env"

  # Step 1: Check if .env.example file exists
  if [[ ! -f "$env_example_path" ]]; then
    echo "Skipping create_and_update_api_env: .env.example file does not exist at $env_example_path"
    return 0
  fi

  # Step 2: Copy .env.example to .env
  cp "$env_example_path" "$env_path"

  # Step 3: Use the shared DB passwords
  local db_host="database-service"
  local db_root_password="$1"
  local db_password="$2"

  # Step 4: Extract appName from config.json
  local app_env=$(grep '"appEnv"' "$working_directory"/config.json | awk -F'"' '{print $4}')
  local app_name=$(grep '"appName"' "$working_directory"/config.json | awk -F'"' '{print $4}')
  local app_domain=$(grep '"rootDomain"' "$working_directory"/config.json | awk -F'"' '{print $4}')

  # Step 5: Update .env file with generated values and appName from config.json
  sed_replace "s/APP_ENV=.*/APP_ENV=\"$app_env\"/g" "$env_path"
  sed_replace "s/APP_DOMAIN=.*/APP_DOMAIN=\"$app_domain\"/g" "$env_path"
  sed_replace "s/APP_DEBUG=.*/APP_DEBUG=false/g" "$env_path"
  sed_replace "s/DB_HOST=.*/DB_HOST=$db_host/g" "$env_path"
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
  local docker_env_path="$working_directory/nginx/.env"

  # Step 1: Check if the docker .env file exists and remove it
  if [[ -f "$docker_env_path" ]]; then
    echo "Removing existing docker .env file at $docker_env_path"
    rm "$docker_env_path"
  fi

  # Step 2: Use the shared DB passwords
  local db_root_password="$1"
  local db_password="$2"

  # Step 2: Extract appName from config.json
  local app_name=$(grep '"appName"' "$working_directory"/config.json | awk -F'"' '{print $4}')

  # Step 3: Write the variables to the .env file
  cat <<EOL > "$docker_env_path"
DB_DATABASE="$app_name"
DB_USERNAME="$app_name"
DB_PASSWORD="$db_password"
DB_ROOT_PASSWORD="$db_root_password"
EOL

  echo "Successfully created docker .env file at $docker_env_path"
}

start_services() {
  local db_root_password="$1"
  local docker_services_string="$2"

  # Start the docker services
  "$working_directory"/nginx/start.sh "$docker_services_string"

  if [[ "$docker_services_string" == *"api-service"* ]]; then
    echo "Waiting for the containers to initialize..."
    while ! docker exec database-service mysql -uroot -p"$db_root_password" -e "SELECT 1" >/dev/null 2>&1; do
      sleep 1
    done
  fi

  # Setup the services
  "$working_directory"/nginx/setup.sh "$docker_services_string"
}

deploy_application() {
  local repo_key="$1"
  local script_folder="$2"
  local repo_url=$(grep "\"$repo_key\"" "$working_directory"/config.json | awk -F'"' '{print $4}')
  local deploy_script="$working_directory/scripts/$script_folder/deploy.sh"

  # Check if the repository URL is not empty
  if [[ -z "$repo_url" ]]; then
    echo "Skipping deployment for $repo_key because the value is empty in config.json."
    return 0
  fi

  # Check if the deployment script exists
  if [[ ! -f "$deploy_script" ]]; then
    echo "Deployment script $deploy_script does not exist for $repo_key"
    return 0
  fi

  # Run the deployment script
  if ! "$deploy_script"; then
    echo "Deployment failed for $repo_key"
    return 0
  fi

  echo "$script_folder successfully deployed"
}

main() {
  # Stop the existing docker services
  "$working_directory"/nginx/stop.sh

  # Remove the public folder if it exists
  [ -d "$working_directory/nginx/public" ] && sudo rm -r "$working_directory/nginx/public"

  # Generate database passwords
  local db_root_password=$(openssl rand -base64 12)
  local db_password=$(openssl rand -base64 12)

  # Docker services
  local docker_services=("webserver-service")

  if is_config_value_present "apiRepository"; then
    # Add the api and database services to the docker services array
    docker_services+=("api-service" "database-service")

    # Replace the config values
    replace_config_value "api.domain" "apiDomain" "$working_directory/nginx/conf/sites-available/api.conf"
    replace_config_value "root.domain" "rootDomain" "$working_directory/nginx/conf/sites-available/api.conf"

    # Clone the repositories
    clone_repositories "apiRepository" "api"

    # Create and update the api .env file
    create_and_update_api_env "$db_root_password" "$db_password"
  fi

  if is_config_value_present "webappRepository"; then
    # Add the webapp service to the docker services array
    docker_services+=("webapp-service")

    # Replace the config values
    replace_config_value "webapp.domain" "webappDomain" "$working_directory/nginx/conf/sites-available/webapp.conf"
    replace_config_value "root.domain" "rootDomain" "$working_directory/nginx/conf/sites-available/webapp.conf"
    replace_config_value "app.env" "appEnv" "$working_directory/scripts/webapp/deploy.sh"

    # Clone the repositories
    clone_repositories "webappRepository" "webapp"
  fi

  if is_config_value_present "websiteRepository"; then
    # Add the website service to the docker services array
    docker_services+=("website-service")

    # Replace the config values
    replace_config_value "website.domain" "websiteDomain" "$working_directory/nginx/conf/sites-available/website.conf"
    replace_config_value "root.domain" "rootDomain" "$working_directory/nginx/conf/sites-available/website.conf"

    # Clone the repositories
    clone_repositories "websiteRepository" "website"
  fi

  # Create the docker .env file
  create_docker_env "$db_root_password" "$db_password"
  source "$working_directory"/nginx/.env

  # Remove the database folder if it exists
  [ -d "$working_directory"/nginx/database ] && sudo rm -r "$working_directory"/nginx/database

  # Start the docker services
  docker_services_string="${docker_services[@]}"
  echo "$docker_services_string"
  start_services "$db_root_password" "$docker_services_string"

  # Deploy applications
  deploy_application "apiRepository" "api"
  deploy_application "webappRepository" "webapp"
  deploy_application "websiteRepository" "website"
}

main

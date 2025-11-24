# CI/CD SETUP

### This is a CI/CD pipeline using GitHub Actions, Docker, and Nginx

### nginx directory
* Contains all the nginx related files and configurations

### scripts directory
* Contains all the deployment scripts

### Build and run the pipeline
* Update the config.json file with the correct values
* Just provide the repository of the application that you want to deploy. You can empty the other fields if you don't want to use them
* Run the following command to build and run the pipeline
```
./provision.sh
```

### Prerequisites
* [Docker](https://docs.docker.com/engine/install/)
* [Docker Compose](https://docs.docker.com/compose/install/)
* [Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)
* [Configure Docker to start on boot](https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot)

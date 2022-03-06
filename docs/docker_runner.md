# Deploy via docker

We use docker image to package all the dependencies and tools witch you need to deploy your infrastucture.

Just run:

    ./docker.sh <your command>


for run any command inside docker container

For example, you can read config by this command:

    source $(./docker.sh read ./configs/env/<env_name>)

and than you can deploy your apps in kubernetes cluster, by this command:

    ./docker.sh ./scripts/k8s/deploy_apps.bash deploy

# Deploy without docker (deprecated way)

Read config:

    source $(./scripts/read_config.sh ./configs/env/<env_name>)

Deploy k8s apps (Just remove):

    ./scripts/k8s/deploy_apps.bash deploy

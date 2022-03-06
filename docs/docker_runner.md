# Deploy via docker

To deploy our infrastructure, you **only need to install docker** on your local enviroment, because we use docker image to package all the dependencies and tools witch you need for deploy process.

First if you don't login in gcloud tool before please execute:

     ./docker.sh gcloud auth login

**ATENTION!**
    This overwrite your gcloud credentials inside ~/.config/gcloud

Than you need read env config by this command:

    source $(./docker.sh read ./configs/env/<env_name>)

and than you can run any command inside prepared enviroment inside docker container, for example, deploy apps in kubernetes cluster:

    ./docker.sh ./scripts/k8s/deploy_apps.bash deploy

# Deploy without docker (deprecated way)

Read config:

    source $(./scripts/read_config.sh ./configs/env/<env_name>)

Deploy k8s apps (Just remove):

    ./scripts/k8s/deploy_apps.bash deploy

and you need install all dependencies manualy

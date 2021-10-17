#!/usr/bin/env bash

function create_k8s_cluster()
{
    gcloud container --project ${env_project_id} clusters create ${env_k8s_cluster_name} \
        --region ${env_k8s_nodes_region} \
        --cluster-version "${env_k8s_version}" \
        --machine-type ${env_k8s_nodes_type} \
        --scopes="https://www.googleapis.com/auth/devstorage.read_write" \
        --image-type "COS" \
        --disk-type "${env_k8s_nodes_disk_type}" \
        --disk-size "${env_k8s_nodes_disk_size}" \
        --num-nodes ${env_k8s_nodes_count} \
        --network "default" \
        --subnetwork "default" \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing \
        --no-enable-autoupgrade \
        --enable-autorepair
}

function setup_cloudbuild()
{
    gcloud services enable --project ${env_project_id} cloudbuild.googleapis.com

    gcloud iam service-accounts --project ${env_project_id} create kuberengine --display-name "CI/CD deployment"

    gcloud projects add-iam-policy-binding ${env_project_id} \
        --member serviceAccount:kuberengine@${env_project_id}.iam.gserviceaccount.com \
        --role roles/cloudbuild.builds.builder

    gcloud projects add-iam-policy-binding ${env_project_id} \
        --member serviceAccount:kuberengine@${env_project_id}.iam.gserviceaccount.com \
        --role roles/container.developer

    gcloud projects add-iam-policy-binding ${env_project_id} \
        --member serviceAccount:kuberengine@${env_project_id}.iam.gserviceaccount.com \
        --role roles/storage.admin
}

function deploy_k8s_ingress_nginx()
{
    gcloud container clusters get-credentials ${env_k8s_cluster_name} --zone ${env_k8s_nodes_region} --project ${env_project_id}

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml
}

function deploy_k8s_cert_manager()
{
    gcloud container clusters get-credentials ${env_k8s_cluster_name} --zone ${env_k8s_nodes_region} --project ${env_project_id}

    kubectl create namespace cert-manager

    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

    CLOUD_DNS_SA=cloud-dns-admin-${env_name}

    gcloud --project ${env_project_id}  iam service-accounts create $CLOUD_DNS_SA \
        --display-name "Service Account to support ACME DNS-01 challenge."

    CLOUD_DNS_SA=$CLOUD_DNS_SA@${env_project_id}.iam.gserviceaccount.com

    gcloud projects add-iam-policy-binding ${env_project_id}  \
        --member serviceAccount:$CLOUD_DNS_SA \
        --role roles/dns.admin

    KEY_DIRECTORY=`mktemp -d`

    gcloud iam service-accounts keys create $KEY_DIRECTORY/cloud-dns-key.json \
        --iam-account=$CLOUD_DNS_SA

    kubectl create secret --namespace cert-manager generic cloud-dns-key \
        --from-file=key.json=$KEY_DIRECTORY/cloud-dns-key.json
}

#!/usr/bin/env bash

function get_credentials() 
{
    if [ ! -z ${env_k8s_kubeconfig_cluster_certificate_authority_data} ]; then
        K8S_CLUSTER="${env_k8s_cluster_name}"
        K8S_USER="${env_k8s_cluster_name}-admin"
        K8S_CONTEXT="${env_k8s_cluster_name}-ctx"

        kubectl config set "clusters.${K8S_CLUSTER}.certificate-authority-data" ${env_k8s_kubeconfig_cluster_certificate_authority_data}
        kubectl config set "clusters.${K8S_CLUSTER}.server" ${env_k8s_kubeconfig_cluster_server}

        kubectl config set "users.${K8S_USER}.client-certificate-data" ${env_k8s_kubeconfig_user_client_certificate_data}
        kubectl config set "users.${K8S_USER}.client-key-data" ${env_k8s_kubeconfig_user_client_key_data}

        kubectl config set "contexts.${K8S_CONTEXT}.cluster" "${K8S_CLUSTER}"
        kubectl config set "contexts.${K8S_CONTEXT}.user" "$K8S_USER"

        kubectl config set "current-context" "${K8S_CONTEXT}"
    else
        gcloud container clusters get-credentials ${env_k8s_cluster_name} --zone ${env_k8s_nodes_region} --project ${env_project_id}
    fi
}

function create_ns_if_doesnt_exists()
{
    #https://stackoverflow.com/questions/63135361/how-to-create-kubernetes-namespace-if-it-does-not-exist
    local namespace=$1
    kubectl create namespace $namespace --dry-run -o yaml | kubectl apply -f -
}

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
        --enable-ip-alias \
        --network ${env_k8s_network_name} \
        --create-subnetwork name=${env_k8s_network_subnet},range=${env_k8s_network_ip_range} \
        --cluster-ipv4-cidr ${env_k8s_network_pod_ip_range} \
        --services-ipv4-cidr ${env_k8s_network_services_ip_range} \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing \
        --no-enable-autoupgrade \
        --enable-autorepair
}

function create_namespaces()
{
    get_credentials
    create_ns_if_doesnt_exists ${env_k8s_apps_namespace}
}

function setup_cloudbuild()
{
    PROJECT_NUMBER=$(gcloud projects describe ${env_project_id} --format json | jq '.projectNumber' | tr -d '"')

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

    gcloud projects add-iam-policy-binding ${env_project_id} \
        --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
        --role roles/compute.admin
}

function setup_cloudsql_proxy()
{
    get_credentials
    gcloud iam service-accounts create sqlproxy \
        --project ${env_project_id} \
        --display-name "SQL proxy"

    gcloud projects add-iam-policy-binding ${env_project_id} \
        --member serviceAccount:sqlproxy@${env_project_id}.iam.gserviceaccount.com \
        --role roles/cloudsql.client

    gcloud iam service-accounts keys create /tmp/sqlproxy-key.json \
        --iam-account sqlproxy@${env_project_id}.iam.gserviceaccount.com

    kubectl -n ${env_k8s_apps_namespace} create secret generic cloudsql-instance-credentials \
        --from-file=service_account.json=/tmp/sqlproxy-key.json
}

function deploy_k8s_ingress_nginx()
{
    get_credentials

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml
}

function deploy_k8s_cert_manager()
{
    get_credentials

    create_ns_if_doesnt_exists cert-manager

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

function deploy_k8s_manifests()
{
    local namespace="manifests"
    get_credentials
    create_ns_if_doesnt_exists $namespace
    kubectl apply -f manifests/${env_name} --recursive -n $namespace
}

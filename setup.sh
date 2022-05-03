#!/bin/bash -xe
#export PROJECT_ID=flius-vpc-2

#specify GKE cluster name, cluster domain name for mongodb
read -t 30 -p "Please input GKE cluster name: " CLUSTER_NAME
echo "GKE cluster name: $CLUSTER_NAME"
export CLUSTER_NAME=$CLUSTER_NAME
read -t 30 -p "Please input MongoDB cluster domain: " CLUSTER_DOMAIN
echo "Mondb cluster domain: $CLUSTER_DOMAIN"
export CLUSTER_DOMAIN=$CLUSTER_DOMAIN
read -t 30 -p "Please input machine type you need: " MACHINE_TYPE
echo "GKE machine type: $MACHINE_TYPE"
export MACHINE_TYPE=$MACHINE_TYPE


#enable service apis
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable clouddeploy.googleapis.com
gcloud services enable orgpolicy.googleapis.com

#set default region, zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

PROJECT_ID=$(gcloud config get-value project)
GCP_REGION=$(gcloud config get-value compute/region)
PROJECT_NUMBER=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")

#set iam, role bindings
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/iam.serviceAccountTokenCreator

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/container.clusterAdmin

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/container.admin

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/compute.admin

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/compute.storageAdmin

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/clouddeploy.admin

#Please make sure you have the org admin permissions
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/requireShieldedVm.yaml
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/requireOsLogin.yaml
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/vmExternalIpAccess.yaml
# gcloud org-policies set-policy org-policies/requireShieldedVm.yaml
# gcloud org-policies set-policy org-policies/requireOsLogin.yaml
# gcloud org-policies set-policy org-policies/vmExternalIpAccess.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/requireShieldedVm.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/requireOsLogin.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/vmExternalIpAccess.yaml

#submit cloud build job
gcloud builds submit \
--substitutions=_PROJECT_ID=${PROJECT_ID},_GCP_REGION=${GCP_REGION},_CLUSTER_NAME=${CLUSTER_NAME},_CLUSTER_DOMAIN=${CLUSTER_DOMAIN},_MACHINE_TYPE=${MACHINE_TYPE}
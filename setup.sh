#!/bin/bash -x
trap 'exit' ERR
#export PROJECT_ID=flius-vpc-2

#specify GKE cluster name, cluster domain name for mongodb
read -t 30 -p "Please input GKE cluster name: " CLUSTER_NAME
echo "GKE cluster name: $CLUSTER_NAME"
export CLUSTER_NAME=$CLUSTER_NAME
read -t 30 -p "Please input MongoDB cluster domain: " CLUSTER_DOMAIN
echo "Mondb cluster domain: $CLUSTER_DOMAIN"
export CLUSTER_DOMAIN=$CLUSTER_DOMAIN
read -t 30 -p "Please input machine type: " MACHINE_TYPE
echo "GKE machine type: $MACHINE_TYPE"
export MACHINE_TYPE=$MACHINE_TYPE
read -t 30 -p "Please input MongoDB operator pod profile <small | medium | large>: " CLUSTER_PROFILE
echo "MongoDB cluster profile: $CLUSTER_PROFILE"
export CLUSTER_PROFILE=$CLUSTER_PROFILE

#enable service apis
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable clouddeploy.googleapis.com
gcloud services enable orgpolicy.googleapis.com
gcloud services enable dns.googleapis.com

#set default region, zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

PROJECT_ID=$(gcloud config get-value project)
GCP_REGION=$(gcloud config get-value compute/region)
PROJECT_NUMBER=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")

# Please make sure you have the org admin permissions
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/requireShieldedVm.yaml
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/requireOsLogin.yaml
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/vmExternalIpAccess.yaml
# sed -i .bak "s/PROJECT_ID/${PROJECT_ID}/" org-policies/vmCanIpForward.yaml
# gcloud org-policies set-policy org-policies/requireShieldedVm.yaml
# gcloud org-policies set-policy org-policies/requireOsLogin.yaml
# gcloud org-policies set-policy org-policies/vmExternalIpAccess.yaml
# gcloud org-policies set-policy org-policies/vmCanIpForward.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/requireShieldedVm.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/requireOsLogin.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/vmExternalIpAccess.yaml
# sed -i .bak "s/${PROJECT_ID}/PROJECT_ID/" org-policies/vmCanIpForward.yaml

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

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/iam.serviceAccountAdmin

# for velero service account & bucket
BUCKET=$PROJECT_ID-mongodb-backup
gcs_check=$(gsutil ls gs://$BUCKET/  || echo 1)
if [ $gcs_check = 1 ]
then
gsutil mb gs://$BUCKET/
fi

VELERO_CONST=velero
GSA_NAME=$VELERO_CONST
## check if service account already exists.
flag=$(gcloud iam service-accounts list --filter="email:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" | wc -l | xargs)
if [ $flag = 0 ]
then
  gcloud iam service-accounts create $GSA_NAME \
      --display-name "Velero service account"
fi

# gcloud iam service-accounts list

SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:Velero service account" \
    --format 'value(email)')

# ROLE_PERMISSIONS=(
#     compute.disks.get
#     compute.disks.create
#     compute.disks.createSnapshot
#     compute.snapshots.get
#     compute.snapshots.create
#     compute.snapshots.useReadOnly
#     compute.snapshots.delete
#     compute.zones.get
#     storage.objects.create
#     storage.objects.delete
#     storage.objects.get
#     storage.objects.list
# )
#
# gcloud iam roles create velero.server \
#     --project $PROJECT_ID \
#     --title "Velero Server" \
#     --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

# gcloud projects add-iam-policy-binding $PROJECT_ID \
#     --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
#     --role projects/$PROJECT_ID/roles/velero.server

gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
        --role roles/compute.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
        --role roles/compute.storageAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
        --role roles/storage.objectAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
        --role roles/storage.objectCreator

# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
#         --role roles/storage.legacyBucketOwner

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://$BUCKET

#submit cloud build job
gcloud builds submit --substitutions=\
_PROJECT_ID=${PROJECT_ID},\
_GCP_REGION=${GCP_REGION},\
_CLUSTER_NAME=${CLUSTER_NAME},\
_CLUSTER_DOMAIN=${CLUSTER_DOMAIN},\
_MACHINE_TYPE=${MACHINE_TYPE},\
_CLUSTER_PROFILE=${CLUSTER_PROFILE}

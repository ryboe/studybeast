#!/bin/bash
set -euo pipefail

if [[ -z "$GCP_PROJECT_ID" ]]; then
    echo '$GCP_PROJECT_ID not set'
    echo 'Please rerun with GCP_PROJECT_ID=my-project ./scripts/init_cluster.sh'
    exit 1
fi

gcloud auth configure-docker 2>/dev/null
gcloud config set project "$GCP_PROJECT_ID"
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    containerregistry.googleapis.com \
    iam.googleapis.com \
    oslogin.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com

# Delete all the firewall rules in the default VPC. This is required to delete
# the default VPC.
#   -r strips the quotes from the JSON keys, e.g. "default-allow-icmp" -> default-allow-icmp
#   .[] | {name,network} means "create a list of objects with just the name and network keys"
#   select(.network | contains("foo")) means "if the network contains the foo string"
#   .name means "only output the firewall rule name"
gcloud compute firewall-rules list --format=json |
    jq -r '.[] | {name,network} | select(.network | contains("global/networks/default")) | .name' |
    xargs -I {} gcloud compute firewall-rules delete --quiet {}

# Delete the default VPC
gcloud compute networks delete --quiet default

# TODO: create GCR registry
# TODO: docker build prod API image and push to GCR

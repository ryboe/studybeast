#!/bin/bash
set -euo pipefail

# if the number of arguments isn't 1
if [[ "$#" -ne 1 ]]; then
    echo 'Usage: ./init_cluster.sh <GCP-PROJECT-ID>'
    echo ''
    echo 'Examples:'
    echo '  ./scripts/init_cluster.sh studybeast-dev-ryan-boehning'
    exit 1
fi

GCP_PROJECT_ID="$1"
if [[ "$GCP_PROJECT_ID" == "studybeast-prod" ]] ||
    [[ "$GCP_PROJECT_ID" == "studybeast-staging" ]] ||
    [[ "$GCP_PROJECT_ID" =~ studybeast\-dev\-[a-z-]+ ]]; then
    : # project id is valid
else
    echo "Invalid project id '$GCP_PROJECT_ID'"
    echo 'Project id must match one of these: studybeast-prod, studybeast-staging, studybeast-dev-[a-z-]+'
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
#   || true make the command succeed if the default network has already been deleted (idempotence)
RULES=$(gcloud compute firewall-rules list --format=json | jq -r '.[] | {name,network} | select(.network | endswith("global/networks/default")) | .name')
if [[ -z "$RULES" ]]; then
    xargs -I {} gcloud compute firewall-rules delete --quiet {}
fi

# Delete the default VPC
VPCS=$(gcloud compute network list --format=json | jq -r '.name')
if [[ -z "$VPCS" ]]; then
    gcloud compute networks delete --quiet default
fi

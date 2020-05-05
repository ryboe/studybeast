#!/usr/bin/env bash
set -euo pipefail

# VERIFY DEPENDENCIES ARE INSTALLED
for PROGRAM in docker gcloud terraform; do
	if [[ ! -x "$(command -v $PROGRAM)" ]]; then
		echo "$PROGRAM is not installed"
		echo "Please install $PROGRAM and try again."
		exit 1
	fi
done

# VERIFY DOCKER IS RUNNING
if ! docker info >/dev/null; then
	echo 'The docker daemon is not running.'
	echo 'Please start docker and try again.'
	exit 1
fi

# VERIFY DOCKER IS LOGGED-IN TO GCR
if ! docker login gcr.io; then
	echo 'docker failed to log in to GCR.'
	echo 'Configuring docker...'
	gcloud auth configure-docker # try to configure login

	if ! docker login gcr.io; then # second attempt
		echo 'docker failed to log in to GCR a second time.'
		echo "Please troubleshoot docker failing to log in to gcr.io. Then, rerun the script."
		exit 1
	fi
fi

# VERIFY CURRENT PROJECT ID IS CORRECT
GCP_PROJECT_ID=$(gcloud config get-value project)
echo "redirector image will be built and pushed to $GCP_PROJECT_ID"
read -r -t 600 -p "Is '$GCP_PROJECT_ID' where you want to push this image? [yN]: " REPLY
if [[ ${REPLY,,} != "y" ]] && [[ ${REPLY,,} != "yes" ]]; then # ${VAR,,} lowercases $VAR
	echo 'Goodbye'
	exit 1
fi

# SWITCH TO THE redirector/ DIRECTORY
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$PROJECT_ROOT/redirector"

# BUILD AND PUSH IMAGE
TAG="gcr.io/$GCP_PROJECT_ID/redirector"
docker pull nginx:alpine
DOCKER_BUILDKIT=1 docker build -t "$TAG" .
docker push "$TAG"

#!/usr/bin/env bash

echo "This script needs a rewrite"
exit 1

read -r -t 600 -p "Please enter your name from your company email address (e.g. 'ryan' from 'ryan@studybeast.com'): " NAME
NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]') # lowercase the name

read -r -t 600 -p "Is '$NAME' correct? [yN]: " REPLY

# if reply doesn't start with a 'y' or 'Y'
if [[ ! $REPLY =~ ^[yY] ]]; then
	echo 'Goodbye'
	exit 1
fi

# Write the backend.hcl file to terraform/development/
SCRIPT_DIR="$(
	cd "$(dirname "$0")" >/dev/null 2>&1 || exit 1
	pwd -P
)"
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

cd "$PROJECT_ROOT/terraform/development" || exit 1

cat <<EOF >backend.hcl
organization = "studybeast-org"
workspaces {
  name = "dev-$NAME"
}
EOF

# Initialize terraform.
terraform init --backend-config=backend.hcl

echo ""
echo "You're almost ready to deploy. Please go to this URL:"
echo ""
echo "  https://app.terraform.io/studybeast/workspaces/dev-$NAME/settings"
echo ""
echo "Add this environment variable, which you should get from a TFC admin."
echo ""
echo "  GOOGLE_CREDENTIALS=<minified JSON from terraform service account key>"
echo ""
echo "Then you can create a cluster by running terraform apply from within the"
echo "terraform/development directory."

source init_cluster.sh

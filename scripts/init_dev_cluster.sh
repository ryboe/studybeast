#!/bin/bash

read -r -t 600 -p "Please enter your name from your company email address (e.g. 'ryan' from 'ryan@studybeast.com'): " name
name=$(echo "$name" | tr '[:upper:]' '[:lower:]') # lowercase the name

read -r -t 600 -p "Is '$name' correct? [yN]: " reply

# if reply doesn't start with a 'y' or 'Y'
if [[ ! $reply =~ ^[yY] ]]; then
	echo 'Goodbye'
	exit 1
fi

# Write the backend.hcl file to terraform/development/
cat <<EOF >../terraform/development/backend.hcl
organization = "studybeast"
workspaces {
  name = "dev-$name"
}
EOF

# Initialize terraform.
cd ../terraform/development || exit 1
terraform init --backend-config=backend.hcl

cat <<-EOT
	You're almost ready to deploy. Please go to this URL:

	  https://app.terraform.io/studybeast/workspaces/dev-$name/settings

	Add this environment variable. which you should get from a TFC admin.

	  GOOGLE_CREDENTIALS=<full JSON from terraform service account key>

EOT

echo 'Congrats! Terraform Cloud is now connected to your GCP project.'
echo 'Now you can create a cluster by switching to terraform/development and running'
echo 'terraform apply.'

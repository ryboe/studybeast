# Terraform

## How to set up a dev cluster

1. Get an admin to create a Terraform Cloud workspace and GCP project for you. They should have the same name, which is based on your company email address. For example, if your email is `ryan@studybeast.com`, then your workspace and GCP project will be named `studybeast-dev-ryan`.
Be aware that your GCP project name is permanent and can never be reused. If it becomes deleted for some reason, the name is retired permanently.

2. Once the GCP project has been created, ask the admin for a `terraform` service account key.

3. Run `scripts/init_dev_workspace.sh`. Enter your lowercase name when prompted. Your name should match your company email, e.g. `ryan` from `ryan@studybeast.com`.

4. [Find your workspace here](https://app.terraform.io/studybeast/workspaces). Click on _Settings_. Add an environment variable called `GOOGLE_CREDENTIALS` with a value of the service account key from step 2. Check the _Sensitive_ box, because this is a secret key.

5. Congrats! You are now able to deploy a cluster. Switch to the `terraform/development` directory and run `terraform apply` to deploy your cluster.

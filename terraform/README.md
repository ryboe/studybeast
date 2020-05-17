# Terraform

## How to Set Up a Dev Cluster

1. Get an admin to create a Terraform Cloud workspace and GCP project for you. They should have the same name, which is based on your company email address. For example, if your email is `ryan@studybeast.com`, then your workspace and GCP project will be named `studybeast-dev-ryan`.
Be aware that your GCP project name is permanent and can never be reused. If it becomes deleted for some reason, the name is retired permanently.

2. Once the GCP project has been created, ask the admin for a `terraform` service account key.

3. Run `scripts/init_dev_workspace.sh`. Enter your lowercase name when prompted. Your name should match your company email, e.g. `ryan` from `ryan@studybeast.com`.

4. [Find your workspace here](https://app.terraform.io/studybeast/workspaces). Click on _Settings_. Add an environment variable called `GOOGLE_CREDENTIALS` with a value of the service account key from step 2. Check the _Sensitive_ box, because this is a secret key.

5. Congrats! You are now able to deploy a cluster. Switch to the `terraform/development` directory and run `terraform apply` to deploy your cluster.

## The First Deploy

The first time a cluster is deployed, there are some manual steps to perform to
make it work. I haven't figured out a way to automate these steps (yet).

  1. Change the Google Domains nameservers to point to the ones in the Cloud DNS
managed zone. After `terraform apply` finishes, the NS record on Cloud DNS will
look something like this.

```txt
ns-cloud-d1.googledomains.com
ns-cloud-d2.googledomains.com
ns-cloud-d3.googledomains.com
ns-cloud-d4.googledomains.com
```

We can't predict whether we'll get the `a1` nameserver or the `e1` nameserver.
Go into Google domains, select _Use custome name servers_, and set them to the
values that appear in Cloud DNS.

  2. The initial deploy will create an artifacts.studybeast-prod.appspot.com storage
bucket automatically. This bucket is where the GCR images are stored. Add a
lifecycle rule to this bucket to delete images older than 90 days. This can't be
done through Terraform. This only needs to be done once.

  3. Build and push the `api` image to GCR.

```sh
./scripts/build_and_push_api.sh
```

  4. Use `gcloud` to deploy the `api` image.

```sh
# UNTESTED. DOES THIS WORK?
gcloud run deploy studybeast-api --image=gcr.io/studybeast-prod/api
```

## How to Set Up a GCP rganization

This only needs to be done once.

The organization should have the same name as the company. Within the organization,
folders should be created. A folder is a way to group GCP projects. We should
create one folder per product. In the beginning, there will only be one product,
but we should put it in a folder nonetheless.

To run these `gcloud` commands, the Cloud Resource Manager API must be enabled.

```sh
gcloud services enable cloudresourcemanager.googleapis.com
```

Create a folder with the same name as the company's first product.

```sh
gcloud resource-manager folders create $PRODUCT_NAME --organization $ORGANIZATION_ID
```

The following organization policies should be created. The `gcloud` command for this
is currently in beta.

```sh
# Don't create a default VPC when a new project is created.
gcloud beta resource-manager org-policies enable-enforce constraints/compute.skipDefaultNetworkCreation --organization $ORGANIZATION_ID

# All VM instances should use OS Login to manage their SSH keys.
# Details here: https://cloud.google.com/compute/docs/oslogin
gcloud beta resource-manager org-policies enable-enforce constraints/compute.requireOsLogin --organization $ORGANIZATION_ID
```

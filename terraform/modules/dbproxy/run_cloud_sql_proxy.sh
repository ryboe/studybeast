#!/bin/bash
set -euxo pipefail

# Poll for up to 60s. We need key.json to start cloud_sql_proxy.
# COUNT=0
# while [[ ! -f /key.json ]] && [[ $COUNT -lt 12 ]]; do
#     ((COUNT += 1))
#     sleep 5
# done

# if [[ $COUNT -eq 12 ]]; then
#     echo 'timeout: service account key at /key.json still not created after 60 seconds'
#     echo 'cloud_sql_proxy cannot start without a service account key that grants access to the db'
#     exit 1
# fi

echo "${service_account_key}" >/key.json
chmod 444 key.json

# -p 127.0.0.1:5432:3306    -- cloud_sql_proxy exposes port 3306 on the container, even for Postgres.
#                              We map 3306 in the container to 5432 on the host. '127.0.0.1' means
#                              that you can only connect to host port 5432 over localhost.
# -v /key.json:/key.json:ro -- The file provisioner will copy the service account key file to /key.json
#                              on the host. We will mount it read-only into the container at the
#                              same path.
# -ip_address_types=PRIVATE -- The proxy should only try to connect to the db's private IP.
# -instances=${db_instance_name}=tcp:0.0.0.0:3306 -- The instance name will be something like 'my-project:us-central1:my-db'.
#                                                    The proxy should accept incoming TCP connections on port 3306.
docker pull gcr.io/cloudsql-docker/gce-proxy:latest
docker run --rm -p 127.0.0.1:5432:3306 -v key.json:/key.json:ro gcr.io/cloudsql-docker/gce-proxy:latest /cloud_sql_proxy -credential_file=/key.json -ip_address_types=PRIVATE -instances=${db_instance_name}=tcp:0.0.0.0:3306

FROM gcr.io/cloudsql-docker/gce-proxy
LABEL maintainer="fuck@you.com"
COPY cloud-sql-proxy-service-account-key.json /key.json
CMD [ "/cloud_sql_proxy", "-credential_file=/key.json", "-ip_address_types=PRIVATE", "-instances=studybeast-dev-XXXX:us-central1:main-primary-XXXX=tcp:0.0.0.0:5432"  ]

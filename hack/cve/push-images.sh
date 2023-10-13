#!/usr/bin/env bash

set -e

# This script requires setting `CVE_REPORTER_API_KEY`. It can be retrieved from staging
# cluster by running:
#
#    export CVE_REPORTER_API_KEY=$(kubectl -n dispatch get secrets cve-reporter-d2iq-ci -o json | jq -r '.data."api-key" | @base64d')
#
# The script requires a path to `images.json` file as a first argument.
#
# Optionally project name and version can be overriden with environment variables
#  CVE_REPORTER_PROJECT_NAME=dkp-catalog-applications
#  CVE_REPORTER_PROJECT_VERSION=main
#
# Example:
#  CVE_REPORTER_PROJECT_VERSION=2.1.0-rc.1 ./push-images.sh ./path/to/images.json

: "${CVE_REPORTER_API_KEY:?Provide CVE_REPORTER_API_KEY environment variable}"
IMAGES_JSON_PATH=${1:?Provide path to uploaded images.json file}

: "${CVE_REPORTER_PROJECT_NAME:=dkp-catalog-applications}"
: "${CVE_REPORTER_PROJECT_VERSION:=main}"
: "${CVE_REPORTER_URL:=https://cve-reporter.production.d2iq.cloud}"

curl -v -f -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CVE_REPORTER_API_KEY" \
  -d @"$IMAGES_JSON_PATH" \
  "$CVE_REPORTER_URL/api/v1/import/konvoy/images_json?name=$CVE_REPORTER_PROJECT_NAME&version=$CVE_REPORTER_PROJECT_VERSION&overwrite=true"

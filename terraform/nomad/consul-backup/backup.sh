#!/bin/bash

set -xeuo pipefail

FILE="./consul-$(date +%Y-%m-%d).snap"

consul snapshot save "$FILE"
aws --endpoint-url=https://s3.us-west-004.backblazeb2.com s3 cp "$FILE" "s3://efthymiosh-db-backups/consul/"

#!/bin/bash

set -xeuo pipefail

ARCHIVE="immich-$1.tar.gz"

aws --endpoint-url=https://s3.us-west-004.backblazeb2.com s3 cp "s3://efthymiosh-db-backups/immich/$ARCHIVE" .
tar xvf "$ARCHIVE"
psql -f backup.sql postgres

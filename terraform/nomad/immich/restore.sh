#!/bin/bash

set -xeuo pipefail

ARCHIVE="$1"

aws --endpoint-url=https://s3.us-west-004.backblazeb2.com s3 cp "s3://efthymiosh-db-backups/immich/$ARCHIVE" .
tar xvf "$ARCHIVE"
pg_restore $ARCHIVE/backup.sql

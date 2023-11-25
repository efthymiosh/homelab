#!/bin/bash

set -xeuo pipefail

ARCHIVE="./immich-$(date +%Y-%m-%d).tar.gz"

pg_dumpall > backup.sql
tar czf "$ARCHIVE" backup.sql
aws --endpoint-url=https://s3.us-west-004.backblazeb2.com s3 cp "$ARCHIVE" "s3://efthymiosh-db-backups/immich/"

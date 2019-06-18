#!/bin/bash
set -x

GITHUB_PAT="${GITHUB_PAT}"

export AWS_ACCESS_KEY_ID="${ARTIFACTS_KEY}"
export AWS_SECRET_ACCESS_KEY="${ARTIFACTS_SECRET}"
export AWS_REGION="${ARTIFACTS_REGION}"
S3_BUCKET="${ARTIFACTS_BUCKET}"
S3_ENDPOINT="https://${S3_BUCKET}.s3.amazonaws.com"

# compare with PR base branch's screenshots and add diferences
if [ "${CIRCLE_PULL_REQUEST}" != "false" ]
then
  ls -hl artifacts
  #aws s3 cp artifacts "s3://${S3_BUCKET}/${DIFFERENCE_OBJECT_KEY}"
else
  ls -hl
fi

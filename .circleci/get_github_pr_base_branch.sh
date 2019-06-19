#!/bin/bash

curl -su $GITHUB_USERNAME:$GITHUB_PAT https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${CIRCLE_PR_NUMBER} | \
  jq -r .base.ref

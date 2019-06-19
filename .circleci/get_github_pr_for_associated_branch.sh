#!/bin/bash

curl -su $GITHUB_USERNAME:$GITHUB_PAT \
  https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls | \
  jq --arg CIRCLE_BRANCH ${CIRCLE_BRANCH} '.[] | select(.head.ref=="$CIRCLE_BRANCH" and (.base.ref|test("develop|staging|master")) ) | .number' | \
  head -n1

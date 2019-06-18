#!/usr/bin/env bash
# script borrowed from: https://discuss.circleci.com/t/auto-cancel-redundant-builds-not-working-for-workflow/13852/31

PROJECT_NAME=$CIRCLE_PROJECT_REPONAME
ORG_NAME=$CIRCLE_PROJECT_USERNAME
CIRCLE_TOKEN=$CIRCLE_TOKEN
CIRCLE_BASE_URL="https://circleci.com/api/v1.1/project/github/$ORG_NAME/$PROJECT_NAME"

getRunningJobs() {
  local circleApiResponse
  local runningJobs

  circleApiResponse=$(curl -u ${CIRCLE_TOKEN}: --silent --show-error "$CIRCLE_BASE_URL/tree/$CIRCLE_BRANCH" -H "Accept: application/json")
  runningJobs=$(echo "$circleApiResponse" | jq 'map(if .status == "running" then .build_num else "None" end) - ["None"] | .[]')
  echo "$runningJobs"
}

cancelRunningJobs() {
  local runningJobs
  runningJobs=$(getRunningJobs)
  for buildNum in $runningJobs;
  do
    echo Canceling "$buildNum"
    curl --silent --show-error -X POST "$CIRCLE_BASE_URL/$buildNum/cancel?$QUERY_PARAMS" >/dev/null
  done
}

cancelRunningJobs

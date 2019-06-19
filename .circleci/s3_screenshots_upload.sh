#!/bin/bash
set -x

GITHUB_PAT="${GITHUB_PAT}"
REPO_SLUG="${CIRCLE_PROJECT_REPONAME}"
PR_NUMBER="${CIRCLE_PR_NUMBER}"
CIRCLE_PR_BASE_BRANCH=$(curl -su $GITHUB_USERNAME:$GITHUB_PAT https://circleci.com/api/v1.1/project/github/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/tree/${CIRCLE_BRANCH} | jq -r .base.ref)

export AWS_ACCESS_KEY_ID="${ARTIFACTS_KEY}"
export AWS_SECRET_ACCESS_KEY="${ARTIFACTS_SECRET}"
export AWS_REGION="${ARTIFACTS_REGION}"
S3_BUCKET="${ARTIFACTS_BUCKET}"
S3_ENDPOINT="https://${S3_BUCKET}.s3.amazonaws.com"

test -z $SCREENSHOT_DIFF_THRESHOLD && SCREENSHOT_DIFF_THRESHOLD=0
test -z $SCREENSHOT_DIFF_COLOR && SCREENSHOT_DIFF_COLOR=yellow

# install depends if not present
AWSCLI_BIN=$(which awscli); if [ -z "${AWSCLI_BIN}" ]; then sudo apt-get update -qq; sudo apt-get install -qqy python-pip; sudo pip install awscli; fi
JQ_BIN=$(which jq); if [ -z "${JQ_BIN}" ]; then sudo apt-get update -qq; sudo apt-get install -qqy jq; fi
COMPARE_BIN=$(which compare); if [ -z "${COMPARE_BIN}" ]; then sudo apt-get update -qq; sudo apt-get install -qqy imagemagick; fi
BC_BIN=$(which bc); if [ -z "${BC_BIN}" ]; then sudo apt-get update -qq; sudo apt-get install -qqy bc; fi

# check if there are any screenshots
if [ $(find screenshots -type f | wc -l) -gt 0 ]
then
  if [ ! -z "${PR_NUMBER}" ]
  then
    OBJECT_KEY_BASEPATH="screenshots/${BROWSER}/${PR_NUMBER}-${GIT_SHORT_COMMIT}"
  else
    OBJECT_KEY_BASEPATH="screenshots/${BROWSER}/${CIRCLE_BRANCH}"
  fi
  
  rm -f /tmp/pr-screenshots-urls
  find screenshots -type f | while read file;
  do
    BASENAME=$(echo ${file} | sed "s|^screenshots/||")
    OBJECT_KEY="${OBJECT_KEY_BASEPATH}/${BASENAME}"
    S3_URI="$(echo ${S3_ENDPOINT}/${OBJECT_KEY} | sed 's| |%20|g')"
    aws s3 cp "${file}" "s3://${S3_BUCKET}/${OBJECT_KEY}"
    echo "**- $(echo ${BASENAME} | sed 's|.png||'):**" >> /tmp/pr-screenshots-urls
    echo "![${BASENAME}](${S3_URI})" >> /tmp/pr-screenshots-urls
  done
  aws s3 cp /tmp/pr-screenshots-urls "s3://${S3_BUCKET}/${OBJECT_KEY_BASEPATH}/pr-screenshots-urls"
  
  # compare with PR base branch's screenshots and add diferences
  if [ ! -z "${PR_NUMBER}" ]
  then
  
    rm -f /tmp/pr-differences-urls
    find screenshots -type f | while read file;
    do
      BASENAME=$(echo ${file} | sed "s|^screenshots/||")
      BASE_BRANCH_OBJECT_KEY="screenshots/${BROWSER}/${CIRCLE_PR_BASE_BRANCH}/${BASENAME}"
      BASE_BRANCH_S3_URI="$(echo ${S3_ENDPOINT}/${BASE_BRANCH_OBJECT_KEY} | sed 's| |%20|g')"
      PR_OBJECT_KEY="${OBJECT_KEY_BASEPATH}/${BASENAME}"
      PR_S3_URI="$(echo ${S3_ENDPOINT}/${PR_OBJECT_KEY} | sed 's| |%20|g')"
      DIFFERENCE_OBJECT_KEY="${OBJECT_KEY_BASEPATH}/differences/${BASENAME}"
      # TODO: implement cache (tho it might not make much sense)
      if [ ! -e "${BASE_BRANCH_OBJECT_KEY}" ]
      then
        curl -sLo base-image.png "${BASE_BRANCH_S3_URI}"
        # workaround first deploy where branches images do not exist
        if [ -z "$(file base-image.png | awk -F: '{print $2}' | grep -i png)" ]
        then
          cp -a "${file}" base-image.png
        fi
      fi
      compare -metric RMSE -lowlight-color transparent -highlight-color ${SCREENSHOT_DIFF_COLOR} base-image.png "${file}" difference.png
      DIFF_VALUE=$(compare -metric RMSE -highlight-color ${SCREENSHOT_DIFF_COLOR} base-image.png "${file}" difference.png 2>&1| awk '{print $1}' | sed 's|\.||g')
      if [ $DIFF_VALUE -gt $SCREENSHOT_DIFF_THRESHOLD ]
      then
        DIFFERENCE_S3_URI="$(echo ${S3_ENDPOINT}/${DIFFERENCE_OBJECT_KEY} | sed 's| |%20|g')"
        aws s3 cp "difference.png" "s3://${S3_BUCKET}/${DIFFERENCE_OBJECT_KEY}"
        echo "**- $(echo ${BASENAME} | sed 's|.png||'):**" >> /tmp/pr-differences-urls
        echo "[Base branch (${CIRCLE_PR_BASE_BRANCH}) image](${BASE_BRANCH_S3_URI})" >> /tmp/pr-differences-urls
        echo "[PR (${CIRCLE_BRANCH}/PR${PR_NUMBER}) image](${PR_S3_URI})" >> /tmp/pr-differences-urls
        echo "![${BASENAME}](${DIFFERENCE_S3_URI})" >> /tmp/pr-differences-urls
      fi
    done
    if [ -e /tmp/pr-differences-urls ]
    then
      aws s3 cp /tmp/pr-differences-urls "s3://${S3_BUCKET}/${OBJECT_KEY_BASEPATH}/pr-differences-urls"
    fi
  fi
fi

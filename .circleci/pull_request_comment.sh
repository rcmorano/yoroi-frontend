#!/bin/bash
set -x

GITHUB_PAT="${GITHUB_PAT}"
REPO_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
PR_NUMBER="${CIRCLE_PR_NUMBER}"
PR_BASE_BRANCH="${CIRCLE_PR_BASE_BRANCH}"
BRANCH="${CIRCLE_BRANCH}"

export AWS_ACCESS_KEY_ID="${ARTIFACTS_KEY}"
export AWS_SECRET_ACCESS_KEY="${ARTIFACTS_SECRET}"
export AWS_REGION="${ARTIFACTS_REGION}"
S3_BUCKET="${ARTIFACTS_BUCKET}"
S3_ENDPOINT="https://${S3_BUCKET}.s3.amazonaws.com"

if [ ! -z "${PR_NUMBER}" ]
then
 
  for browser in brave chrome firefox
  do
    # comment header
  cat > /tmp/${browser}-pr-comment.json <<EOF
{ "body": "
EOF
  
    OBJECT_KEY_BASEPATH="screenshots/${browser}/${PR_NUMBER}-${GIT_SHORT_COMMIT}"
  
    set +e; aws s3 cp "s3://${S3_BUCKET}/${OBJECT_KEY_BASEPATH}/pr-screenshots-urls" /tmp/${browser}-pr-screenshots-urls; set -e
    set +e; aws s3 cp "s3://${S3_BUCKET}/${OBJECT_KEY_BASEPATH}/pr-differences-urls" /tmp/${browser}-pr-differences-urls; set -e
    # add differences detail only if we found any
    if [ -e /tmp/${browser}-pr-differences-urls ]
    then
      cat >> /tmp/${browser}-pr-comment.json <<EOF
<details>\n
  <summary>E2E _${browser}_ screenshots differences between 'PR${PR_NUMBER}-${GIT_SHORT_COMMIT}' and base branch '${TRAVIS_BRANCH}'</summary>\n\n
$(cat /tmp/${browser}-pr-differences-urls | while read line; do echo "\\n\\n  $line\\n\\n"; done)\n\n
</details>\n
EOF
    fi
  
    if [ -e /tmp/${browser}-pr-screenshots-urls ]
    then
      cat >> /tmp/${browser}-pr-comment.json <<EOF
<details>\n
  <summary>Complete E2E _${browser}_ screenshots collection for 'PR${PR_NUMBER}-${GIT_SHORT_COMMIT}'</summary>\n\n
$(cat /tmp/${browser}-pr-screenshots-urls | while read line; do echo "\\n\\n  $line\\n\\n"; done)\n\n
</details>\n
EOF
    fi

    # check if there is something to comment
    if [ $(cat /tmp/${browser}-pr-comment.json | wc -l) -gt 2 ]
    then
      cat >> /tmp/${browser}-pr-comment.json <<EOF
"}
EOF
      set +e; aws s3 cp /tmp/${browser}-pr-comment.json "s3://${S3_BUCKET}/${OBJECT_KEY_BASEPATH}/${browser}-pr-comment.json"; set -e
      curl -s -H "Authorization: token ${GITHUB_PAT}" \
        -X POST --data @/tmp/${browser}-pr-comment.json \
        "https://api.github.com/repos/${REPO_SLUG}/issues/${PR_NUMBER}/comments"
    fi


  done

fi

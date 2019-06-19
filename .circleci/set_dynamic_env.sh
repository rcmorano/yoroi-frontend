#!/bin/bash

# HACK: circle does not support composing environment from other env
echo -e "export GIT_SHORT_COMMIT=${CIRCLE_SHA1:0:7}" >> $BASH_ENV
echo -e "export REPO_SLUG=${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}" >> $BASH_ENV
echo -e "export CIRCLE_PR_NUMBER=$(bash .circleci/get_github_pr_for_associated_branch.sh)" >> $BASH_ENV
echo -e "export CIRCLE_PR_BASE_BRANCH=$(bash .circleci/get_github_pr_base_branch.sh)" >> $BASH_ENV

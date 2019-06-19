#!/bin/bash

echo -e "export CIRCLE_PR_NUMBER=$(bash .circleci/get_github_pr_for_associated_branch.sh)" >> $BASH_ENV
echo -e "export CIRCLE_PR_BASE_BRANCH=$(bash .circleci/get_github_pr_base_branch.sh)" >> $BASH_ENV

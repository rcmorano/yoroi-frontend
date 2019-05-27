#!/bin/bash

set -xeo pipefail

if [ ! -e "build/${GIT_SHORT_COMMIT}.built" ]
then
  npm run test-prepare
  mv *crx *xpi artifacts/
  touch build/${GIT_SHORT_COMMIT}.built
fi

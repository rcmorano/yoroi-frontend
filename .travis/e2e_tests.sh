#!/bin/bash

set -xeo pipefail    

npm install # everything is already there but binaries (cucumber-js) are not in context
cp -a artifacts/*crx .
cp -a artifacts/*xpi .
npm run test-e2e-${BROWSER}

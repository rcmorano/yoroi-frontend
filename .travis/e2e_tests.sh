#!/bin/bash

set -xeo pipefail    

cp -a artifacts/*crx .
cp -a artifacts/*xpi .
npm run test-e2e-${BROWSER}

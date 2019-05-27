#!/bin/bash

set -xeo pipefail    

PATH=$PATH:$(npm bin)

cp -a artifacts/*crx .
cp -a artifacts/*xpi .
npm run test-e2e-${BROWSER}

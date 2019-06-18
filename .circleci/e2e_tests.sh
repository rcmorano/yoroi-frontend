#!/bin/bash

set -xeo pipefail

cp -a artifacts/*crx .
cp -a artifacts/*xpi .
npm run test-e2e-${BROWSER}
mv screenshots screenshots-${BROWSER}
mkdir screenshots
mv screenshots-${BROWSER} screenshots/${BROWSER}

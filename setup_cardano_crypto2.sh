#! /bin/bash

git submodule update --init --recursive && \
cd js-cardano-wasm2 && \
git checkout wasm-pack-version && \
git submodule update && \
npm install && \
../js-cardano-wasm-build2 && \
npm link && \
cd .. && \
npm link rust-cardano-crypto

#! /bin/bash

git submodule update --init --recursive && \
cd js-cardano-wasm && \
git checkout wasm-pack-version && \
git submodule update && \
npm install && \
../js-cardano-wasm-build && \
npm link && \
cd .. && \
npm link rust-cardano-crypto

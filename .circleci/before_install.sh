#!/bin/bash

set -xeo pipefail

curl https://sh.rustup.rs -sSf | sh -s -- -y
echo 'export PATH=$HOME/.cargo/bin/:$PATH' >> ${BASH_ENV}
source $BASH_ENV
rustup install ${RUST_VERSION}
rustup target add ${RUST_TARGETS} --toolchain ${RUST_VERSION}

sudo apt-get install -qq -y python-pip && sudo pip install awscli

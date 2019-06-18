#!/bin/bash

set -xeo pipefail

# Because npm link will write in this path
sudo chown -R "$(whoami):$(whoami)" /usr/local/lib/node_modules

if [ -z "$(which cargo)" ]
then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  echo 'export PATH=$HOME/.cargo/bin/:$PATH' >> ${BASH_ENV}
fi

source $BASH_ENV

if [ -z "$(ls ~/.rustup/toolchains | grep ^${RUST_VERSION}-)" ]
then
  rustup install ${RUST_VERSION}
fi

for rust_target in ${RUST_TARGETS}
do
  if [ ! -e ~/.rustup/toolchains/${RUST_VERSION}*/lib/rustlib/manifest-rust-std-${rust_target} ]
  then
    rustup target add ${RUST_TARGETS} --toolchain ${RUST_VERSION}
  fi
done

sudo apt-get install -qq -y python-pip && sudo pip install awscli

#!/bin/bash

set -xeo pipefail

/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- ${DISPLAY} -ac -screen 0 ${SCREEN_RESOLUTION}
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

if [ ! -e "$HOME/.cargo/bin" ]
then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  sudo ln -fs $HOME/.cargo/bin/* /usr/local/bin/
  source $HOME/.cargo/env
  rustup install ${RUST_VERSION}
  rustup target add ${RUST_TARGETS} --toolchain ${RUST_VERSION}
fi
sudo ln -fs $HOME/.cargo/bin/* /usr/local/bin/

# base build environment
ARG NODE_VERSION=10
ENV NODE_VERSION ${NODE_VERSION}
FROM node:${NODE_VERSION} AS rust-env-setup
ARG RUST_VERSION=1.32.0
ENV RUST_VERSION ${RUST_VERSION}

COPY ./docker-assets/bin/rust-setup.functions /src/docker-assets/bin/rust-setup.functions
RUN /bin/bash -c 'source docker-assets/bin/rust-setup.functions && \
    rust-setup'

# yoroi artifacts output image
ARG DOCKER_IMAGE_BUILD_ENV=rust-env-setup
ENV DOCKER_IMAGE_BUILD_ENV ${DOCKER_IMAGE_BUILD_ENV}
FROM ${DOCKER_IMAGE_BUILD_ENV} AS yoroi-build
ARG CARDANO_NETWORK=mainnet
ENV CARDANO_NETWORK ${CARDANO_NETWORK}
ARG DOCKER_IMAGE_SOURCE=emurgornd/yoroi-src:latest
ENV DOCKER_IMAGE_SOURCE ${DOCKER_IMAGE_SOURCE}
ARG APP_ID=APP_ID
ENV APP_ID ${APP_ID}
ARG CODEBASE=https://www.sample.com/dw/yoroi-extension.crx
ENV CODEBASE ${CODEBASE}

COPY --from=${DOCKER_IMAGE_SOURCE} /src /src

COPY ./docker-assets/bin/yoroi-setup.functions /src/docker-assets/bin/yoroi-setup.functions
RUN /bin/bash -c 'source docker-assets/bin/yoroi-setup.functions && \
    yoroi-depends-install'

RUN /bin/bash -c 'source docker-assets/bin/yoroi-setup.functions && \
    yoroi-build'

# development environment for the build
ARG DOCKER_IMAGE_BUILD=yoroi-build
ENV DOCKER_IMAGE_BUILD ${DOCKER_IMAGE_BUILD}
FROM ${DOCKER_IMAGE_BUILD} AS dev-env
COPY --from=yoroi-build /src /src
COPY ./docker-assets/bin/entrypoint* /src/docker-assets/bin/
RUN /bin/bash -c 'source docker-assets/bin/entrypoint.functions && \
    setup-sudoers && \
    sudo chmod +x /src/docker-assets/bin/entrypoint'
ENTRYPOINT ["/src/docker-assets/bin/entrypoint"]

# yoroi run on an isolated chrome image
FROM ubuntu:18.04 AS yoroi-standalone-chrome-mainnet
COPY --from=yoroi-build /src/build /yoroi
ARG DATE=20190327
RUN apt update -qq && \
    apt install -y sudo curl rsync && \
    curl -o /var/cache/apt/archives/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y /var/cache/apt/archives/chrome.deb && \
    apt clean 
COPY ./docker-assets/bin/entrypoint* /src/docker-assets/bin/
ENTRYPOINT ["/src/docker-assets/bin/entrypoint", "run-chrome"]

# Bosh & Concourse CLI and tools container
#
# Related links:
# * https://bosh.io/docs/cli-v2-install/
# * https://github.com/cloudfoundry/bosh-cli/releases

FROM ubuntu:latest

ARG BOSH_URL=https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
ARG CREDHUB_URL=https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.3.0/credhub-linux-2.3.0.tgz
ARG BBL_URL=https://github.com/cloudfoundry/bosh-bootloader/releases/download/v7.4.0/bbl-v7.4.0_linux_x86-64
ARG FLY_URL=https://github.com/concourse/concourse/releases/download/v5.1.0/fly-5.1.0-linux-amd64.tgz

RUN apt-get update

# Install bosh requirements
RUN apt-get install -y \
    build-essential \
    zlibc \
    zlib1g-dev \
    ruby \
    ruby-dev \
    openssl \
    libxslt-dev \
    libxml2-dev \
    libssl-dev \
    libreadline7 \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3

# APT Install some more tooling
RUN apt-get install -y \
    git \
    netcat-openbsd \
    openssh-client \
    sudo \
    unzip \
    wget

# Installing a couple of CLIs
RUN wget -q -O /usr/local/bin/bosh ${BOSH_URL} \
    && chmod +x /usr/local/bin/bosh

RUN tmpfile=$(tempfile) \
    && wget -q -O ${tmpfile} ${TERRAFORM_URL} \
    && unzip ${tmpfile} -d /usr/local/bin/ \
    && rm ${tmpfile}

RUN tmpfile=$(tempfile) \
    && wget -q -O ${tmpfile} ${CREDHUB_URL} \
    && tar xf ${tmpfile} -C /usr/local/bin/ \
    && rm ${tmpfile}

RUN wget -q -O /usr/local/bin/bbl ${BBL_URL} \
    && chmod +x /usr/local/bin/bbl

RUN tmpfile=$(tempfile) \
    && wget -q -O ${tmpfile} ${FLY_URL} \
    && tar xf ${tmpfile} -C /usr/local/bin/ \
    && rm ${tmpfile}

COPY bnc.sh /usr/local/bin/bnc.sh

RUN mkdir /work
WORKDIR /work

# Create a local user with uid:gid 1000:1000
RUN groupadd -g 1000 -o user
RUN useradd -m -u 1000 -g 1000 -s /bin/bash user
USER user

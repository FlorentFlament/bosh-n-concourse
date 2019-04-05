#!/usr/bin/env bash
set -e

ENVFILE=./envrc
CONCOURSE_CONFIG=vars/concourse-vars-file.yml

# Checking for prerequisites
if [ ! -f ${ENVFILE} ]; then
    echo "File ${ENVFILE} could not be found."
    exit 1
fi
if [ ! -f ${CONCOURSE_CONFIG} ]; then
    echo "File ${CONCOURSE_CONFIG} could not be found."
    exit 2
fi
if ! which bbl; then
    echo "bbl executable could not be found in PATH."
    exit 3
fi


# The following environment variables are requried for bbl to deploy a
# bosh director. They should be exported in the envrc file.
# Example:
# export BBL_IAAS=gcp
# export BBL_GCP_REGION=europe-west1
# export BBL_GCP_SERVICE_ACCOUNT_KEY=<path-to-gcp-service-account-key>
# See:
# * https://github.com/cloudfoundry/bosh-bootloader
# * https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-gcp.md
source ${ENVFILE}

# Deploying bosh director using bbl.
# Also preparing to deploy concourse.
# See: https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/concourse.md
bbl plan --lb-type concourse
bbl up

# Configuring bosh CLI (setting up bosh environment variables)
eval "$(bbl print-env)"


# Deploying concourse
STEMCELL_URL="https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-xenial-go_agent"
DEP_URL="https://github.com/concourse/concourse-bosh-deployment.git"
DEP_DIR="./concourse-bosh-deployment"
OPS_DIR=${DEP_DIR}/cluster/operations
EXT_HOST=$(bbl outputs | grep concourse_lb_ip | cut -d ' ' -f2)

bosh upload-stemcell ${STEMCELL_URL}

if [ ! -d ${DEP_DIR} ]; then
    git clone ${DEP_URL}
fi
bosh deploy -n -d concourse ${DEP_DIR}/cluster/concourse.yml \
    -o ${OPS_DIR}/basic-auth.yml \
    -o ${OPS_DIR}/privileged-http.yml \
    -o ${OPS_DIR}/privileged-https.yml \
    -o ${OPS_DIR}/tls.yml \
    -o ${OPS_DIR}/tls-vars.yml \
    -o ${OPS_DIR}/web-network-extension.yml \
    -o ${OPS_DIR}/scale.yml \
    -o ${OPS_DIR}/worker-ephemeral-disk.yml \
    -l ${DEP_DIR}/versions.yml \
    -l ${CONCOURSE_CONFIG} \
    -v external_host=${EXT_HOST} \
    -v external_url=https://${EXT_HOST}

echo "Concourse URL: https://${EXT_HOST}"

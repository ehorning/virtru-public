#!/usr/bin/env bash
# This script runs a Google-style verification on the chart, using mpdev
# pwd should be /your/path/to/virtru-public
# Reference: https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/verification-integration.md#troubleshooting-verification-errors

# Prerequisite: install Application CRD
# kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"

set -eu

cd chart/gateway
helm dependency update
cd -

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VERSION="$(< "${SCRIPT_DIR}/VERSION" )"

export TAG="${VERSION}";
export DEPLOYER_VERSION="$(echo "${VERSION}" | cut -d'.' -f 1-2)";

if [[ "${ENVIRONMENT:-}" = 'production' ]]; then
  export REGISTRY=gcr.io/virtru-public/gateway;
  printf 'Deploying to production. Using registry [%s]\n' $REGISTRY
else
  export REGISTRY=gcr.io/virtru-public/staging/gateway;
  printf 'Deploying to staging. Using registry [%s]\n' $REGISTRY
fi

printf 'Using container tag = [%s] and deployer version = [%s]\n' $TAG $DEPLOYER_VERSION

# reportingSecret:
# To actually report to the real Google ServiceControlEndpoint use "gateway-reportingsecret"
# To make sure not to bill, use "gs://cloud-marketplace-tools/reporting_secrets/fake_reporting_secret.yaml"}'

docker build --no-cache --build-arg TAG="${TAG}" --build-arg REGISTRY="${REGISTRY}" \
  -t "${REGISTRY}/deployer:${DEPLOYER_VERSION}" -f dev.Dockerfile "${SCRIPT_DIR}" 

docker push "${REGISTRY}/deployer:${DEPLOYER_VERSION}"

# mpdev install to install, mpdev verify to test
# TODO: figure out how to get the parameter values into the app
mpdev verify --deployer="${REGISTRY}/deployer:${DEPLOYER_VERSION}"

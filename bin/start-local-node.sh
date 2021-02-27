#!/bin/bash

set -ea

cmd_usage="Start local node

Usage: start-local-node.sh <path-to-package.json> [options]
  <path-to-package.json> must be an absolute path including file name

  Options:
  --override-major-version    - major version to use
  --override-minor-version    - minor version to use
  --dapi-branch               - dapi branch to be injected into mn-bootstrap
  --drive-branch              - drive branch to be injected into mn-bootstrap
  --sdk-branch                - Dash SDK (DashJS) branch to be injected into mn-bootstrap
"

PACKAGE_JSON_PATH="$1"

if [ -z "$PACKAGE_JSON_PATH" ]
then
  echo "Path to package.json is not specified"
  echo ""
  echo "$cmd_usage"
  exit 1
fi

for i in "$@"
do
case ${i} in
    -h|--help)
        echo "$cmd_usage"
        exit 0
    ;;
    --override-major-version=*)
    major_version="${i#*=}"
    ;;
    --override-minor-version=*)
    minor_version="${i#*=}"
    ;;
    --dapi-branch=*)
    dapi_branch="${i#*=}"
    ;;
    --drive-branch=*)
    drive_branch="${i#*=}"
    ;;
    --sdk-branch=*)
    sdk_branch="${i#*=}"
    ;;
esac
done

# Setup node for local node mn-bootstrap
echo "Setting up a local node"

mn config:default local
mn config:set core.miner.enable true
mn config:set core.miner.interval 1s
mn config:set environment development
mn config:set platform.drive.abci.log.stdout.level trace


echo "Starting local init"
OUTPUT=$(mn setup local "$mn_bootstrap_dapi_options" "$mn_bootstrap_drive_options")

FAUCET_PRIVATE_KEY=$(echo "$OUTPUT" | grep -m 1 "Private key:" | awk '{printf $4}')
DPNS_CONTRACT_ID=$(mn config:get platform.dpns.contract.id)
DPNS_CONTRACT_BLOCK_HEIGHT=$(mn config:get platform.dpns.contract.blockHeight)
DPNS_TOP_LEVEL_IDENTITY_ID=$(mn config:get platform.dpns.ownerId)
DPNS_TOP_LEVEL_IDENTITY_PRIVATE_KEY=$(echo "$OUTPUT" | grep -m 1 "HD private key:" | awk '{$1=""; printf $5}')

echo "Node is configured:"

echo "FAUCET_PRIVATE_KEY: ${FAUCET_PRIVATE_KEY}"
echo "DPNS_CONTRACT_ID: ${DPNS_CONTRACT_ID}"
echo "DPNS_CONTRACT_BLOCK_HEIGHT: ${DPNS_CONTRACT_BLOCK_HEIGHT}"
echo "DPNS_TOP_LEVEL_IDENTITY_ID: ${DPNS_TOP_LEVEL_IDENTITY_ID}"
echo "DPNS_TOP_LEVEL_IDENTITY_PRIVATE_KEY: ${DPNS_TOP_LEVEL_IDENTITY_PRIVATE_KEY}"


#Start mn-bootstrap
echo "Starting mn-bootstrap"
mn start

#Export variables
export CURRENT_VERSION
export FAUCET_PRIVATE_KEY
export DPNS_TOP_LEVEL_IDENTITY_PRIVATE_KEY
export DPNS_TOP_LEVEL_IDENTITY_ID
export DPNS_CONTRACT_ID
export DPNS_CONTRACT_BLOCK_HEIGHT

echo "Success"

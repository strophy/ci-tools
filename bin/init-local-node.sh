#!/bin/bash

set -ea

cmd_usage="Init local node

Usage: init-local-node.sh <path-to-package.json> [options]
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

# Define variables

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CURRENT_VERSION=$("$DIR"/get-release-version "$PACKAGE_JSON_PATH" "$major_version")
MN_RELEASE_LINK=$("$DIR"/get-github-release-link "$PACKAGE_JSON_PATH" dashevo/mn-bootstrap "$major_version" "$minor_version")

echo "Current version: ${CURRENT_VERSION}";

# Create temp dir
TMP="$DIR"/../tmp
rm -rf "$TMP"
mkdir "$TMP"

# Download dapi from defined branch
mn_bootstrap_dapi_options="--dapi-image-build-path="
if [ -n "$dapi_branch" ]
then
  echo "Cloning DAPI from branch $dapi_branch"
  cd "$TMP"
  git clone https://github.com/dashevo/dapi.git
  cd "$TMP"/dapi
  git checkout "$dapi_branch"
  mn_bootstrap_dapi_options="--dapi-image-build-path=$TMP/dapi"
fi

# Download drive from defined branch
mn_bootstrap_drive_options="--drive-image-build-path="
if [ -n "$drive_branch" ]
then
  echo "Cloning Drive from branch $dapi_branch"
  cd "$TMP"
  git clone https://github.com/dashevo/drive.git
  cd "$TMP"/drive
  git checkout "$drive_branch"
  mn_bootstrap_drive_options="--drive-image-build-path=$TMP/drive"
fi

# Download and install mn-bootstrap
echo "Installing mn-bootstrap"
curl -L "$MN_RELEASE_LINK" > "$TMP"/mn-bootstrap.tar.gz
mkdir "$TMP"/mn-bootstrap && tar -C "$TMP"/mn-bootstrap -xvf "$TMP"/mn-bootstrap.tar.gz
MN_RELEASE_DIR="$(ls "$TMP"/mn-bootstrap)"
cd "$TMP"/mn-bootstrap/"$MN_RELEASE_DIR"

npm ci

if [ -n "$sdk_branch" ]
then
  echo "Installing Dash SDK from branch $sdk_branch"
  npm i "github:dashevo/DashJS#$sdk_branch"
fi

npm link

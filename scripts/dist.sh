#!/usr/bin/env bash

VERSION=$1
# Get the version from the environment, or try to figure it out.
if [ -z "$VERSION" ]; then
	VERSION=$(awk -F\" '/version =/ { print $2; exit }' < version/version.go)
fi
if [ -z "$VERSION" ];then
  echo "Please specify a version."
  exit 1
fi

VERSION="v$VERSION"
project_path=$(pwd)
project_name="${project_path##*/}"
echo "==> Building $project_name $VERSION..."

DOWNLOAD_DIR=build/download/
BCBCHAINDIR="bcbchain"
TENDERMINTDIR="tendermint"

mkdir -p "$DOWNLOAD_DIR"

pushd "$DOWNLOAD_DIR" || exit 1 >/dev/null 2>&1

echo "===> Downloading bcbchain..."
if [ -d "$BCBCHAINDIR" ];then
  pushd "$BCBCHAINDIR" || exit 1 >/dev/null 2>&1
  git reset --hard origin/master
  popd >/dev/null || exit 1 >/dev/null 2>&1
else
  git clone https://github.com/bcbchain/bcbchain.git
fi

echo "==> Downloading tendermint..."
if [ -d "$TENDERMINTDIR" ];then
  pushd "$TENDERMINTDIR" || exit 1 >/dev/null 2>&1
  git reset --hard origin/master
  popd >/dev/null || exit 1 >/dev/null 2>&1
else
  git clone https://github.com/bcbchain/tendermint.git
fi

echo "==> Packing bcchain..."
pushd "$BCBCHAINDIR" || exit 1 >/dev/null 2>&1
make dist
popd >/dev/null || exit 1 >/dev/null 2>&1

echo "==> Packing tendermint..."
pushd "$TENDERMINTDIR" || exit 1 >/dev/null 2>&1
make dist
popd >/dev/null || exit 1 >/dev/null 2>&1

popd >/dev/null || exit 1 >/dev/null 2>&1   # popd from build/download direction

rm -rf ./build/pkg
mkdir -p ./build/pkg
for OS_TYPE in linux_amd64 darwin_amd64 windows_amd64;do
  mkdir ./build/pkg/"$OS_TYPE"

  cp ./build/download/bcbchain/build/dist/bcbchain*"$OS_TYPE"*.tar.gz ./build/pkg/"$OS_TYPE"
  cp ./build/download/tendermint/build/dist/tendermint*"$OS_TYPE"*.tar.gz ./build/pkg/"$OS_TYPE"

  mkdir ./build/pkg/"$OS_TYPE"/bcbchain
  mkdir ./build/pkg/"$OS_TYPE"/tendermint

  tar xf ./build/pkg/"$OS_TYPE"/tendermint*.tar.gz -C  ./build/pkg/"$OS_TYPE"/tendermint
  tar xf ./build/pkg/"$OS_TYPE"/bcbchain*.tar.gz -C  ./build/pkg/"$OS_TYPE"/bcbchain

  rm -rf ./build/pkg/"$OS_TYPE"/*.tar.gz
  cp ./setup/setup.sh ./build/pkg/"$OS_TYPE"/

  pushd ./build/pkg/"$OS_TYPE" >/dev/null 2>&1
  tar zcf ../bcb-node-"$VERSION"_"$OS_TYPE".tar.gz ./*
  popd >/dev/null 2>&1
done

rm -rf ./build/dist
mkdir -p ./build/dist
for FILENAME in $(find ./build/pkg -mindepth 1 -maxdepth 1 -type f); do
  FILENAME=$(basename "$FILENAME")
	cp "./build/pkg/${FILENAME}" "./build/dist/${FILENAME}"
done

pushd ./build/dist >/dev/null 2>&1
shasum -a256 ./* > "./bcb-node_${VERSION}_SHA256SUMS"
popd >/dev/null 2>&1

echo ""
echo "==> PACK bcbchain-node success:"

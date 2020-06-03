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
  git pull
  popd >/dev/null || exit 1 >/dev/null 2>&1
else
  git clone https://github.com/bcbchain/bcbchain.git
fi

echo "==> Downloading tendermint..."
if [ -d "$TENDERMINTDIR" ];then
  pushd "$TENDERMINTDIR" || exit 1 >/dev/null 2>&1
  git pull
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

cd ..
rm -rf dist
mkdir -p dist
cp download/bcbchain/build/dist/bcbchain*linux*.tar.gz dist/
cp download/tendermint/build/dist/tendermint*linux*.tar.gz dist/

cd dist || exit 1
mkdir bcbchain
mkdir tendermint

tar xf tendermint*.tar.gz -C  tendermint/
tar xf bcbchain*.tar.gz -C  bcbchain/
rm -rf ./*.tar.gz
cp ../../setup/setup.sh .

tar zcf bcb-node-$VERSION.tar.gz ./*

rm -rf tendermint bcbchain setup.sh

echo ""
echo "==> PACK bcbchain-node success:"
ls -lh
popd >/dev/null || exit 1 >/dev/null 2>&1

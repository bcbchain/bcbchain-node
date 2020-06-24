#!/usr/bin/env bash

platform=`uname`
OS_TYPE=''
if [ $platform = 'Darwin' ]; then
  OS_TYPE="darwin_amd64"
elif [ $platform = 'Linux' ]; then
  OS_TYPE="linux_amd64"
else
  echo "cannot support windows system"
  exit 1
fi

rm -rf ./local
mkdir -p ./local
tar zxf ./build/dist/*"$OS_TYPE".tar.gz -C ./local

# clear
rm -rf ~/.build
rm -rf ~/tmcore
rm -rf ~/log
rm -rf ~/.appstate.*
sudo rm -rf /etc/bcchain
sudo rm -rf /etc/tmcore

mkdir -p ~/.build/thirdparty/src
tar zxf ./local/bcbchain*/pieces/thirdparty*.tar.gz -C ~/.build/thirdparty/
mkdir -p ~/.build/sdk/
tar zxf ./local/bcbchain*/pieces/sdk*.tar.gz -C ~/.build/sdk/
mkdir -p ~/.build/smcrunsvc_v1.0_3dcontract/bin
cp -r ./local/bcbchain*/pieces/smcrunsvc ~/.build/smcrunsvc_v1.0_3dcontract/bin/
pushd ./local/tendermint*/pieces >/dev/null
mkdir -p ./v2/local
cp -rf ./local/v2/* ./v2/local/
popd >/dev/null

sudo mkdir /etc/bcchain
sudo cp -r ./local/bcbchain*/pieces/local/.config/* /etc/bcchain/
if [ $platform = 'Darwin' ]; then
  sudo sed -i  "" 's#false#true#g' /etc/bcchain/bcchain.yaml
else
  sudo sed -i 's#false#true#g' /etc/bcchain/bcchain.yaml
fi

function installGenesisValidator() {
  echo "===>start bcchain..."
  pushd ./local/bcbchain*/pieces >/dev/null
  ./bcchain start &
  popd >/dev/null

  echo "===>start tendermint..."
  pushd ./local/tendermint*/pieces >/dev/null
  ./tendermint init --genesis_path v2 --chain_id local
  ./tendermint node
  popd >/dev/null
}

function installFollower() {
  echo "===>start bcchain..."
  pushd ./local/bcbchain*/pieces >/dev/null
  ./bcchain start &
  popd >/dev/null

  sleep 5
  echo "===>start tendermint..."
  pushd ./local/tendermint*/pieces >/dev/null
  echo "Please input the which node or FOLLOWER's name[:port] you want to follow"
  echo "Multi nodes can be separated by comma \",\""
  echo "for example \"earth.bcbchain.io,mar.bcbchain.io:46657\" or \"venus.bcbchain.io\""
  read -p "nodes or FOLLOWERs to follow: " officials
  echo ""
  echo "You selected \"${officials}\" to follow"
  echo ""

  echo "Initializing all genesis node..."
  ./tendermint init --follow ${officials}
  ./tendermint node
  popd >/dev/null
}

echo ""
echo "Select HOW to install tmcore service"
choices=("")
choices[0]="GENESIS VALIDATOR"
choices[1]="FOLLOWER"

select nodeType in "${choices[@]}"; do
    case ${nodeType} in
    "GENESIS VALIDATOR")
        echo "You selected GENESIS VALIDATOR node"
        echo ""
        installGenesisValidator
        ;;
    "FOLLOWER")
        echo "You selected FOLLOWER"
        echo ""
        installFollower
        ;;
    *) echo "Invalid choice.";;
    esac
done

echo "===> Finished"

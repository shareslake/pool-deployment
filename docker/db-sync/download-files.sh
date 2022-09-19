#!/bin/bash 

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

mkdir -p /opt/shareslake/{bin,lib,shelley/genesis,byron/genesis,configuration,node-ipc,logs,node-db,db-sync/ledger-state}

wget --no-check-certificate -O /opt/shareslake/shelley/genesis/genesis.json https://github.com/shareslake/pool-deployment/raw/main/config/shelley-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/shelley/genesis/genesis.alonzo.json https://raw.githubusercontent.com/shareslake/pool-deployment/main/config/alonzo-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/byron/genesis/genesis.json https://github.com/shareslake/pool-deployment/raw/main/config/byron-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/configuration/configuration-mainnet.yaml https://github.com/shareslake/pool-deployment/raw/main/config/configuration-mainnet.yaml && \

chmod -R g+rwX /opt/shareslake/{node-ipc,node-db,logs,db-sync}

ln -s /opt/shareslake/node-ipc /node-ipc
ln -s /opt/shareslake/node-db /node-db

git clone https://github.com/shareslake/shareslake-db-sync.git /tmp/shareslake-db-sync
(
  cd /tmp/shareslake-db-sync
  BRANCH=shareslake-db-sync-13.0.4
  git fetch origin "$BRANCH"
  git checkout origin/"$BRANCH"
  cp -R ./schema /opt/shareslake/db-sync/
)




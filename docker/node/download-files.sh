#!/bin/bash 

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

mkdir -p /opt/shareslake/{bin,lib,shelley/genesis,byron/genesis,configuration,node-ipc,logs,node-db}

wget --no-check-certificate -O /opt/shareslake/bin/shareslake-node https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.3/shareslake-node && \
wget --no-check-certificate -O /opt/shareslake/bin/shareslake-cli https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.3/shareslake-cli && \
chmod +x /opt/shareslake/bin/{shareslake-node,shareslake-cli} && \
wget --no-check-certificate -O /opt/shareslake/shelley/genesis/genesis.json https://github.com/shareslake/pool-deployment/raw/main/config/shelley-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/shelley/genesis/genesis.alonzo.json https://raw.githubusercontent.com/shareslake/pool-deployment/main/config/alonzo-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/byron/genesis/genesis.json https://github.com/shareslake/pool-deployment/raw/main/config/byron-genesis.json && \
wget --no-check-certificate -O /opt/shareslake/configuration/configuration-mainnet.yaml https://github.com/shareslake/pool-deployment/raw/main/config/configuration-mainnet.yaml && \
wget --no-check-certificate -O /opt/shareslake/lib/libsodium.so.23 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/libsodium.so.23 && \
wget --no-check-certificate -O /opt/shareslake/lib/libsecp256k1.so.0 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.3/libsecp256k1.so.0

cat > /opt/shareslake/configuration/topology.json <<EOF
{
  "Producers": [
    {
      "addr": "relays.shareslake.network",
      "port": 3001,
      "valency": 1
    }
  ]
}
EOF

chmod g+rwX /opt/shareslake/{node-ipc,node-db,logs}

#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

NODE_TYPE="${1:?Missing node type. Pass either 'relay' or 'block' to configure the relay/block producing nodes}"

mkdir -p /opt/shareslake/byron/genesis \
         /opt/shareslake/shelley/genesis \
         /opt/shareslake/configuration

cp ./config/byron-genesis.json /opt/shareslake/byron/genesis/genesis.json
cp ./config/shelley-genesis.json /opt/shareslake/shelley/genesis/genesis.json
cp ./config/byron-genesis.json /opt/shareslake/shelley/genesis/genesis.alonzo.json
cp ./config/configuration-mainnet.yaml /opt/shareslake/configuration/
if [[ "$NODE_TYPE" == "relay" ]]; then
    cp ./config/relay-topology.json /opt/shareslake/configuration/topology.json
    cp ./config/run-relay.sh /opt/shareslake/bin/run.sh
elif [[ "$NODE_TYPE" == "block" ]]; then
    cp ./config/block-prod-topology.json /opt/shareslake/configuration/topology.json
    cp ./config/run-block-producing.sh /opt/shareslake/bin/run.sh
else
    echo "Unknown node type, please use 'relay' or 'block'"
    exit 1
fi

chown -R shareslake /opt/shareslake

cp ./config/node.service /etc/systemd/system/shareslake-node.service

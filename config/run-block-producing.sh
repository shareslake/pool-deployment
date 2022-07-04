#!/bin/bash

LD_LIBRARY_PATH="/opt/shareslake/lib:${LD_LIBRARY_PATH:-}" /opt/shareslake/bin/shareslake-node run \
  --config /opt/shareslake/configuration/configuration-mainnet.yaml \
  --topology /opt/shareslake/configuration/topology.json \
  --database-path /opt/shareslake/node-db \
  --socket-path /opt/shareslake/node-ipc/node.sock \
  --shelley-kes-key /home/shareslake/.shelley/kes.skey \
  --shelley-vrf-key /home/shareslake/.shelley/vrf.skey \
  --shelley-operational-certificate /home/shareslake/.shelley/node.cert \
  --port 3001

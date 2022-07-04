#!/bin/bash

LD_LIBRARY_PATH="/opt/shareslake/lib:${LD_LIBRARY_PATH:-}" /opt/shareslake/bin/shareslake-node run \
  --config /opt/shareslake/configuration/configuration-mainnet.yaml \
  --topology /opt/shareslake/configuration/topology.json \
  --database-path /opt/shareslake/node-db \
  --socket-path /opt/shareslake/node-ipc/node.sock \
  --port 3001

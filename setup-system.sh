#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Create Shareslake non-root user
useradd -m shareslake -u 1001
chsh -s /bin/bash shareslake

# Install tools
apt-get update && apt-get install -y git vim jq
wget https://github.com/mikefarah/yq/releases/download/v4.21.1/yq_linux_amd64.tar.gz -O - | tar xz && mv yq_linux_amd64 /usr/bin/yq

# Create folder structure
mkdir -p /opt/shareslake/bin /opt/shareslake/lib /opt/shareslake/node-db \
         /opt/shareslake/node-ipc /opt/shareslake/logs
chown -R shareslake /opt/shareslake

# Configure auto updates for the system packages
apt-get update -y && apt-get upgrade -y
apt-get autoremove && apt-get autoclean && apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo "export PATH=${PATH}:/home/shareslake/bin" >> /home/shareslake/.bashrc
echo "export LD_LIBRARY_PATH=/opt/shareslake/lib:${LD_LIBRARY_PATH:-}" >> /home/shareslake/.bashrc
echo "export CARDANO_NODE_SOCKET_PATH=/opt/shareslake/node-ipc/node.sock" >> /home/shareslake/.bashrc

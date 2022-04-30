# Deploying a Shareslake stake pool

Shareslake is a Cardano based network. Before deploying a stake pool into the Shareslake mainnet, we recommend to be familiar with deploying a stake pool in Cardano testnet, as the process will be the same. You can learn how to do it [here](https://developers.cardano.org/docs/stake-pool-course/).

## Requirements

- 8GB RAM
- 20GB disk space
- 2 CPUs 1.6GHz or higher.
- Stable internet connection

## Overview

A stake pool is composed of two different nodes, a relay node that will be exposed to the internet and a block-producing node that will remain hidden.

It is strongly recommended to preserve the keys in an off-line machine, also called air-gapped machine. This can be an old computer in which you can sing the transactions and then move them using, for example, a pen-drive to the online computer to submit it.
There are some keys that are required to remain in the running nodes and need to be changed from time to time.

## Standalone node deployment

These steps have to be followed twice, once for your relay and once for your block-producing node.
The relay does not contain any keys, while the block-producing does. In the case of the block-producing node, you also need to follow the section to generate the keys.

> All the step must be executed from the root directory of this repository.

### Setting up the system

Run the `setup-system.sh` script from this repository as `root`. It will:

1. Configure the `shareslake` system non-root user.
1. Install `vim`, `jq` and `yq` tools.
1. Create directory structure under `/opt/shareslake` with the proper permissions.
1. Configure unattended upgrade for system packages.

### Downloading Shareslake binaries

First you need to download the Shareslake binaries and `libsodium` library. The `libsodium` library has been built with some modifications so installing it from system packages may not work.

Run the following:

```console
wget -O /opt/shareslake/bin/shareslake-node https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/shareslake-node
wget -O /opt/shareslake/bin/shareslake-cli https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/shareslake-cli
wget -O /opt/shareslake/lib/libsodium.so.23 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.34.1/libsodium.so.23
```

> IMPORTANT: The binaries currently are built for linux x86-64 arch.

The scripts later will configure your `LD_LIBRARY_PATH`. If you want to test the binaries now, just set it on the command:

```console
LD_LIBRARY_PATH="/opt/shareslake/lib" shareslake-cli --version
```

### Configure the node

Run the `node-config.sh` script to copy the configuration and genesis files to the correct locations.
It will also add the topology file. After running the script edit the `/opt/shareslake/configuration/topology.json` to set the IP of the other node, it is relay's IP if you are in the block producing or block producing's IP if you are in the relay.

The `node-config.sh` script will also create a new system service called `shareslake-node`. You can check it by running `systemctl status shareslake-node`.

#### Generate keys and certificates. Only for the block producing node

> It is recommended to generate the keys on an air-gapped offline machine.

> IMPORTANT: DO NOT lose the keys

Ensure you have `shareslake-cli` installed.

Edit the file `pool.json` adding the information for your stake pool.

To generate the stake pool keys execute the `generate-keys.sh` script. You need to select your pool `pledge`, `cost` and `margin`.
Execute `./generate-keys.sh` to check the options. Example:

```
./generate-keys.sh -d /tmp/test -p 3 -c 9000 -m 0.2 -u "https://www.my-pool.com/metadata"
```

The script will generate the stake pool hot (KES) and cold keys.
Hot keys need to be updated every 90 days and will be moved to the running node, while cold keys are intended to be preserved offline.
It will also generate the stake pool operational certificate and stake reward keys. As well as keys required by the stake pool owner, including the stake pool owner delegation certificate.
Finally, the script will generate the registration certificate that we will use later to register the pool into the network.

Once you have generated the keys, copy the following to the block-producing node at the specified path:

| LOCAL                                        | Block-producing node                  |
|:---------------------------------------------|:--------------------------------------|
| `<your_keys_dir>/pool/pool-kes.skey`         | `/home/shareslake/.shelley/kes.skey`  |
| `<your_keys_dir>/pool/pool-vrf.skey`         | `/home/shareslake/.shelley/vrf.skey`  |
| `<your_keys_dir>/pool/pool-operational.cert` | `/home/shareslake/.shelley/node.cert` |

### Start the nodes

1. Start the relay node and wait until it is synced:

```console
systemctl start shareslake-node
```

> You can check the sync status with `shareslake-cli query tip --mainnet`.

1. Once the relay is fully synced, start the block-producing node:

```console
systemctl start shareslake-node
```

And that's all! Now you have a working stake pool that will be receiving rewards from transactions validations at the end of each epoch.
Remember it will take 2 epochs boundaries for your pool to start earning.
You can now start convincing people to delegate their RED to your pool, the more RED delegated to your pool, the more rewards you will obtain.

## Containerized deployment

### TODO: publish container images

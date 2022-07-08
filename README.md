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
wget -O /opt/shareslake/bin/shareslake-node https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/shareslake-node
wget -O /opt/shareslake/bin/shareslake-cli https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/shareslake-cli
wget -O /opt/shareslake/lib/libsodium.so.23 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/libsodium.so.23
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

### Register the pool certificates

At this point, you will need to have the relay running and synced to be able to submit a transaction. Check the next step to start your relay and wait until it is synced.

To register the pool certificates you need to create and submit a transaction containing them.

You can find here how to do it step by step if you are not familiar with it. The scripts above already generated all the files you will need

Use the following to check your balance, `TxHash` and `TxIx`:

```console
shareslake-cli query utxo --address <your_address> --mainnet
```

Draft the Tx and calculate the fees:

```console
shareslake-cli transaction build-raw \
    --tx-in <TxHash>#<TxIx> \
    --tx-out $(cat <your_keys_dir>/owner/payment.addr)+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file tx.draft \
    --certificate-file <your_keys_dir>/owner/stake.reg.cert \
    --certificate-file <your_keys_dir>/owner/owner-stake.deleg.cert \
    --certificate-file <your_keys_dir>/pool/stake-reward.registration.cert \
    --certificate-file <your_keys_dir>/pool/registration.cert \
    --mainnet

# Calculate fees
shareslake-cli query protocol-parameters --mainnet > protocol.json
shareslake-cli transaction calculate-min-fee \
    --tx-body-file tx.draft \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 3 \
    --byron-witness-count 0 \
    --mainnet \
    --protocol-params-file protocol.json
```

Calculate the change as `<UTxO BALANCE> - <poolDeposit> - <TRANSACTION FEE>`. The pool deposit can be found into the `./protocol.json` file.

Now let's build the actual Tx. Use as `TTL` the current epoch plus some more.

```
shareslake-cli transaction build-raw \
    --tx-in <TxHash>#<TxIx> \
    --tx-out $(cat <your_keys_dir>/owner/payment.addr)+<CHANGE IN LOVELACE> \
    --invalid-hereafter <TTL> \
    --fee <TRANSACTION FEE> \
    --out-file tx.raw \
    --certificate-file <your_keys_dir>/owner/stake.reg.cert \
    --certificate-file <your_keys_dir>/owner/owner-stake.deleg.cert \
    --certificate-file <your_keys_dir>/pool/stake-reward.registration.cert \
    --certificate-file <your_keys_dir>/pool/registration.cert \
    --mainnet
```

Sign the Tx:

```console
shareslake-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file <your_keys_dir>/owner/payment.skey \
    --signing-key-file <your_keys_dir>/owner/stake.skey \
    --signing-key-file .<your_keys_dir>/pool/stake-reward.skey \
    --signing-key-file <your_keys_dir>/pool/pool.skey \
    --mainnet \
    --out-file tx.signed
```

Now copy the signed transaction to your relay node, and execute the following to submit it:

```console
shareslake-cli transaction submit \
    --tx-file tx.signed \
    --mainnet
```

After some time, check the registration is correct as follows:

1. We need to the pool id:

```console
shareslake-cli stake-pool id --cold-verification-key-file <your_keys_dir>/pool/pool.vkey --output-format "hex"
```

2. Check your pool id is on the network:

```console
shareslake-cli query ledger-state --mainnet | grep publicKey | grep <poolId>
```

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

## Debug information

### Wrong genesis hash

If you see a message in `/opt/shareslake/logs/out.log` stating that the genesis hash indicated in the configuration file differs from the actual hash, delete the content of the corresponding genesis file (one of `/opt/shareslake/shelley/genesis.json`, `/opt/shareslake/shelley/genesis.alonzo.json` or `/opt/shareslake/byron/genesis.json`) and copy-paste the content inside from the `config` directory in this repository (without trailing spaces at the end). Then check the hash correspond with the hash specified in the configuration file at `/opt/sharesake/configuration/`.

Use the following command to check the hash:

```console
shareslake-cli genesis hash --genesis <file_path>
```

> Be sure to be working as `shareslake` user during this process. If you are working as root you will need to export `LD_LIBRARY_PATH` and `PATH` manually to use the shareslake binaries.

## Containerized deployment

Shareslake node: https://hub.docker.com/repository/docker/shareslake/shareslake-node
Shareslake db sync: https://hub.docker.com/repository/docker/shareslake/shareslake-db-sync

Check [this](https://github.com/shareslake/cardano-address-monitor/blob/main/test/docker-compose.yaml) `docker-compose.yaml` file for an example of a Shareslake relay plus shareslake-db-sync and the Shareslake's cardano-address monitor.

## Upgrading

### `1.34.1` to `1.35.0`

1. Stop the running node: `systemctl stop shareslake-node`.
1. Go to `/opt/shareslake/bin` and remove `shareslake-cli` and `shareslake-node` binaries.
1. Download the new binaries:

    ```console
    wget -O /opt/shareslake/bin/shareslake-cli https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/shareslake-cli
    wget -O /opt/shareslake/bin/shareslake-node https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/shareslake-node
    chmod +x /opt/shareslake/bin/*
    ```

1. Start the node: `systemctl start shareslake-node`.
1. Check the status with `systemctl status shareslake-node`. If there is an error check `/opt/shareslake/logs/err.log`. If the error is a missing library called `libsecp256k1.so.0` execute the following and then check the node status again:

    ```console
    wget -O /opt/shareslake/lib/libsecp256k1.so.0 https://shareslake-public-binaries.s3.eu-west-3.amazonaws.com/1.35.0/libsecp256k1.so.0
    systemctl start shareslake-node
    ```



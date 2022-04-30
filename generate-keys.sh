#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

keys_dir=""
pledge=""
cost=""
margin=""
metadata_url=""

usage() { echo "Usage: $0"
          echo "-d <string>  - Directory where to save the keys"
          echo "-p <number>  - Pool pledge. How much funds the operator locks into the pool. Can be 0."
          echo "-c <number>  - Pool cost. How much RED should be send to the owner before distributing the pool rewards to cover the pool costs."
          echo "-m <number>  - Pool margin. How much does the stake pool operator earn from the rewards. ust be lower than 1"
          echo "-u <string>  - Pool metadata URL. URL where the pool metadata is served (the pool.json file content)."
          echo "               This is just for adding the information while registering, the URL does NOT need to be working at this moment."
          exit 1
}

while getopts "d:p:c:m:u:" o; do
    echo "o: $o"
    case "$o" in
        d)
            keys_dir="$OPTARG"
            ;;
        p)
            pledge="$OPTARG"
            ;;
        c)
            cost="$OPTARG"
            ;;
        m)
            margin="$OPTARG"
            ;;
        u)
            metadata_url="$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))

[[ "$(echo "$margin > 1" | bc -l)" -eq "1" ]] && echo "Pool margin cannot be greater than 1" && exit 1
if [[ -z "$keys_dir" ]] || [[ -z "$pledge" ]] || [[ -z "$cost" ]] || [[ -z "$margin" ]] || [[ -z "$metadata_url" ]]; then
    usage
fi

SHARESLAKE_POOL_KEYS_DIR="${keys_dir}/pool"
SHARESLAKE_OWNER_KEYS_DIR="${keys_dir}/owner"

mkdir -p "$SHARESLAKE_POOL_KEYS_DIR" "$SHARESLAKE_OWNER_KEYS_DIR"

####################################################
##### Keys required by the stake pool ########
####################################################

# Pool cold keys
shareslake-cli node key-gen \
    --cold-verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool.vkey" \
    --cold-signing-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool.skey" \
    --operational-certificate-issue-counter-file "${SHARESLAKE_POOL_KEYS_DIR}/pool.counter"

shareslake-cli node key-gen-VRF \
    --verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool-vrf.vkey" \
    --signing-key-file      "${SHARESLAKE_POOL_KEYS_DIR}/pool-vrf.skey"

# Set permissions for the VRF private key file: read for owner only
chmod 400 "${SHARESLAKE_POOL_KEYS_DIR}/pool-vrf.skey" "${SHARESLAKE_POOL_KEYS_DIR}/pool.skey"

# Generate hot keys
shareslake-cli node key-gen-KES \
    --verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool-kes.vkey" \
    --signing-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool-kes.skey"

# Generate the operational certificate from the keys
shareslake-cli node issue-op-cert \
    --kes-verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool-kes.vkey" \
    --cold-signing-key-file "${SHARESLAKE_POOL_KEYS_DIR}/pool.skey" \
    --operational-certificate-issue-counter "${SHARESLAKE_POOL_KEYS_DIR}/pool.counter" \
    --kes-period 0 \
    --out-file "${SHARESLAKE_POOL_KEYS_DIR}/pool-operational.cert"

# Stake reward keys
shareslake-cli stake-address key-gen \
    --signing-key-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.skey" \
    --verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.vkey"

shareslake-cli stake-address registration-certificate \
    --stake-verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.vkey" \
    --out-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.registration.cert"

shareslake-cli stake-address build \
    --stake-verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.vkey" \
    --out-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.addr" \
    --mainnet

####################################################
##### Keys required by the stake pool owner ########
####################################################
shareslake-cli address key-gen \
    --verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/payment.vkey" \
    --signing-key-file      "${SHARESLAKE_OWNER_KEYS_DIR}/payment.skey"

shareslake-cli stake-address key-gen \
    --verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --signing-key-file      "${SHARESLAKE_OWNER_KEYS_DIR}/stake.skey"

shareslake-cli address build \
    --payment-verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/payment.vkey" \
    --stake-verification-key-file   "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --out-file                      "${SHARESLAKE_OWNER_KEYS_DIR}/payment.addr" \
    --mainnet

shareslake-cli stake-address build \
    --stake-verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --out-file                    "${SHARESLAKE_OWNER_KEYS_DIR}/stake.addr" \
    --mainnet

shareslake-cli stake-address registration-certificate \
    --stake-verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --out-file                    "${SHARESLAKE_OWNER_KEYS_DIR}/stake.reg.cert"

########################################################
# Generate the stake pool owner delegation certificate #
########################################################
shareslake-cli stake-address delegation-certificate \
    --stake-verification-key-file "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --cold-verification-key-file  "${SHARESLAKE_POOL_KEYS_DIR}/pool.vkey" \
    --out-file                    "${SHARESLAKE_OWNER_KEYS_DIR}/owner-stake.deleg.cert"

###################################################################
# Generate the pool registration certificate using the owner keys #
###################################################################

# Crete pool metadata
cp ./pool.json "${SHARESLAKE_KEYS_DIR}/pool.json"
metadata_hash="$(shareslake-cli stake-pool metadata-hash --pool-metadata-file "${SHARESLAKE_KEYS_DIR}/pool.json")"

# Note we use as reward account the same verification key as the pool owner stake
shareslake-cli stake-pool registration-certificate \
    --pool-pledge                               "$pledge" \
    --pool-cost                                 "$cost" \
    --pool-margin                               "$margin" \
    --cold-verification-key-file                "${SHARESLAKE_POOL_KEYS_DIR}/pool.vkey" \
    --vrf-verification-key-file                 "${SHARESLAKE_POOL_KEYS_DIR}/pool-vrf.vkey" \
    --pool-reward-account-verification-key-file "${SHARESLAKE_POOL_KEYS_DIR}/stake-reward.vkey" \
    --pool-owner-stake-verification-key-file    "${SHARESLAKE_OWNER_KEYS_DIR}/stake.vkey" \
    --metadata-url                              "$metadata_url" \
    --metadata-hash                             "$metadata_hash" \
    --out-file                                  "${SHARESLAKE_POOL_KEYS_DIR}/registration.cert" \
    --mainnet

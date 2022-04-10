#!/bin/sh

if [ -d /data/pocketcoin ]; then
  echo 'Found existing directory at /data/pocketcoin.  Skipping initialization.'
  exit 0
fi

echo 'Initializing pocketcoin configuration with RPC username and password...'

mkdir -p /data/pocketcoin
echo "Created /data/pocketcoin directory."

RPCAUTH_OUT=$(python3 /home/pocketcoin/rpcauth.py "${RPC_USERNAME}" "${RPC_PASSWORD}" 2>/tmp/rpcauth.err | grep 'rpcauth=')

RPCAUTH_ERR=$(cat /tmp/rpcauth.err)
if [ -n "${RPCAUTH_ERR}" ]; then
  echo 'Unexpected error while initializing RPC authentication:'
  echo "${RPCAUTH_ERR}"
  echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  exit 129
fi

sed -E "s/^rpcauth=.*$/${RPCAUTH_OUT}/" /home/pocketcoin/pocketcoin.conf.template > /data/pocketcoin/pocketcoin.conf
echo "Added '${RPCAUTH_OUT}' to /data/pocketcoin/pocketcoin.conf."

echo 'Copying main.sqlite3 database into data folder...'
mkdir -p /data/pocketcoin/checkpoints
cp /home/pocketcoin/main.sqlite3.init /data/pocketcoin/checkpoints/main.sqlite3

echo 'Finished!'

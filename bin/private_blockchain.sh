#!/bin/bash

geth=${GETH:-geth}
timestamp=`date +%s`
NETWORK_ID=${NETWORK_ID:-$timestamp}

exec $geth --datadir /data --genesis ./genesis.json --networkid $NETWORK_ID --etherbase '3ae88fe370c39384fc16da2c9e768cf5d2495b48' --rpc --rpccorsdomain "*" console


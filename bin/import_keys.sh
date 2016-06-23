#!/bin/sh

geth=${GETH:-geth}
echo "***** Using geth at: $geth"

echo "***** Import all pre-funded private keys"
echo "***** Password: $(cat password)"

for key in `find ./private_keys -name '*.key'`
do
	$geth --password password --datadir data account import $key
done

echo "***** Done."

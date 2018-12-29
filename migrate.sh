#!/bin/bash

if [ -z "$1" ]; then
    echo "Network is not specified"
    exit 1
fi

echo "migrating to $1"
tronbox migrate --reset --network $1

echo "Sourcing env vars"
source injecter_env.sh

echo "Running contract.py"
python ./ContractInjecter.py

echo "Done"


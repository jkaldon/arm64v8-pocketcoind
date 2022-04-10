#!/bin/sh

helm upgrade pocketcoind -n pocketcoin --create-namespace --install ./ -f values.yaml

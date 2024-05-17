#!/usr/bin/env bash

kubectl -n wireguard exec deploy/wireguard -- cat /config/peer$1/peer$1.conf
echo 'PersistentKeepalive = 15'
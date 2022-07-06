#!/bin/sh
set -e

## fix resource manager fatal error on arm64/linux with 2Gb RAM
# ipfs config --json Swarm.ResourceMgr.Enabled false
# ERROR   p2pnode libp2p/rcmgr_defaults.go:107    ===> OOF! go-libp2p changed DefaultServiceLimits
# => changes ('test' represents the old value):
#  {"op":"test","path":"/SystemLimits/Memory","value":1073741824}
#  {"op":"replace","path":"/SystemLimits/Memory","value":256560128}
# => go-libp2p SetDefaultServiceLimits update needs a review:
# Please inspect if changes impact go-ipfs users, and update expectedDefaultServiceLimits in rcmgr_defaults.go to remove this message
# FATAL   p2pnode libp2p/rcmgr_defaults.go:115    daemon will refuse to run with the resource manager until this is resolved

## Astroport.One
ipfs config Pubsub.Router gossipsub
ipfs config --json Experimental.Libp2pStreamMounting true
ipfs config --json Experimental.P2pHttpProxy true
ipfs config Addresses.Gateway "/ip4/0.0.0.0/tcp/8080"

## ipfs client needs API address
# search for ip address of $(hostname).${IPFS_ADDRESSES_API_DOMAIN}
[ -n "${IPFS_ADDRESSES_API_DOMAIN}" ] && [ -z "${IPFS_ADDRESSES_API_INET4}" ] \
 && IPFS_ADDRESSES_API_INET4=$(nslookup -type=A "$(hostname).${IPFS_ADDRESSES_API_DOMAIN}" |awk 'found && /^Address:/ {print $2; found=0}; /^Name:\t'"$(hostname).${IPFS_ADDRESSES_API_DOMAIN}"'/ {found=1};')
# check ${IPFS_ADDRESSES_API_INET4} format
echo "${IPFS_ADDRESSES_API_INET4}" |awk -F. '{ for ( i=1; i<=4; i++ ) if ($i >= 0 && $i <= 255); else exit 1;}; NF != 4 {exit 1;}' || unset IPFS_ADDRESSES_API_INET4
# check ${IPFS_ADDRESSES_API_PORT} format
[ "${IPFS_ADDRESSES_API_PORT}" -eq "${IPFS_ADDRESSES_API_PORT}" ] 2>/dev/null && [ "${IPFS_ADDRESSES_API_PORT}" -ge 1 ] && [ "${IPFS_ADDRESSES_API_PORT}" -le 65535 ] \
 || unset IPFS_ADDRESSES_API_PORT
ipfs config Addresses.Api "${IPFS_ADDRESSES_API:-/ip4/${IPFS_ADDRESSES_API_INET4:-127.0.0.1}/tcp/${IPFS_ADDRESSES_API_PORT:-5001}}"

## REMOVE IPFS BOOTSTRAP
ipfs bootstrap rm --all

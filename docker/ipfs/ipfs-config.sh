#!/bin/sh

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

## REMOVE IPFS BOOTSTRAP
ipfs bootstrap rm --all

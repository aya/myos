#!/bin/sh
[ -n "${DEBUG:-}" -a "${DEBUG:-}" != "false" ] && set -x
set -e

## fix resource manager fatal error on arm64/linux with 2Gb RAM
# ipfs config --json Swarm.ResourceMgr.Enabled false
# ERROR   p2pnode libp2p/rcmgr_defaults.go:107    ===> OOF! go-libp2p changed DefaultServiceLimits

# set ipfs peer id
[ -n "${IPFS_IDENTITY_PEERID}" ] && [ -n "${IPFS_IDENTITY_PRIVKEY}" ] \
 && sed -i 's/"PeerID":.*/"PeerID": "'"${IPFS_IDENTITY_PEERID}"'",/;s/"PrivKey":.*/"PrivKey": "'"${IPFS_IDENTITY_PRIVKEY}"'"/' "${IPFS_PATH}/config" \
 || true

## ipfs client needs API address
# search for ip address of $(hostname).${IPFS_ADDRESSES_API_DOMAIN}
[ -n "${IPFS_ADDRESSES_API_DOMAIN}" ] && [ -z "${IPFS_ADDRESSES_API_INET4}" ] \
 && IPFS_ADDRESSES_API_INET4=$(nslookup -type=A -timeout=1 "$(hostname).${IPFS_ADDRESSES_API_DOMAIN}" |awk 'found && /^Address:/ {print $2; found=0}; /^Name:\t'"$(hostname).${IPFS_ADDRESSES_API_DOMAIN}"'/ {found=1};')
# check ${IPFS_ADDRESSES_API_INET4} format
echo "${IPFS_ADDRESSES_API_INET4}" |awk -F. '{ for ( i=1; i<=4; i++ ) if ($i >= 0 && $i <= 255); else exit 1;}; NF != 4 {exit 1;}' || unset IPFS_ADDRESSES_API_INET4
# check ${IPFS_ADDRESSES_API_PORT} format
[ "${IPFS_ADDRESSES_API_PORT}" -eq "${IPFS_ADDRESSES_API_PORT}" ] 2>/dev/null && [ "${IPFS_ADDRESSES_API_PORT}" -ge 1 ] && [ "${IPFS_ADDRESSES_API_PORT}" -le 65535 ] \
 || unset IPFS_ADDRESSES_API_PORT
ipfs config Addresses.Api "${IPFS_ADDRESSES_API:-/ip4/${IPFS_ADDRESSES_API_INET4:-127.0.0.1}/tcp/${IPFS_ADDRESSES_API_PORT:-5001}}"

## gateway address
# search for ip address of $(hostname).${IPFS_ADDRESSES_GATEWAY_DOMAIN}
[ -n "${IPFS_ADDRESSES_GATEWAY_DOMAIN}" ] && [ -z "${IPFS_ADDRESSES_GATEWAY_INET4}" ] \
 && IPFS_ADDRESSES_GATEWAY_INET4=$(nslookup -type=A -timeout=1 "$(hostname).${IPFS_ADDRESSES_GATEWAY_DOMAIN}" |awk 'found && /^Address:/ {print $2; found=0}; /^Name:\t'"$(hostname).${IPFS_ADDRESSES_GATEWAY_DOMAIN}"'/ {found=1};')
# check ${IPFS_ADDRESSES_GATEWAY_INET4} format
echo "${IPFS_ADDRESSES_GATEWAY_INET4}" |awk -F. '{ for ( i=1; i<=4; i++ ) if ($i >= 0 && $i <= 255); else exit 1;}; NF != 4 {exit 1;}' || unset IPFS_ADDRESSES_GATEWAY_INET4
# check ${IPFS_ADDRESSES_GATEWAY_PORT} format
[ "${IPFS_ADDRESSES_GATEWAY_PORT}" -eq "${IPFS_ADDRESSES_GATEWAY_PORT}" ] 2>/dev/null && [ "${IPFS_ADDRESSES_GATEWAY_PORT}" -ge 1 ] && [ "${IPFS_ADDRESSES_GATEWAY_PORT}" -le 65535 ] \
 || unset IPFS_ADDRESSES_GATEWAY_PORT
ipfs config Addresses.Gateway "${IPFS_ADDRESSES_GATEWAY:-/ip4/${IPFS_ADDRESSES_GATEWAY_INET4:-127.0.0.1}/tcp/${IPFS_ADDRESSES_GATEWAY_PORT:-8080}}"

[ -n "${IPFS_ADDRESSES_NOANNOUNCE}" ] && ipfs config --json Addresses.NoAnnounce "${IPFS_ADDRESSES_NOANNOUNCE}"

## api http headers
[ -n "${IPFS_API_HTTPHEADERS}${IPFS_API_HTTPHEADERS_ACA_CREDENTIALS}${IPFS_API_HTTPHEADERS_ACA_HEADERS}${IPFS_API_HTTPHEADERS_ACA_METHODS}${IPFS_API_HTTPHEADERS_ACA_ORIGIN}" ] \
 && ipfs config --json API.HTTPHeaders "${IPFS_API_HTTPHEADERS:-{
\"Access-Control-Allow-Credentials\": ${IPFS_API_HTTPHEADERS_ACA_CREDENTIALS:-null},
\"Access-Control-Allow-Headers\": ${IPFS_API_HTTPHEADERS_ACA_HEADERS:-null},
\"Access-Control-Allow-Methods\": ${IPFS_API_HTTPHEADERS_ACA_METHODS:-null},
\"Access-Control-Allow-Origin\": ${IPFS_API_HTTPHEADERS_ACA_ORIGIN:-null}
}}"

## bootstrap
[ -n "${IPFS_BOOTSTRAP}" ] && ipfs config --json Bootstrap "${IPFS_BOOTSTRAP}"

## storage
# limit disk usage to 50 percent of disk size
diskSize=$(df -P ${IPFS_PATH:-~/.ipfs} | awk 'NR>1{size+=$2}END{print size}')
ipfs config Datastore.StorageMax "$((diskSize * ${IPFS_DISK_USAGE_PERCENT:-50/100}))"
# garbage collector
[ -n "${IPFS_DATASTORE_GCPERIOD}" ] && ipfs config Datastore.GCPeriod "${IPFS_DATASTORE_GCPERIOD}"

## experimental features
[ -n "${IPFS_EXPERIMENTAL_ACCELERATEDDHTCLIENT}" ] && ipfs config --json Experimental.AcceleratedDHTClient "${IPFS_EXPERIMENTAL_ACCELERATEDDHTCLIENT}"
[ -n "${IPFS_EXPERIMENTAL_FILESTOREENABLED}" ] && ipfs config --json Experimental.FilestoreEnabled "${IPFS_EXPERIMENTAL_FILESTOREENABLED}"
[ -n "${IPFS_EXPERIMENTAL_GRAPHSYNCENABLED}" ] && ipfs config --json Experimental.GraphsyncEnabled "${IPFS_EXPERIMENTAL_GRAPHSYNCENABLED}"
[ -n "${IPFS_EXPERIMENTAL_LIBP2PSTREAMMOUNTING}" ] && ipfs config --json Experimental.Libp2pStreamMounting "${IPFS_EXPERIMENTAL_LIBP2PSTREAMMOUNTING}"
[ -n "${IPFS_EXPERIMENTAL_P2PHTTPPROXY}" ] && ipfs config --json Experimental.P2pHttpProxy "${IPFS_EXPERIMENTAL_P2PHTTPPROXY}"
[ -n "${IPFS_EXPERIMENTAL_STRATEGICPROVIDING}" ] && ipfs config --json Experimental.StrategicProviding "${IPFS_EXPERIMENTAL_STRATEGICPROVIDING}"
[ -n "${IPFS_EXPERIMENTAL_URLSTOREENABLED}" ] && ipfs config --json Experimental.UrlstoreEnabled "${IPFS_EXPERIMENTAL_URLSTOREENABLED}"

## gateway http headers
[ -n "${IPFS_GATEWAY_HTTPHEADERS}${IPFS_GATEWAY_HTTPHEADERS_ACA_CREDENTIALS}${IPFS_GATEWAY_HTTPHEADERS_ACA_HEADERS}${IPFS_GATEWAY_HTTPHEADERS_ACA_METHODS}${IPFS_GATEWAY_HTTPHEADERS_ACA_ORIGIN}" ] \
 && ipfs config --json Gateway.HTTPHeaders "${IPFS_GATEWAY_HTTPHEADERS:-{
\"Access-Control-Allow-Credentials\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_CREDENTIALS:-[ \"true\" ]},
\"Access-Control-Allow-Headers\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_HEADERS:-[ \"X-Requested-With\", \"Range\", \"User-Agent\" ]},
\"Access-Control-Allow-Methods\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_METHODS:-[ \"GET\" ]},
\"Access-Control-Allow-Origin\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_ORIGIN:-[ \"*\" ]}
}}"

## ipns
[ -n "${IPFS_IPNS_REPUBLISHPERIOD}" ] && ipfs config Ipns.RepublishPeriod "${IPFS_IPNS_REPUBLISHPERIOD}"
[ -n "${IPFS_IPNS_RECORDLIFETIME}" ] && ipfs config Ipns.RecordLifetime "${IPFS_IPNS_RECORDLIFETIME}"
[ -n "${IPFS_IPNS_USEPUBSUB}" ] && ipfs config --json Ipns.UsePubsub "${IPFS_IPNS_USEPUBSUB}"

## dht pubsub mode
[ -n "${IPFS_PUBSUB_ENABLE}" ] && ipfs config --json Pubsub.Enabled "${IPFS_PUBSUB_ENABLE}"
[ -n "${IPFS_PUBSUB_ROUTER}" ] && ipfs config Pubsub.Router "${IPFS_PUBSUB_ROUTER}"

## routing
[ -n "${IPFS_ROUTING_TYPE}" ] && ipfs config Routing.Type "${IPFS_ROUTING_TYPE}"

## reproviding local content to routing system
[ -n "${IPFS_REPROVIDER_INTERVAL}" ] && ipfs config Reprovider.Interval "${IPFS_REPROVIDER_INTERVAL}"
[ -n "${IPFS_REPROVIDER_STRATEGY}" ] && ipfs config Reprovider.Strategy "${IPFS_REPROVIDER_STRATEGY}"

## swarm config
[ -n "${IPFS_SWARM_CONNMGR_HIGHWATER}" ] && ipfs config --json Swarm.ConnMgr.HighWater "${IPFS_SWARM_CONNMGR_HIGHWATER}"
[ -n "${IPFS_SWARM_CONNMGR_LOWWATER}" ] && ipfs config --json Swarm.ConnMgr.LowWater "${IPFS_SWARM_CONNMGR_LOWWATER}"
[ -n "${IPFS_SWARM_CONNMGR_TYPE}" ] && ipfs config --json Swarm.ConnMgr.Type "${IPFS_SWARM_CONNMGR_TYPE}"
[ -n "${IPFS_SWARM_DISABLENATPORTMAP}" ] && ipfs config --bool Swarm.DisableNatPortMap "${SWARM_DISABLENATPORTMAP}"
[ -n "${IPFS_SWARM_ENABLEHOLEPUNCHING}" ] && ipfs config --bool Swarm.EnableHolePunching "${SWARM_ENABLEHOLEPUNCHING}"
[ -n "${IPFS_SWARM_RELAYCLIENT_ENABLED}" ] && ipfs config --bool Swarm.RelayClient.Enabled "${SWARM_RELAYCLIENT_ENABLED}"
[ -n "${IPFS_SWARM_RELAYSERVICE_ENABLED}" ] && ipfs config --bool Swarm.RelayService.Enabled "${SWARM_RELAYSERVICE_ENABLED}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_RELAY}" ] && ipfs config --bool Swarm.Transports.Network.Relay "${SWARM_TRANSPORTS_NETWORK_RELAY}"

## REMOVE IPFS BOOTSTRAP for private usage
[ ${IPFS_NETWORK:-public} = "public" ] || ipfs bootstrap rm --all
[ ${IPFS_NETWORK:-public} = "private" ] && export LIBP2P_FORCE_PNET=1 ||:

## ALLOW AUTO DISCOVERY ON DOCKER NETWORK
ipfs config --bool Discovery.MDNS.Enabled true
ipfs config --json Addresses.NoAnnounce "$(ipfs config Addresses.NoAnnounce |sed '/172.16.0.0/d')"
ipfs config --json Swarm.AddrFilters "$(ipfs config Swarm.AddrFilters |sed '/172.16.0.0/d')"

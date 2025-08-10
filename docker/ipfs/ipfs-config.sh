#!/bin/sh
[ -n "${DEBUG:-}" -a "${DEBUG:-}" != "false" ] && set -x
set -e

## fix resource manager fatal error on arm64/linux with 2Gb RAM
# ipfs config --json Swarm.ResourceMgr.Enabled false
# ERROR   p2pnode libp2p/rcmgr_defaults.go:107    ===> OOF! go-libp2p changed DefaultServiceLimits

# apply migration
if [ "${IPFS_REPO_MIGRATE}" = "true" ]; then ipfs repo stat >/dev/null || ipfs repo migrate; fi

# set ipfs peer id
[ -n "${IPFS_IDENTITY_PEERID}" ] && [ -n "${IPFS_IDENTITY_PRIVKEY}" ] \
 && sed -i 's/"PeerID":.*/"PeerID": "'"${IPFS_IDENTITY_PEERID}"'",/;s/"PrivKey":.*/"PrivKey": "'"${IPFS_IDENTITY_PRIVKEY}"'"/' "${IPFS_PATH}/config" \
 || true

# apply ipfs profile
[ -n "${IPFS_PROFILE}" ] && for profile in ${IPFS_PROFILE}; do ipfs config profile apply "${profile}"; done

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

[ -n "${IPFS_ADDRESSES_SWARM}" ] && ipfs config --json Addresses.Swarm "${IPFS_ADDRESSES_SWARM}"
[ -n "${IPFS_ADDRESSES_ANNOUNCE}" ] && ipfs config --json Addresses.Announce "${IPFS_ADDRESSES_ANNOUNCE}"
[ -n "${IPFS_ADDRESSES_APPENDANNOUNCE}" ] && ipfs config --json Addresses.AppendAnnounce "${IPFS_ADDRESSES_APPENDANNOUNCE}"
[ -n "${IPFS_ADDRESSES_NOANNOUNCE}" ] && ipfs config --json Addresses.NoAnnounce "${IPFS_ADDRESSES_NOANNOUNCE}"

## api http headers
[ -n "${IPFS_API_HTTPHEADERS}${IPFS_API_HTTPHEADERS_ACA_CREDENTIALS}${IPFS_API_HTTPHEADERS_ACA_HEADERS}${IPFS_API_HTTPHEADERS_ACA_METHODS}${IPFS_API_HTTPHEADERS_ACA_ORIGIN}" ] \
 && ipfs config --json API.HTTPHeaders "${IPFS_API_HTTPHEADERS:-{
\"Access-Control-Allow-Credentials\": ${IPFS_API_HTTPHEADERS_ACA_CREDENTIALS:-null},
\"Access-Control-Allow-Headers\": ${IPFS_API_HTTPHEADERS_ACA_HEADERS:-null},
\"Access-Control-Allow-Methods\": ${IPFS_API_HTTPHEADERS_ACA_METHODS:-null},
\"Access-Control-Allow-Origin\": ${IPFS_API_HTTPHEADERS_ACA_ORIGIN:-null}
}}"

## api authorizations:     "Bob": { "AuthSecret": "bearer:secret-token123", "AllowedPaths": ["/api/v0"] }
[ -n "${IPFS_API_AUTHORIZATIONS}" ] && ipfs config --json API.Authorizations "${IPFS_API_AUTHORIZATIONS}"

## autonat service
[ -n "$IPFS_AUTONAT$IPFS_AUTONAT_SERVICEMODE$IPFS_AUTONAT_THROTTLE$IPFS_AUTONAT_THROTTLE_GLOBALLIMIT$IPFS_AUTONAT_THROTTLE_PEERLIMIT$IPFS_AUTONAT_THROTTLE_INTERVAL" ] \
 && ipfs config --json AutoNAT "${IPFS_AUTONAT:-{
\"ServiceMode\": ${IPFS_AUTONAT_SERVICEMODE:-null},
\"Throttle\": ${IPFS_AUTONAT_THROTTLE:-{
 \"GlobalLimit\": ${IPFS_AUTONAT_THROTTLE_GLOBALLIMIT:-null},
 \"PeerLimit\": ${IPFS_AUTONAT_THROTTLE_PEERLIMIT:-null},
 \"Interval\": \"${IPFS_AUTONAT_THROTTLE_INTERVAL:-null}\"
 }
}}"

## auto tls
[ -n "$IPFS_AUTOTLS$IPFS_AUTOTLS_ENABLED$IPFS_AUTOTLS_DOMAINSUFFIX$IPFS_AUTOTLS_REGISTRATIONENDPOINT$IPFS_AUTOTLS_REGISTRATIONTOKEN$IPFS_AUTOTLS_CAENDPOINT" ] \
 && ipfs config --json AutoNAT "${IPFS_AUTOTLS:-{
\"Enabled\": ${IPFS_AUTOTLS_ENABLED:-null},
\"DomainSuffix\": ${IPFS_AUTOTLS_DOMAINSUFFIX:-null},
\"RegistrationEndpoint\": ${IPFS_AUTOTLS_REGISTRATIONENDPOINT:-null},
\"RegistrationToken\": ${IPFS_AUTOTLS_REGISTRATIONTOKEN:-null},
\"CAEndpoint\": ${IPFS_AUTOTLS_CAENDPOINT:-null}
}}"

## bootstrap
[ -n "${IPFS_BOOTSTRAP}" ] && ipfs config --json Bootstrap "${IPFS_BOOTSTRAP}"

## storage
# limit disk usage to xx/percent of disk size
diskSize=$(df -P ${IPFS_PATH:-~/.ipfs} | awk 'NR>1{size+=$2}END{print size}')
ipfs config Datastore.StorageMax "$((diskSize * ${IPFS_DATASTORE_DISKUSAGE:-50}/100))"
# garbage collector is declenched over xx/percent of available disk used
[ -n "${IPFS_DATASTORE_STORAGEGCWATERMARK}" ] && ipfs config Datastore.StorageGCWatermark "${IPFS_DATASTORE_STORAGEGCWATERMARK}"
# automatic garbage collector run every time period
[ -n "${IPFS_DATASTORE_GCPERIOD}" ] && ipfs config Datastore.GCPeriod "${IPFS_DATASTORE_GCPERIOD}"
[ -n "${IPFS_DATASTORE_HASHONREAD}" ] && ipfs config --bool Datastore.HashOnRead "${IPFS_DATASTORE_HASHONREAD}"
[ -n "${IPFS_DATASTORE_BLOOMFILTERSIZE}" ] && ipfs config --json Datastore.BloomFilterSize "${IPFS_DATASTORE_BLOOMFILTERSIZE}"
[ -n "${IPFS_DATASTORE_SPEC}" ] && ipfs config --json Datastore.Spec "${IPFS_DATASTORE_SPEC}"

## ALLOW AUTO DISCOVERY ON DOCKER NETWORK
[ -n "${IPFS_DISCOVERY_MDNS_ENABLED}" ] && ipfs config --bool Discovery.MDNS.Enabled "${IPFS_DISCOVERY_MDNS_ENABLED}"
[ -n "${IPFS_DOCKER_NETWORK}" ] && ipfs config --json Addresses.NoAnnounce "$(ipfs config Addresses.NoAnnounce |sed '/"${IPFS_DOCKER_NETWORK}"/d')"

## serve only local content
[ -n "${IPFS_GATEWAY_NOFETCH}" ] && ipfs config --bool Gateway.NoFetch "${IPFS_GATEWAY_NOFETCH}"
## redirect content with TXT DNS link prefix
[ -n "${IPFS_GATEWAY_NODNSLINK}" ] && ipfs config --bool Gateway.NoDNSLink "${IPFS_GATEWAY_NODNSLINK}"
## false = trustless gateway
[ -n "${IPFS_GATEWAY_DESERIALIZEDRESPONSES}" ] && ipfs config --json Gateway.DeserializedResponses "${IPFS_GATEWAY_DESERIALIZEDRESPONSES}"
## pretty html errors
[ -n "${IPFS_GATEWAY_DISABLEHTMLERRORS}" ] && ipfs config --json Gateway.DisableHTMLErrors "${IPFS_GATEWAY_DISABLEHTMLERRORS}"
## someguy
[ -n "${IPFS_GATEWAY_EXPOSEROUTINGAPI}" ] && ipfs config --json Gateway.ExposeRoutingAPI "${IPFS_GATEWAY_EXPOSEROUTINGAPI}"
## gateway http headers
[ -n "${IPFS_GATEWAY_HTTPHEADERS}${IPFS_GATEWAY_HTTPHEADERS_ACA_CREDENTIALS}${IPFS_GATEWAY_HTTPHEADERS_ACA_HEADERS}${IPFS_GATEWAY_HTTPHEADERS_ACA_METHODS}${IPFS_GATEWAY_HTTPHEADERS_ACA_ORIGIN}" ] \
 && ipfs config --json Gateway.HTTPHeaders "${IPFS_GATEWAY_HTTPHEADERS:-{
\"Access-Control-Allow-Credentials\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_CREDENTIALS:-null},
\"Access-Control-Allow-Headers\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_HEADERS:-null},
\"Access-Control-Allow-Methods\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_METHODS:-null},
\"Access-Control-Allow-Origin\": ${IPFS_GATEWAY_HTTPHEADERS_ACA_ORIGIN:-null}
}}"
## redirect /
[ -n "${IPFS_GATEWAY_ROOTREDIRECT}" ] && ipfs config Gateway.RootRedirect "${IPFS_GATEWAY_ROOTREDIRECT}"
## public gateways: { "localhost": { "Paths": ["/ipfs", "/ipns"], "UseSubdomains": true } }
[ -n "${IPFS_GATEWAY_PUBLICGATEWAYS}" ] && ipfs config --json Gateway.PublicGateways "${IPFS_GATEWAY_PUBLICGATEWAYS}"

## ipns
[ -n "${IPFS_IPNS_REPUBLISHPERIOD}" ] && ipfs config Ipns.RepublishPeriod "${IPFS_IPNS_REPUBLISHPERIOD}"
[ -n "${IPFS_IPNS_RECORDLIFETIME}" ] && ipfs config Ipns.RecordLifetime "${IPFS_IPNS_RECORDLIFETIME}"
[ -n "${IPFS_IPNS_RESOLVECACHESIZE}" ] && ipfs config Ipns.ResolveCacheSize "${IPFS_IPNS_RESOLVECACHESIZE}"
[ -n "${IPFS_IPNS_MAXCACHETTL}" ] && ipfs config Ipns.MaxCacheTTL "${IPFS_IPNS_MAXCACHETTL}"
[ -n "${IPFS_IPNS_USEPUBSUB}" ] && ipfs config --json Ipns.UsePubsub "${IPFS_IPNS_USEPUBSUB}"

## pinning
[ -n "${IPFS_PINNING_REMOTESERVICES}" ] && ipfs config --json Pinning.RemoteServices "${IPFS_PINNING_REMOTESERVICES}"

## peering :)
[ -n "${IPFS_PEERING_PEERS}" ] && ipfs config --json Peering.Peers "${IPFS_PEERING_PEERS}"

## reproviding local content to routing system
[ -n "${IPFS_REPROVIDER_INTERVAL}" ] && ipfs config Reprovider.Interval "${IPFS_REPROVIDER_INTERVAL}"
[ -n "${IPFS_REPROVIDER_STRATEGY}" ] && ipfs config Reprovider.Strategy "${IPFS_REPROVIDER_STRATEGY}"

## routing
[ -n "${IPFS_ROUTING_TYPE}" ] && ipfs config Routing.Type "${IPFS_ROUTING_TYPE}"
[ -n "${IPFS_ROUTING_ACCELERATEDDHTCLIENT}" ] && ipfs config --json Routing.AcceleratedDHTClient "${IPFS_ROUTING_ACCELERATEDDHTCLIENT}"
[ -n "${IPFS_ROUTING_LOOPBACKADDRESSESONLANDHT}" ] && ipfs config --bool Routing.LoopbackAddressesOnLanDHT "${IPFS_ROUTING_LOOPBACKADDRESSESONLANDHT}"
[ -n "${IPFS_ROUTING_METHODS}" ] && ipfs config --json Routing.Methods "${IPFS_ROUTING_METHODS}"
[ -n "${IPFS_ROUTING_ROUTERS}" ] && ipfs config --json Routing.Routers "${IPFS_ROUTING_ROUTERS}"

## swarm config
[ -n "${IPFS_SWARM_ADDRFILTERS}" ] 				&& ipfs config --json Swarm.AddrFilters "${IPFS_SWARM_ADDRFILTERS}"
[ -n "${IPFS_DOCKER_NETWORK}" ] 				&& ipfs config --json Swarm.AddrFilters "$(ipfs config Swarm.AddrFilters |sed '/${IPFS_DOCKER_NETWORK}"/d')"
[ -n "${IPFS_SWARM_DISABLEBANDWIDTHMETRICS}" ]			&& ipfs config --bool Swarm.DisableBandwidthMetrics "${SWARM_DISABLEBANDWIDTHMETRICS}"
[ -n "${IPFS_SWARM_DISABLENATPORTMAP}" ] 			&& ipfs config --bool Swarm.DisableNatPortMap "${SWARM_DISABLENATPORTMAP}"
[ -n "${IPFS_SWARM_ENABLEHOLEPUNCHING}" ] 			&& ipfs config --json Swarm.EnableHolePunching "${SWARM_ENABLEHOLEPUNCHING}"
[ -n "${IPFS_SWARM_RELAYCLIENT_ENABLED}" ] 			&& ipfs config --json Swarm.RelayClient.Enabled "${SWARM_RELAYCLIENT_ENABLED}"
[ -n "${IPFS_SWARM_RELAYCLIENT_STATICRELAYS}" ] 		&& ipfs config --json Swarm.RelayClient.StaticRelays "${SWARM_RELAYCLIENT_STATICRELAYS}"
[ -n "${IPFS_SWARM_RELAYSERVICE_ENABLED}" ] 			&& ipfs config --json Swarm.RelayService.Enabled "${SWARM_RELAYSERVICE_ENABLED}"
[ -n "${IPFS_SWARM_RELAYSERVICE_LIMIT}" ] 			&& ipfs config --json Swarm.RelayService.Limit "${SWARM_RELAYSERVICE_LIMIT}"
[ -n "${IPFS_SWARM_RELAYSERVICE_CONNECTIONDURATIONLIMIT}" ] 	&& ipfs config Swarm.RelayService.ConnectionDurationLimit "${SWARM_RELAYSERVICE_CONNECTIONDURATIONLIMIT}"
[ -n "${IPFS_SWARM_RELAYSERVICE_CONNECTIONDATALIMIT}" ] 	&& ipfs config Swarm.RelayService.ConnectionDataLimit "${SWARM_RELAYSERVICE_CONNECTIONDATALIMIT}"
[ -n "${IPFS_SWARM_RELAYSERVICE_RESERVATIONTTL}" ] 		&& ipfs config Swarm.RelayService.ConnectionDataLimit "${SWARM_RELAYSERVICE_RESERVATIONTTL}"
[ -n "${IPFS_SWARM_RELAYSERVICE_MAXRESERVATIONS}" ] 		&& ipfs config Swarm.RelayService.MaxReservations "${SWARM_RELAYSERVICE_MAXRESERVATIONS}"
[ -n "${IPFS_SWARM_RELAYSERVICE_MAXCIRCUITS}" ] 		&& ipfs config Swarm.RelayService.MaxCircuits "${SWARM_RELAYSERVICE_MAXCIRCUITS}"
[ -n "${IPFS_SWARM_RELAYSERVICE_BUFFERSIZE}" ]			&& ipfs config Swarm.RelayService.BufferSize "${SWARM_RELAYSERVICE_BUFFERSIZE}"
[ -n "${IPFS_SWARM_RELAYSERVICE_MAXRESERVATIONSPERASN}" ] 	&& ipfs config Swarm.RelayService.MaxReservationsPerASN "${SWARM_RELAYSERVICE_MAXRESERVATIONSPERASN}"
[ -n "${IPFS_SWARM_RELAYSERVICE_MAXRESERVATIONSPERIP}" ] 	&& ipfs config Swarm.RelayService.MaxReservationsPerIp "${SWARM_RELAYSERVICE_MAXRESERVATIONSPERIP}"
[ -n "${IPFS_SWARM_CONNMGR_TYPE}" ] 				&& ipfs config Swarm.ConnMgr.Type "${IPFS_SWARM_CONNMGR_TYPE}"
[ -n "${IPFS_SWARM_CONNMGR_HIGHWATER}" ] 			&& ipfs config Swarm.ConnMgr.HighWater "${IPFS_SWARM_CONNMGR_HIGHWATER}"
[ -n "${IPFS_SWARM_CONNMGR_LOWWATER}" ] 			&& ipfs config Swarm.ConnMgr.LowWater "${IPFS_SWARM_CONNMGR_LOWWATER}"
[ -n "${IPFS_SWARM_CONNMGR_GRACEPERIOD}" ] 			&& ipfs config Swarm.ConnMgr.GracePeriod "${IPFS_SWARM_CONNMGR_GRACEPERIOD}"
[ -n "${IPFS_SWARM_RESOURCEMGR_ENABLED}" ] 			&& ipfs config --json Swarm.ResourceMgr.Enabled "${IPFS_SWARM_RESOURCEMGR_ENABLED}"
[ -n "${IPFS_SWARM_RESOURCEMGR_MAXMEMORY}" ] 			&& ipfs config Swarm.ResourceMgr.MaxMemory "${IPFS_SWARM_RESOURCEMGR_MAXMEMORY}"
[ -n "${IPFS_SWARM_RESOURCEMGR_MAXFILEDESCRIPTORS}" ] 		&& ipfs config Swarm.ResourceMgr.MaxFileDescriptors "${IPFS_SWARM_RESOURCEMGR_MAXFILEDESCRIPTORS}"
[ -n "${IPFS_SWARM_RESOURCEMGR_ALLOWLIST}" ] 			&& ipfs config --json Swarm.ResourceMgr.Allowlist "${IPFS_SWARM_RESOURCEMGR_ALLOWLIST}"

## swarm transports
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_TCP}" ] 			&& ipfs config --json Swarm.Transports.Network.TCP "${SWARM_TRANSPORTS_NETWORK_TCP}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_WEBSOCKET}" ] 		&& ipfs config --json Swarm.Transports.Network.Websocket "${SWARM_TRANSPORTS_NETWORK_WEBSOCKET}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_QUIC}" ]			&& ipfs config --json Swarm.Transports.Network.QUIC "${SWARM_TRANSPORTS_NETWORK_QUIC}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_RELAY}" ] 		&& ipfs config --json Swarm.Transports.Network.Relay "${SWARM_TRANSPORTS_NETWORK_RELAY}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_WEBTRANSPORT}" ]		&& ipfs config --json Swarm.Transports.Network.WebTransport "${SWARM_TRANSPORTS_NETWORK_WEBTRANSPORT}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_WEBRTCDIRECT}" ]		&& ipfs config --json Swarm.Transports.Network.WebRTCDirect "${SWARM_TRANSPORTS_NETWORK_WEBRTCDIRECT}"
[ -n "${IPFS_SWARM_TRANSPORTS_NETWORK_WEBRTCDIRECT}" ]		&& ipfs config --json Swarm.Transports.Network.WebRTCDirect "${SWARM_TRANSPORTS_NETWORK_WEBRTCDIRECT}"
[ -n "${IPFS_SWARM_TRANSPORTS_SECURITY_TLS}" ]			&& ipfs config Swarm.Transports.Security.TLS "${SWARM_TRANSPORTS_SECURITY_TLS}"
[ -n "${IPFS_SWARM_TRANSPORTS_SECURITY_NOISE}" ] 		&& ipfs config Swarm.Transports.Security.Noise "${SWARM_TRANSPORTS_SECURITY_NOISE}"
[ -n "${IPFS_SWARM_TRANSPORTS_MULTIPLEXERS_YAMUX}" ] 		&& ipfs config Swarm.Transports.Multiplexers.Yamux "${SWARM_TRANSPORTS_MULTIPLEXERS_YAMUX}"

## dns
[ -n "${IPFS_DNS_RESOLVERS}" ]		&& ipfs config --json DNS.Resolvers "${IPFS_DNS_RESOLVERS}"
[ -n "${IPFS_DNS_MAXCACHETTL}" ]	&& ipfs config DNS.MaxCacheTTL "${IPFS_DNS_MAXCACHETTL}"

## experimental features
[ -n "${IPFS_EXPERIMENTAL_FILESTOREENABLED}" ]		&& ipfs config --json Experimental.FilestoreEnabled "${IPFS_EXPERIMENTAL_FILESTOREENABLED}"
[ -n "${IPFS_EXPERIMENTAL_URLSTOREENABLED}" ]		&& ipfs config --json Experimental.UrlstoreEnabled "${IPFS_EXPERIMENTAL_URLSTOREENABLED}"
[ -n "${IPFS_EXPERIMENTAL_URLSTORE}" ]			&& ipfs urlstore add "${IPFS_EXPERIMENTAL_URLSTORE}"
[ -n "${IPFS_EXPERIMENTAL_LIBP2PSTREAMMOUNTING}" ]	&& ipfs config --json Experimental.Libp2pStreamMounting "${IPFS_EXPERIMENTAL_LIBP2PSTREAMMOUNTING}"
[ -n "${IPFS_EXPERIMENTAL_P2PHTTPPROXY}" ]		&& ipfs config --json Experimental.P2pHttpProxy "${IPFS_EXPERIMENTAL_P2PHTTPPROXY}"
[ -n "${IPFS_EXPERIMENTAL_STRATEGICPROVIDING}" ]	&& ipfs config --json Experimental.StrategicProviding "${IPFS_EXPERIMENTAL_STRATEGICPROVIDING}"
[ -n "${IPFS_EXPERIMENTAL_OPTIMISTICPROVIDE}" ]		&& ipfs config --json Experimental.OptimisticProvide "${IPFS_EXPERIMENTAL_OPTIMISTICPROVIDE}"
[ -n "${IPFS_EXPERIMENTAL_GATEWAYOVERLIBP2P}" ]		&& ipfs config --json Experimental.GatewayOverLibp2p "${IPFS_EXPERIMENTAL_GATEWAYOVERLIBP2P}"

## REMOVE IPFS BOOTSTRAP for private usage
[ ${IPFS_NETWORK:-public} = "public" ]  || ipfs bootstrap rm --all
[ ${IPFS_NETWORK:-public} = "private" ] && export LIBP2P_FORCE_PNET=1 ||:

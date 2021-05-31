SETUP_NFSD                      ?= false
SETUP_NFSD_OSX_CONFIG           ?= nfs.server.bonjour=0 nfs.server.mount.regular_files=1 nfs.server.mount.require_resv_port=0 nfs.server.nfsd_threads=16 nfs.server.async=1
SETUP_SYSCTL                    ?= false
SETUP_SYSCTL_CONFIG             ?= vm.max_map_count=262144 vm.overcommit_memory=1 fs.file-max=8388608 net.core.somaxconn=1024

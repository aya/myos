#shellcheck shell=sh
# myos_cert_names normally reads the compose configuration; here it is replaced
# by a fixed list so the grouping can be checked on its own.
MYOS_CERT_MODE=$1
_fixture=${2-'urlprefix-ipfs.ex.org/*
urlprefix-*.ipns.ex.org/*
urlprefix-a.ipns.ex.org/*
urlprefix-ex.org/*'}
myos_cert_names() { printf '%s' "$_fixture" | myos_cert_parse; }
myos_cert_groups

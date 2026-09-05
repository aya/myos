#shellcheck shell=sh
MYOS_CERT_MODE=$1
myos_cert_names() { printf 'urlprefix-*.ipns.ex.org/*\nurlprefix-a.ex.org/*\n' | myos_cert_parse; }
myos_cert_needs_dns && echo yes || echo no

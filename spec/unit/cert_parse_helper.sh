#shellcheck shell=sh
printf 'urlprefix-ipfs.ex.org/api/*\nurlprefix-*.ipns.ex.org/*\nurlprefix-ex.org:443/* proto=https\nurlprefix-*/*\n' | myos_cert_parse

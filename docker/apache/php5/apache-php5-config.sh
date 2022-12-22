#!/bin/sh
set -eu

DOCUMENT_ROOT=${DOCUMENT_ROOT:-/web/html}
LOAD_MODULE=${LOAD_MODULE:-env expires headers remoteip reqtimeout rewrite setenvif slotmem_shm vhost_alias}
PREFIX=${PREFIX:-/web/config}
SERVER_NAME=${SERVER_NAME:-$(hostname)}
VIRTUAL_ROOT=${VIRTUAL_ROOT:-%0}

sed -E -i \
  -e 's!^#?\s*(LoadModule ('${LOAD_MODULE// /|}')_module modules/mod_('${LOAD_MODULE// /|}').so)\s*!\1!g' \
  -e 's!^ServerName .*!ServerName '${SERVER_NAME}'!g' \
  -e 's!^ServerSignature .*!ServerSignature Off!g' \
  -e 's!DocumentRoot .*!DocumentRoot "'${DOCUMENT_ROOT}'"!; /DocumentRoot/,/Directory/{s!Directory .*"!Directory "'${DOCUMENT_ROOT}'"!}' \
  "$PREFIX/httpd.conf"
sed -ni \
  -e '/^VirtualDocumentRoot/!p;$a VirtualDocumentRoot '"${DOCUMENT_ROOT}/${VIRTUAL_ROOT:-%-1/%-2/%-3}"'' \
  "$PREFIX/conf.d/default.conf"
sed -i \
  -e 's!internal!localhost!g' \
  -e 's!^Alias .*!Alias "/localhost" "'${DOCUMENT_ROOT}'/localhost"!g; /Alias/,/Directory/{s!Directory .*"!Directory "'${DOCUMENT_ROOT}/localhost'"!}' \
  "$PREFIX/conf.d/errordocs.conf"

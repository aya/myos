#!/bin/sh
set -eu

TZ="${TZ:-UTC}"
printf "%s\n" "${TZ}" > /etc/timezone
unlink /etc/localtime && ln -s "/usr/share/zoneinfo/${TZ}" /etc/localtime

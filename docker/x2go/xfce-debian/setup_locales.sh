#!/bin/sh
[ -n "${DEBUG}" ] && set -x
set -eu

LANG=${LANG:-C.UTF-8}
LOCALES=${LOCALES:-${LANG} ${LANG##*.}}
printf "LANG=%s\n" "${LANG}" > /etc/default/locale
rm /etc/locale.gen && printf "%s\n" "${LOCALES}" |while read -r locale; do
  printf "%s\n" "${locale}" >> /etc/locale.gen
done && locale-gen

#!/bin/sh
# Print the golden cases of the catalogue fixture (spec/fixtures/catalogue =
# myos-stacks@7289b83, the last state readable by make). Appended to cases.txt
# by hand when the fixture changes:  spec/golden/cases-catalogue.sh > spec/golden/cases.catalogue.txt
cd "$(dirname "$0")/../fixtures/catalogue/stack" || exit 1
ref() { # path of a .mk or .yml -> stack reference
  r=${1%.*}
  case $r in */*) [ "${r%/*}" = "${r#*/}" ] && r=${r%/*} ;; esac
  printf '%s' "$r"
}
slug() { printf '%s' "$1" | tr '/' '-' | tr '[:upper:]' '[:lower:]'; }
find . -name '*.mk' | sed 's#^\./##' | sort | while read -r mk; do
  # ENV_VARS and MAKECMDARGS are the plumbing of make, not settings
  vars=$(grep -oE '^[A-Z][A-Z0-9_]* *[?:+]?=' "$mk" | sed 's/ *[?:+]*=$//' | grep -v -e '^ENV_VARS$' -e '^MAKECMDARGS$' | sort -u | tr '\n' ' ')
  [ -z "$vars" ] && continue
  case $mk in */*) r=$(ref "$mk") ;; *) r=${mk%.mk} ;; esac
  d=${mk%/*}; b=${mk##*/}; b=${b%.mk}
  if [ "$mk" != "${mk#*/}" ] && [ ! -f "$d/$b.yml" ] && [ "$b" != "$d" ]; then
    # apache.php5.mk -> host/apache/php5 ; woodpecker.mk -> the group woodpecker ; exporter.mk -> host/exporter
    if [ -f "$d/$(printf '%s' "$b" | tr . /).yml" ]; then r=$d/$(printf '%s' "$b" | tr . /)
    elif grep -qE "^[a-z][a-z0-9_-]*[[:space:]]*[?:]*=" "$mk"; then r=$(grep -oE "^[a-z][a-z0-9_-]*[[:space:]]*[?:]*=" "$mk" | head -1 | sed "s/[[:space:]]*[?:]*=//")
    elif [ -d "$d/$b" ]; then r=$d/$b; fi
  fi
  pin=
  # supabase derives its tokens from the current time: pin it
  case $r in supabase) pin=' SUPABASE_JWT_IAT=1700000000' ;; esac
  printf '%-40s | catalogue | %sSTACK=%s%s\n' "catalogue-$(slug "$r")-vars" "$(printf 'print-%s ' $vars)" "$r" "$pin"
done
find . -name '*.yml' | sed 's#^\./##' | grep -E '^[^/]+/[^/.]+\.yml$' | sort | while read -r yml; do
  r=$(ref "$yml")
  printf '%-40s | catalogue | print-COMPOSE_FILE print-COMPOSE_PROJECT_NAME STACK=%s\n' "catalogue-$(slug "$r")-files" "$r"
done
for g in default develop logs monitoring testing; do
  printf '%-40s | catalogue | up STACK=%s\n' "catalogue-group-$g-up" "$g"
done

#!/bin/sh
# bench.sh LABEL N -- CMD...  run CMD N times, print the median wall time in ms
# Hermetic: docker is the mock of spec/support/bin, config comes from the
# environment only, HOME points at the fixture catalogue.
set -u
label=$1; n=$2; shift 2; [ "$1" = "--" ] && shift
i=0; times=""
while [ "$i" -lt "$n" ]; do
  s=$(python3 -c 'import time;print(int(time.time()*1e6))')
  "$@" >/dev/null 2>&1
  e=$(python3 -c 'import time;print(int(time.time()*1e6))')
  times="$times $(( (e - s) / 1000 ))"
  i=$((i + 1))
done
median=$(printf '%s\n' $times | sort -n | awk '{a[NR]=$1} END {print a[int((NR+1)/2)]}')
printf '%-44s %6s ms   (runs:%s)\n' "$label" "$median" "$times"

#!/bin/sh
# bench.sh LABEL N -- CMD...  run CMD N times, print the median wall time in ms
label=$1; n=$2; shift 2; [ "$1" = "--" ] && shift
python3 - "$label" "$n" "$@" <<'PY'
import subprocess, sys, time, statistics
label, n, cmd = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
times = []
for _ in range(n):
    s = time.perf_counter(); subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); times.append(int((time.perf_counter() - s) * 1000))
print("%-44s %6d ms   (runs: %s)" % (label, statistics.median(times), " ".join(map(str, times))))
PY

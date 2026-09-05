#!/bin/sh
# the benchmark: the engine on the catalogue fixture, 5 runs each, median
MYOS_ROOT=${MYOS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd -P)}; export MYOS_ROOT
. "$(dirname "$0")/env.sh"
rm -rf /tmp/myos-bench; mkdir -p /tmp/myos-bench/home/.local/share/myos
cp -R "$MYOS_ROOT/spec/fixtures/catalogue" /tmp/myos-bench/wd
cp -R "$MYOS_ROOT/spec/fixtures/home/.local/share/myos/stack" /tmp/myos-bench/home/.local/share/myos/stack
cd "$WORKDIR" || exit 1
B=$MYOS_ROOT/spec/bench/bench.sh; N=5; M=$MYOS_ROOT/myos
echo "== fixed cost"
$B "myos --version" $N -- $M --version
$B "myos print-STACK_DIR (path only)" $N -- $M print-STACK_DIR host/consul
echo "== up, dry run: 1 stack, the host group (3), the group with settings (host: 80 settings)"
$B "up host/consul" $N -- $M up host/consul
$B "up host" $N -- $M up host
$B "up default (memcached mysql rabbitmq redis)" $N -- $M up default
echo "== the settings: every exported value of the host group"
$B "env host" $N -- $M env host
$B "print-HOST_FABIO_SERVICE_9998_TAGS" $N -- $M print-HOST_FABIO_SERVICE_9998_TAGS host/fabio
echo "== lifecycle, against the mock"
DRYRUN=false MOCK_VOLUMES="tester-app-local_data" MYOS_BACKUP_ROOT=/tmp/myos-bench/backup $B "status host" $N -- $M status host

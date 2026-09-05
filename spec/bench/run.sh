#!/bin/sh
# the full matrix: 5 runs each, median, every engine on the same work
. /tmp/myos-bench/env.sh; cd "$WORKDIR"
B=/tmp/myos-bench/bench.sh; N=5
MK="make -esC $MYOS_ROOT MYOS=. WORKDIR=$WORKDIR"
SH="$MYOS_ROOT/bin/myos"
JU="just --justfile /tmp/myos-bench/justfile"
GO=/tmp/myos-bench/myos-go
S1="host/consul"; S2="host/consul host/fabio"; S3="host/consul host/fabio host/registrator"

echo "== cout fixe : demarrage + cible vide"
$B "make  noop" $N -- $MK FORCE
$B "sh    noop (myos version)" $N -- $SH version
$B "just  noop (parse + 1 sh + source lib/)" $N -- $JU noop
$B "go    noop" $N -- $GO noop
echo
echo "== up : 1 / 2 / 3 stacks, dry-run"
$B "make  up 1" $N -- $MK up STACK="$S1"
$B "make  up 2" $N -- $MK up STACK="$S2"
$B "make  up 3" $N -- $MK up STACK="$S3"
$B "sh    up 1" $N -- $SH up host/consul
$B "sh    up 2" $N -- $SH up host/consul host/fabio
$B "sh    up 3" $N -- $SH up host/consul host/fabio host/registrator
$B "just  up 1" $N -- $JU up host/consul
$B "just  up 2" $N -- $JU up host/consul host/fabio
$B "just  up 3" $N -- $JU up host/consul host/fabio host/registrator
$B "go    up 1" $N -- $GO up host/consul
$B "go    up 2" $N -- $GO up host/consul host/fabio
$B "go    up 3" $N -- $GO up host/consul host/fabio host/registrator
echo
echo "== export : les 80 reglages du groupe host (evaluation des hooks shell)"
$B "sh    export, hooks tels quels" $N -- $SH export STACK=host
$B "just  export, hooks tels quels" $N -- $JU export host
$B "go    export, hooks tels quels (1 sh/repertoire)" $N -- $GO export host
echo
echo "== export : memes hooks, evalues en une passe (MYOS_VAR_MEMO=1)"
MYOS_VAR_MEMO=1 $B "sh    export, memoise" $N -- $SH export STACK=host
MYOS_VAR_MEMO=1 $B "just  export, memoise" $N -- $JU export host
MYOS_VAR_MEMO=1 $B "go    export, memoise" $N -- $GO export host

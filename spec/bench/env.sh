# the hermetic environment of the benchmark (sourced by run.sh and profile.sh,
# which set MYOS_ROOT first)
: "${MYOS_ROOT:?MYOS_ROOT must name the myos checkout}"
export PATH=$MYOS_ROOT/spec/support/bin:/usr/bin:/bin
export HOME=/tmp/myos-bench/home WORKDIR=/tmp/myos-bench/wd
export USER=tester HOSTNAME=testhost DOMAIN=example.test ENV=local DRYRUN=true
export MYOS_CONF=/dev/null MYOS_PROJECT_FORMAT=user-app-env

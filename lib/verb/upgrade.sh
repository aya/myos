#shellcheck shell=sh
# upgrade: bring the project to the latest images and code, safely.
# lock, backup (MYOS_UPGRADE_BACKUP=false skips it), git pull --ff-only in
# the stack directories that are checkouts, compose pull, compose build
# --pull when a service is built, compose up -d, then wait for every
# service to be running and healthy (MYOS_HEALTH_TIMEOUT seconds).

myos_verb_upgrade() {
  myos_lock
  myos_verb_with_hooks upgrade myos_upgrade_default; _ug_rc=$?
  myos_unlock
  return $_ug_rc
}

myos_upgrade_default() {
  [ "${MYOS_UPGRADE_BACKUP:-true}" = false ] || { myos_verb_backup || return 1; }
  _ug_ifs=$IFS; IFS=$NL; set -f
  for _ug_d in $MYOS_STACK_DIRS; do
    IFS=$_ug_ifs; set +f
    if [ -d "$_ug_d/.git" ]; then
      if myos_run git -C "$_ug_d" pull --ff-only --quiet; then myos_event pull "$_ug_d" ok; else myos_event pull "$_ug_d" fail; return 1; fi
    fi
    IFS=$NL; set -f
  done
  IFS=$_ug_ifs; set +f
  myos_compose pull || return 1
  # shellcheck disable=SC2086
  if grep -qs -E '^[[:space:]]+build:' $MYOS_STACK_FILES; then myos_compose build --pull || return 1; fi
  myos_compose up -d || return 1
  [ "$MYOS_DRYRUN" = true ] || myos_wait_healthy
}

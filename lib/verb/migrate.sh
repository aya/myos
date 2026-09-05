#shellcheck shell=sh
# migrate pin: before a deployment made with the make engine runs on this
# version, pin what would otherwise change: the project name format
# (MYOS_PROJECT_FORMAT=user-app-env keeps <user>-<app>-<env>), written into
# $WORKDIR/.env when it is not set yet. Idempotent.
myos_verb_migrate() {
  case ${MYOS_SUB:-pin} in
    pin)
      myos_env_file; _mg_env=$R
      if myos_env_has MYOS_PROJECT_FORMAT "$_mg_env"; then myos_event pin "$_mg_env" skip "MYOS_PROJECT_FORMAT already set"; return 0; fi
      if [ "$MYOS_DRYRUN" = true ]; then printf 'echo MYOS_PROJECT_FORMAT=user-app-env >> %s\n' "$_mg_env"; return 0; fi
      ( umask 077; printf 'MYOS_PROJECT_FORMAT=user-app-env\n' >> "$_mg_env" ) || return 1
      myos_event pin "$_mg_env" ok "MYOS_PROJECT_FORMAT=user-app-env" ;;
    *) myos_die 2 "migrate: unknown step ${MYOS_SUB} (pin)" ;;
  esac
}

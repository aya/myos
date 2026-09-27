#shellcheck shell=sh
# restore --from DIR|latest: the volumes of the project replaced from a
# backup. Guards: --from is mandatory, the manifest must name this project
# (--force otherwise, and the volumes of that project are then restored into
# those of this one), a safety backup is taken first (--no-backup), and a
# non-interactive run needs --yes. Steps: pre-restore hooks, down, one
# volume at a time (created when missing), up, post-restore hooks.

myos_verb_restore() {
  [ -n "${MYOS_FROM:-}" ] || myos_die 2 "restore needs --from DIR or --from latest"
  if [ "$MYOS_FROM" = latest ]; then
    myos_backup_root; MYOS_FROM=$(ls -1d "$R"/* 2>/dev/null | LC_ALL=C sort | tail -n1)
    [ -n "$MYOS_FROM" ] || myos_die 1 "no backup of $MYOS_PROJECT under $R"
  fi
  [ -f "$MYOS_FROM/manifest.json" ] || myos_die 1 "$MYOS_FROM: no manifest.json"
  _rs_project=$(sed -n 's/.*"project": *"\([^"]*\)".*/\1/p' "$MYOS_FROM/manifest.json" | head -n1)
  if [ "$_rs_project" != "$MYOS_PROJECT" ] && [ -z "${MYOS_FORCE:-}" ]; then
    myos_die 1 "$MYOS_FROM is a backup of project $_rs_project, not $MYOS_PROJECT (--force to restore it anyway)"
  fi
  if [ -z "${MYOS_YES:-}" ] && ! [ -t 0 ]; then myos_die 2 "restore replaces the volumes of $MYOS_PROJECT: run it with --yes"; fi
  if [ -z "${MYOS_YES:-}" ]; then
    printf 'restore %s from %s? [y/N] ' "$MYOS_PROJECT" "$MYOS_FROM"; read -r _rs_a; [ "$_rs_a" = y ] || myos_die 1 "aborted"
  fi
  if [ -z "${MYOS_NO_BACKUP:-}" ]; then _rs_from=$MYOS_FROM; myos_verb_backup || return 1; MYOS_FROM=$_rs_from; fi
  MYOS_BACKUP_DIR=$MYOS_FROM; MYOS_RESTORE_PROJECT=$_rs_project; export MYOS_BACKUP_DIR MYOS_RESTORE_PROJECT
  myos_verb_with_hooks restore myos_restore_default
}

myos_restore_default() {
  myos_compose down || return 1
  myos_volumes; _rd_have=$R
  _rd_vols=$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$MYOS_FROM/manifest.json")
  _rd_ifs=$IFS; IFS=$NL; set -f
  # a backup of another project (--force) lands in the volumes of this one:
  # <source>_<name> is restored into <project>_<name>, never into the volume
  # of the source, which may be running
  _rd_src=${MYOS_RESTORE_PROJECT:-$MYOS_PROJECT}
  for _rd_v in $_rd_vols; do
    IFS=$_rd_ifs; set +f
    [ -f "$MYOS_FROM/$_rd_v.tar.gz" ] || { myos_event volume "$_rd_v" fail "no archive"; IFS=$_rd_ifs; return 1; }
    case $_rd_v in
      "${_rd_src}_"*) _rd_t=$MYOS_PROJECT${_rd_v#"$_rd_src"} ;;
      *) [ "$_rd_src" = "$MYOS_PROJECT" ] || { myos_event volume "$_rd_v" fail "not a volume of $_rd_src"; IFS=$_rd_ifs; return 1; }
         _rd_t=$_rd_v ;;
    esac
    case "$NL$_rd_have$NL" in *"$NL$_rd_t$NL"*) ;; *) myos_run docker volume create "$_rd_t" >/dev/null || return 1 ;; esac
    myos_run docker run --rm -v "$_rd_t:/v" -v "$MYOS_FROM:/b:ro" alpine sh -c "rm -rf /v/..?* /v/.[!.]* /v/* 2>/dev/null; tar xzf /b/$_rd_v.tar.gz -C /v" || { myos_event volume "$_rd_t" fail; IFS=$_rd_ifs; return 1; }
    myos_event volume "$_rd_t" ok
    IFS=$NL; set -f
  done
  IFS=$_rd_ifs; set +f
  myos_compose up -d
}

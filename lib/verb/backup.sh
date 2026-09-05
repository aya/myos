#shellcheck shell=sh
# backup: the volumes of the project archived into
# $MYOS_BACKUP_ROOT/<project>/<date>/ with the .env and a manifest.
# Steps: pre-backup hooks (a database stack dumps itself there), then one
# tar per volume through a throwaway container, the .env (owner only), the
# manifest, the post-backup hooks, the pruning of old backups (--keep N).

myos_sha256() { R=$( (sha256sum "$1" 2>/dev/null || shasum -a 256 "$1" 2>/dev/null || openssl dgst -r -sha256 "$1" 2>/dev/null) | cut -d' ' -f1); }
myos_backup_root() { R=${MYOS_BACKUP_ROOT:-$MYOS_WORKDIR/backup}/$MYOS_PROJECT; }
myos_volumes() { # -> R: NL list of the volumes of the project
  if [ "$MYOS_DRYRUN" = true ]; then R=; return 0; fi
  R=$(docker volume ls --filter "label=com.docker.compose.project=$MYOS_PROJECT" --format '{{.Name}}' 2>/dev/null)
}

myos_verb_backup() {
  myos_backup_root; MYOS_BACKUP_DIR=$R/${MYOS_NOW:-$(date +%Y%m%d-%H%M%S)}; export MYOS_BACKUP_DIR
  mkdir -p "$MYOS_BACKUP_DIR" || return 1
  myos_verb_with_hooks backup myos_backup_default || return 1
  MYOS_ARTIFACTS="${MYOS_ARTIFACTS:+$MYOS_ARTIFACTS }$MYOS_BACKUP_DIR"
  [ -n "${MYOS_KEEP:-}" ] && myos_backup_prune "$MYOS_KEEP"
  return 0
}

myos_backup_default() {
  [ -n "${MYOS_PAUSE:-}" ] && { myos_compose pause || return 1; }
  myos_volumes; _bk_vols=$R; _bk_items=; _bk_rc=0
  _bk_ifs=$IFS; IFS=$NL; set -f
  for _bk_v in $_bk_vols; do
    IFS=$_bk_ifs; set +f
    if myos_run docker run --rm -v "$_bk_v:/v:ro" -v "$MYOS_BACKUP_DIR:/b" alpine tar czf "/b/$_bk_v.tar.gz" -C /v . ; then
      myos_event volume "$_bk_v" ok
      _bk_size=$(wc -c < "$MYOS_BACKUP_DIR/$_bk_v.tar.gz" 2>/dev/null | tr -d ' '); myos_sha256 "$MYOS_BACKUP_DIR/$_bk_v.tar.gz"
      _bk_items="$_bk_items${_bk_items:+,}$NL    {\"name\": \"$_bk_v\", \"size\": ${_bk_size:-0}, \"sha256\": \"$R\"}"
    else
      myos_event volume "$_bk_v" fail; _bk_rc=1
    fi
    IFS=$NL; set -f
  done
  IFS=$_bk_ifs; set +f
  [ -n "${MYOS_PAUSE:-}" ] && myos_compose unpause
  [ "$_bk_rc" -eq 0 ] || return 1
  myos_env_file; [ -f "$R" ] && { ( umask 077; cp "$R" "$MYOS_BACKUP_DIR/.env" ); myos_event env "$MYOS_BACKUP_DIR/.env" ok; }
  myos_nl_join "$MYOS_STACK_FILES" '", "'; _bk_files=$R
  {
    printf '{\n  "project": "%s",\n  "stack": "%s",\n  "env": "%s",\n  "created": "%s",\n  "myos": "%s",\n' "$MYOS_PROJECT" "$MYOS_STACK" "$MYOS_ENV" "${MYOS_NOW:-$(date +%Y%m%d-%H%M%S)}" "$MYOS_VERSION"
    printf '  "files": ["%s"],\n  "volumes": [%s\n  ]\n}\n' "$_bk_files" "$_bk_items"
  } > "$MYOS_BACKUP_DIR/manifest.json"
  myos_event manifest "$MYOS_BACKUP_DIR/manifest.json" ok
}

myos_backup_prune() { # KEEP: remove the oldest backups beyond KEEP
  myos_backup_root; _bp_root=$R
  ls -1d "$_bp_root"/* 2>/dev/null | LC_ALL=C sort | head -n "-$1" 2>/dev/null | while read -r _bp_d; do rm -rf "$_bp_d"; done
  return 0
}

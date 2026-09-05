#!/bin/sh
# main: parse the arguments, resolve the stacks, run the verbs.
# Grammar (the one of the make engine, so that every historical call works):
#   myos [options] VERB... [REF...] [KEY=VALUE...] [-- ARGS...]
#   print-NAME            the value of NAME
#   stack-<ref>-<verb>    <verb> on <ref>
#   STACK="a b"           references (a group, a stack, a path)
#   ENV= SERVICE= ARGS= NUM= and any KEY=VALUE become values of the run
# Options: -n dry run (DRYRUN=true), -C DIR work in DIR, --json, --strict,
#   --version, -h
set -u
MYOS=${MYOS:-$(cd "$(dirname "$0")/.." && pwd -P)}
MYOS_LIB=$MYOS/lib
for _m_m in core path ref files stack values settings fn env events hooks lock; do . "$MYOS_LIB/$_m_m.sh"; done
for _m_m in "$MYOS_LIB"/verb/*.sh; do . "$_m_m"; done

MYOS_VERSION=2.0.0-dev
MYOS_SETTINGS_LOADED=; MYOS_SET_NAMES=; MYOS_SET_EXPORT=; MYOS_MEMO_NAMES=; MYOS_DIST_LINES=; MYOS_ER_D=0
MYOS_VERBS="up down build config logs ps status restart start stop recreate connect exec run scale shutdown bootstrap install clean attach env-update backup restore upgrade doctor firewall cert ls env print"
MYOS_SUBS="audit apply list issue renew"
MYOS_DRYRUN=${DRYRUN:-false}
MYOS_OUTPUT=text; MYOS_STRICT=; MYOS_WORKDIR=${WORKDIR:-$PWD}
verbs=; refs=; MYOS_ARGS=; MYOS_IMAGE=; MYOS_BOOTSTRAP=; MYOS_YES=; MYOS_VERB=; _m_default_ref=.
MYOS_FORCE=; MYOS_PAUSE=; MYOS_NO_BACKUP=; MYOS_KEEP=; MYOS_FROM=; MYOS_ARTIFACTS=; MYOS_LOCKED=
MYOS_SUB=; MYOS_WILDCARD=; MYOS_SELF_SIGNED=; MYOS_CHECK=; MYOS_FIREWALL=${MYOS_FIREWALL:-}

while [ $# -gt 0 ]; do
  case $1 in
    --) shift; MYOS_ARGS="$*"; break ;;
    -n|--dry-run) MYOS_DRYRUN=true ;;
    -C) shift; MYOS_WORKDIR=$1 ;;
    --json) MYOS_OUTPUT=json ;;
    --strict) MYOS_STRICT=1 ;;
    --bootstrap) MYOS_BOOTSTRAP=1 ;;
    --yes|-y) MYOS_YES=1 ;;
    --force) MYOS_FORCE=1 ;;
    --pause) MYOS_PAUSE=1 ;;
    --no-backup) MYOS_NO_BACKUP=1 ;;
    --keep) shift; MYOS_KEEP=$1 ;;
    --keep=*) MYOS_KEEP=${1#--keep=} ;;
    --from) shift; MYOS_FROM=$1 ;;
    --from=*) MYOS_FROM=${1#--from=} ;;
    --wildcard) MYOS_WILDCARD=1 ;;
    --self-signed) MYOS_SELF_SIGNED=1 ;;
    --check) MYOS_CHECK=1 ;;
    --version) printf 'myos %s\n' "$MYOS_VERSION"; exit 0 ;;
    -h|--help) printf 'usage: myos [-n] [-C DIR] VERB... [REF...] [KEY=VALUE...] [-- ARGS...]\nverbs: %s\n' "$MYOS_VERBS"; exit 0 ;;
    -*) myos_die 2 "unknown option $1" ;;
    [A-Za-z_]*=*)
      _m_k=${1%%=*}; _m_v=${1#*=}
      case $_m_k in *[!A-Za-z0-9_]*) myos_die 2 "bad assignment $1" ;; esac
      case $_m_k in
        STACK) refs="${refs:+$refs }$_m_v" ;;
        ARGS) MYOS_ARGS=$_m_v ;;
        *) eval "MYOS_CLI_$_m_k=\$_m_v"; eval "$_m_k=\$_m_v"; export "$_m_k" ;;
      esac ;;
    print-*|context-*) verbs="${verbs:+$verbs }$1" ;;
    docker-build-*) verbs="${verbs:+$verbs }build"; MYOS_IMAGE="${MYOS_IMAGE:+$MYOS_IMAGE }${1#docker-build-}" ;;
    docker-build) verbs="${verbs:+$verbs }build" ;;
    .env-update) verbs="${verbs:+$verbs }env-update" ;;
    setup-ufw) verbs="${verbs:+$verbs }firewall"; MYOS_SUB=apply; MYOS_FIREWALL=${MYOS_FIREWALL:-ufw}; _m_default_ref=host ;;
    stack-*-*) verbs="${verbs:+$verbs }$1" ;;
    *)
      if myos_has "$1" "$MYOS_VERBS"; then verbs="${verbs:+$verbs }$1"
      elif myos_has "$1" "$MYOS_SUBS" && case " $verbs" in *" firewall"|*" cert") true ;; *) false ;; esac; then MYOS_SUB=$1
      else refs="${refs:+$refs }$1"; fi ;;
  esac
  shift
done
[ -n "$verbs" ] || myos_die 2 "unknown verb ${refs%% *} (myos -h lists the verbs)"
# SETUP_UFW=true (the old switch) asks for the ufw adapter
[ "${SETUP_UFW:-}" = true ] && MYOS_FIREWALL=${MYOS_FIREWALL:-ufw}
myos_realpath "$MYOS_WORKDIR" || :; [ -n "$R" ] && MYOS_WORKDIR=$R
MYOS_ENV=${ENV:-local}
MYOS_USER=${USER:-$(id -un)}
MYOS_HOSTNAME=${HOSTNAME:-$(hostname 2>/dev/null | sed 's/\..*//')}
myos_lower "$MYOS_HOSTNAME"; MYOS_HOSTNAME=$R
MYOS_DOMAIN=${DOMAIN:-localhost}
MYOS_SERVICE=${SERVICE:-}; MYOS_NUM=${NUM:-}
export MYOS MYOS_WORKDIR
myos_values_load

# the references: given, or the current directory. A reference names a
# compose project (make: APP_NAME = its first path segment); a group is
# expanded into its member stacks, whose files are merged into that project.
[ -n "$refs" ] || refs=$_m_default_ref
MYOS_REFS=$refs
myos_expand "$refs"; MYOS_STACKS=$R

# myos_project_of REF: resolve the members of REF into one project: sets the
# MYOS_STACK_* of the first member, MYOS_STACK_FILES to the union of the files
# of every member (framework overlays last), MYOS_PROJECT from REF
myos_project_of() {
  myos_expand "$1"; _po_members=$R
  _po_files=; _po_over=; _po_first=
  set -f
  for _po_ref in $_po_members; do
    set +f
    myos_stack_resolve "$_po_ref"
    _po_files="${_po_files:+$_po_files$NL}$MYOS_STACK_OWN"
    [ -n "$MYOS_STACK_OVERLAYS" ] && _po_over=$MYOS_STACK_OVERLAYS
    [ -n "$_po_first" ] || _po_first=$_po_ref
    set -f
  done
  set +f
  myos_stack_resolve "$_po_first"
  myos_nl_uniq "$_po_files"; MYOS_STACK_OWN=$R
  MYOS_STACK_OVERLAYS=$_po_over
  MYOS_STACK_FILES="$MYOS_STACK_OWN${MYOS_STACK_OVERLAYS:+$NL$MYOS_STACK_OVERLAYS}"
  # the project is named after the reference as given
  myos_ref_parse "$1"; MYOS_STACK_APP=$MYOS_REF_APP
  myos_scope "$1"; MYOS_STACK_SCOPE=$R
  case $MYOS_STACK_SCOPE in host) MYOS_STACK_SCOPE_PREFIX=HOST_ ;; user) MYOS_STACK_SCOPE_PREFIX=USER_ ;; *) MYOS_STACK_SCOPE_PREFIX= ;; esac
  myos_project_name "$MYOS_STACK_SCOPE" "$MYOS_STACK_APP"; MYOS_PROJECT=$R
  MYOS_NETWORK_DEFAULT=${DOCKER_NETWORK_DEFAULT:-_$MYOS_PROJECT}
  MYOS_STACK=$1
}

# myos_for_refs FN: run FN once per compose project of the references given
# (two references naming the same project are merged: one compose call)
myos_for_refs() {
  _fr_fn=$1; _fr_seen=
  set -f
  for _fr_ref in ${2:-$MYOS_REFS}; do
    set +f
    myos_project_of "$_fr_ref"
    myos_id "$MYOS_PROJECT"; _fr_id=$R
    case " $_fr_seen " in
      *" $MYOS_PROJECT "*) eval "_fr_files_$_fr_id=\"\$_fr_files_$_fr_id\$NL\$MYOS_STACK_OWN\""
                           [ -n "$MYOS_STACK_OVERLAYS" ] && eval "_fr_over_$_fr_id=\$MYOS_STACK_OVERLAYS" ;;
      *) _fr_seen="${_fr_seen:+$_fr_seen }$MYOS_PROJECT"
         eval "_fr_files_$_fr_id=\$MYOS_STACK_OWN; _fr_over_$_fr_id=\$MYOS_STACK_OVERLAYS; _fr_ref_$_fr_id=\$_fr_ref" ;;
    esac
    set -f
  done
  set +f
  for _fr_p in $_fr_seen; do
    myos_id "$_fr_p"; _fr_id=$R
    eval "myos_project_of \"\$_fr_ref_$_fr_id\"; MYOS_STACK_OWN=\$_fr_files_$_fr_id; MYOS_STACK_OVERLAYS=\$_fr_over_$_fr_id"
    myos_nl_uniq "$MYOS_STACK_OWN"; MYOS_STACK_OWN=$R
    MYOS_STACK_FILES="$MYOS_STACK_OWN${MYOS_STACK_OVERLAYS:+$NL$MYOS_STACK_OVERLAYS}"
    "$_fr_fn" || return $?
  done
}

# myos_stacks_merge: every reference as one list (what print-COMPOSE_FILE
# showed for several references), the first one naming the project
myos_stacks_merge() {
  _sm_files=; _sm_over=; _sm_first=
  set -f
  for _sm_ref in $MYOS_REFS; do
    set +f
    myos_project_of "$_sm_ref"
    _sm_files="${_sm_files:+$_sm_files$NL}$MYOS_STACK_OWN"
    [ -n "$MYOS_STACK_OVERLAYS" ] && _sm_over=$MYOS_STACK_OVERLAYS
    [ -n "$_sm_first" ] || _sm_first=$_sm_ref
    set -f
  done
  set +f
  myos_project_of "$_sm_first"
  myos_nl_uniq "$_sm_files"; MYOS_STACK_OWN=$R
  MYOS_STACK_OVERLAYS=$_sm_over
  MYOS_STACK_FILES="$MYOS_STACK_OWN${MYOS_STACK_OVERLAYS:+$NL$MYOS_STACK_OVERLAYS}"
}

rc=0
for verb in $verbs; do
  MYOS_VERB=$verb
  case $verb in
    env-update) myos_for_refs myos_verb_env_update || rc=$? ;;
    print-*|context-*) myos_stacks_merge; myos_verb_print "${verb#*-}" ;;
    stack-*-*)
      _m_v=${verb##*-}; _m_s=${verb#stack-}; _m_s=${_m_s%-*}
      myos_has "$_m_v" "$MYOS_VERBS" || myos_die 2 "unknown verb $_m_v in $verb"
      myos_for_refs "myos_verb_$_m_v" "$_m_s" || rc=$? ;;
    ls) myos_verb_ls ;;
    env) myos_stacks_merge; myos_env_vars; for _m_v in $R; do myos_var "$_m_v"; [ -n "$R" ] && printf '%s=%s\n' "$_m_v" "$R"; done ;;
    shutdown) # down of the singleton projects of this host and user
      _m_list=; for _m_g in host User; do myos_ref_parse "$_m_g"; myos_ref_dirs; myos_group_members "$_m_g"; { [ -n "$R" ] || [ -d "$MYOS_WORKDIR/stack/$_m_g" ]; } && _m_list="$_m_list $_m_g"; done
      [ -n "$_m_list" ] && { myos_for_refs myos_verb_down "$_m_list" || rc=$?; } ;;
    *) myos_for_refs "myos_verb_$verb" || rc=$? ;;
  esac
  [ "$rc" -eq 0 ] || break
done
if [ "$MYOS_OUTPUT" = json ]; then
  _m_art=; set -f; for _m_a in $MYOS_ARTIFACTS; do myos_json_str "$_m_a"; _m_art="$_m_art${_m_art:+,}$R"; done; set +f
  _m_status=ok; [ "$rc" -eq 0 ] || _m_status=fail
  printf '{"verb":"%s","status":"%s","exit":%s,"artifacts":[%s]}\n' "$MYOS_VERB" "$_m_status" "$rc" "$_m_art"
fi
exit "$rc"

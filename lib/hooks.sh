#shellcheck shell=sh
# hooks: what a stack (or the project) adds to a verb.
# For a phase P (pre-<verb>, <verb>, post-<verb>, on-fail-<verb>, doctor...),
# every stack directory then the project directory may hold a recipe P in a
# justfile, or an executable actions/P. The pre/post hooks of every directory
# run in order; a <verb> hook replaces the engine's default (the highest
# directory wins). A hook runs in its directory with the values of the run
# exported; it exits 0 (ok), 75 (skip me), or fails the verb.

myos_hook_env() { # export what a hook (or compose) sees
  export MYOS_VERB MYOS_STACK MYOS_STACK_NAME MYOS_STACK_SCOPE MYOS_PROJECT MYOS_ENV MYOS_WORKDIR MYOS_LIB MYOS_DRYRUN MYOS_OUTPUT
  MYOS_STACK_DIR=${MYOS_STACK_DIRS##*"$NL"}; export MYOS_STACK_DIR
  myos_nl_join "$MYOS_STACK_DIRS" ':'; MYOS_STACK_DIRS_PATH=$R; export MYOS_STACK_DIRS_PATH
  myos_nl_join "$MYOS_STACK_FILES" ':'; MYOS_COMPOSE_FILES=$R; export MYOS_COMPOSE_FILES
  myos_compose_cmd; MYOS_COMPOSE=$R; export MYOS_COMPOSE
  export MYOS_BACKUP_DIR="${MYOS_BACKUP_DIR:-}"
  myos_env_vars; set -f
  for _he_v in $R; do myos_var "$_he_v"; [ -n "$R" ] && { eval "$_he_v=\$R"; export "$_he_v"; }; done
  set +f
}

# myos_hook_dirs -> R: NL list of the directories that may hold hooks, ascending
myos_hook_dirs() { R="$MYOS_STACK_DIRS"; case "$NL$R$NL" in *"$NL$MYOS_WORKDIR$NL"*) ;; *) R="$R$NL$MYOS_WORKDIR" ;; esac; }

# myos_hook_find PHASE DIR -> R: "just" or "action" when DIR provides PHASE
myos_hook_find() {
  R=
  if [ -x "$2/actions/$1" ]; then R=action; return 0; fi
  if [ -f "$2/justfile" ] && command -v just >/dev/null 2>&1; then
    if just --justfile "$2/justfile" --summary 2>/dev/null | tr ' ' '\n' | grep -qx "$1"; then R=just; fi
  fi
}

# myos_hook_run PHASE DIR KIND: run one hook; returns its status (75 = skipped)
myos_hook_run() {
  MYOS_PHASE=$1; export MYOS_PHASE
  myos_hook_env
  if [ "$MYOS_DRYRUN" = true ]; then printf '%s\n' "hook $1 ($2)"; return 0; fi
  case $3 in
    just)   (cd "$2" && just --justfile "$2/justfile" "$1") ;;
    action) (cd "$2" && "$2/actions/$1") ;;
  esac
}

# myos_hooks PHASE: run every PHASE hook of the project; a failure stops
myos_hooks() {
  myos_hook_dirs; _hk_dirs=$R
  _hk_ifs=$IFS; IFS=$NL; set -f
  for _hk_d in $_hk_dirs; do
    IFS=$_hk_ifs; set +f
    myos_hook_find "$1" "$_hk_d"
    if [ -n "$R" ]; then
      myos_hook_run "$1" "$_hk_d" "$R"; _hk_rc=$?
      case $_hk_rc in
        0)  myos_event "$1" "$_hk_d" ok ;;
        75) myos_event "$1" "$_hk_d" skip ;;
        *)  myos_event "$1" "$_hk_d" fail "exit $_hk_rc"; IFS=$_hk_ifs; set +f; return 1 ;;
      esac
    fi
    IFS=$NL; set -f
  done
  IFS=$_hk_ifs; set +f; return 0
}

# myos_hook_replace VERB: run the highest <verb> hook if one exists (returns 1 when none)
myos_hook_replace() {
  myos_hook_dirs; _hr_found=; _hr_dir=
  _hr_ifs=$IFS; IFS=$NL; set -f
  for _hr_d in $R; do IFS=$_hr_ifs; set +f; myos_hook_find "$1" "$_hr_d"; [ -n "$R" ] && { _hr_found=$R; _hr_dir=$_hr_d; }; IFS=$NL; set -f; done
  IFS=$_hr_ifs; set +f
  [ -n "$_hr_found" ] || return 1
  myos_hook_run "$1" "$_hr_dir" "$_hr_found"; _hr_rc=$?
  [ "$_hr_rc" -eq 75 ] && return 1
  return $_hr_rc
}

# myos_verb_with_hooks VERB DEFAULT_FN: pre hooks, the verb (hook or default), post hooks
myos_verb_with_hooks() {
  myos_hooks "pre-$1" || return 1
  if ! myos_hook_replace "$1"; then "$2" || { myos_hooks "on-fail-$1"; return 1; }; fi
  myos_hooks "post-$1"
}

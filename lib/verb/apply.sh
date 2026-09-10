#shellcheck shell=sh
# apply: bring a checkout to what git says, and deploy it.
#
#   myos [-C DIR] apply [--from <remote>/<ref>] [--target N] [--backend swarm] [REF...]
#
# This is the verb a reconciler loops on, and the verb an operator runs by hand
# when the forge is down -- the same command either way, which is the point:
# ssh, a CI runner and a reconciler are three ways of triggering one execution
# path, not three deployment models.
#
#   --from origin/main     fetch that remote, verify, hard reset to that ref
#   (no --from)            apply the checkout as it stands
#   MYOS_APPLY_VERIFY=true `git verify-commit` must pass before the reset
#   MYOS_POLICY_ENFORCE=false turns the gate off; it is on for apply otherwise
#
# `apply --from` discards uncommitted work by design -- git is the truth, and
# reverting drift is what a reconciler is for. It refuses to do so on a dirty
# checkout unless --force, because an operator's working copy is not a
# reconciler's, and losing an afternoon to a typo is not reconciliation.

myos_apply_verify() {
  myos_var MYOS_APPLY_VERIFY; [ "$R" = true ] || return 0
  if myos_run git -C "$MYOS_WORKDIR" verify-commit "$MYOS_FROM"; then myos_event verify "$MYOS_FROM" ok; return 0; fi
  myos_event verify "$MYOS_FROM" fail "no good signature"; return 1
}

# myos_apply_converge: fetch and reset once, whatever the number of projects
myos_apply_converge() {
  [ -n "${MYOS_APPLY_CONVERGED:-}" ] && return 0
  MYOS_APPLY_CONVERGED=1
  [ -n "$MYOS_FROM" ] || return 0
  [ -d "$MYOS_WORKDIR/.git" ] || myos_die 1 "--from $MYOS_FROM needs a git checkout in $MYOS_WORKDIR"
  if [ -z "$MYOS_FORCE" ] && [ -n "$(git -C "$MYOS_WORKDIR" status --porcelain 2>/dev/null)" ]; then
    myos_die 1 "$MYOS_WORKDIR has uncommitted changes and --from would discard them (--force to proceed)"
  fi
  case $MYOS_FROM in
    */*) _ac_r=${MYOS_FROM%%/*}
         if myos_run git -C "$MYOS_WORKDIR" fetch --quiet "$_ac_r"; then myos_event fetch "$_ac_r" ok
         else myos_event fetch "$_ac_r" fail; return 1; fi ;;
  esac
  myos_apply_verify || return 1
  if myos_run git -C "$MYOS_WORKDIR" reset --hard --quiet "$MYOS_FROM"; then myos_event converge "$MYOS_FROM" ok
  else myos_event converge "$MYOS_FROM" fail; return 1; fi
}

myos_apply_default() {
  myos_apply_converge || return 1
  MYOS_POLICY_ON=true          # the gate is the reason apply exists
  myos_verb_up || return $?    # 4 when the gate refused: it is an audit finding
  [ "$MYOS_DRYRUN" = true ] && return 0
  [ "$MYOS_BACKEND" = swarm ] && return 0   # stack deploy --detach=false already waited
  myos_wait_healthy
}

myos_verb_apply() {
  myos_lock
  myos_verb_with_hooks apply myos_apply_default; _ap_rc=$?
  myos_unlock
  return $_ap_rc
}

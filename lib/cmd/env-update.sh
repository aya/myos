#shellcheck shell=sh
# myos env-update  fill the .env of the workdir from the .env.dist it finds
#
# Templates are read from the workdir and from every requested stack, so a
# stack can ship the variables it expects and their defaults.
myos_cmd_env_update() {
  _target=${ENV_FILE:-$WORKDIR/.env}
  _dists=$MYOS_ARGS
  if [ -z "$_dists" ]; then
    for _ref in $MYOS_STACKS; do
      _d=$(myos_stack_resolve "$_ref" 2>/dev/null) || continue
      for _c in "$_d/.env.dist" "$_d/$(myos_stack_name "$_ref").env.dist"; do
        [ -f "$_c" ] && _dists="${_dists:+$_dists }$_c"
      done
    done
    for _c in "$WORKDIR/.env.dist" "$WORKDIR/.env.example" "$WORKDIR/.env.sample"; do
      [ -f "$_c" ] && _dists="${_dists:+$_dists }$_c"
    done
  fi
  [ -n "$_dists" ] || { myos_warning "no .env.dist found for $MYOS_STACKS"; return 0; }
  for _dist in $_dists; do
    myos_info "env-update $_target from $_dist"
    myos_env_update "$_target" "$_dist" "$WORKDIR/.env.$ENV"
  done
  printf '%s\n' "$_target"
}

#shellcheck shell=sh
# policy: what a stack asks of the host that a shared cluster cannot grant.
#   policy [audit]   one line per finding: stack, service, severity, rule
#                    --strict exits 4 when a finding denies
# Access to the docker socket of a manager is root on the whole swarm, and
# swarm has no RBAC, no admission control and no quota: nothing below the
# engine refuses these. So this is the frontier, and it runs where the author
# of the stack cannot edit it -- on the machine that applies, not in the CI of
# the project.
#
# deny  an escalation: the service leaves its container (privileged, added
#       capabilities, a host namespace, a device, an unconfined profile, a
#       bind mount of the host, the docker socket)
# warn  a shared-cluster hygiene the catalogue does not carry yet: no
#       resource limits (one tenant starves its neighbours), no healthcheck
#       (a swarm rolling update calls a task healthy as soon as it started,
#       so `order: start-first` promises nothing).
#       MYOS_POLICY_REQUIRE="limits healthcheck" turns those into denials,
#       which is how a cluster tightens without waiting for every stack.
#
# A host stack is the trusted layer of the model (it is the load balancer, it
# binds the privileged ports), so its escalations are reported as warnings
# rather than denials -- reported, never blessed: a proxy that reads the
# docker API wants a read-only socket proxy, not the socket.

# myos_policy_raw -> R: NL list of "svc<TAB>kind<TAB>detail" from the raw files
myos_policy_raw() {
  R=; [ -n "$MYOS_STACK_FILES" ] || return 0
  _pl_ifs=$IFS; IFS=$NL; set -f
  # shellcheck disable=SC2086
  R=$(awk '
    function note(s, k, d) { n++; fs[n] = s "\t" k "\t" d }
    function see(s) { if (!(s in seen)) { seen[s] = 1; order[++o] = s } }
    /^services:/ { top = "services"; next }
    /^[^ \t#]/   { top = $0; next }
    top != "services" { next }
    /^  [A-Za-z0-9_.-]+:/ {
      svc = $0; sub(/^  /, "", svc); sub(/:.*/, "", svc); see(svc)
      inlist = ""; indeploy = 0; inres = 0; next
    }
    svc == "" { next }
    # a key of the service: closes any list, opens the ones we follow
    /^    [A-Za-z_]+:/ {
      key = $0; sub(/^ +/, "", key); val = key; sub(/^[^:]*:[ \t]*/, "", val); sub(/:.*/, "", key)
      sub(/[ \t]+#.*$/, "", val)
      inlist = ""; indeploy = (key == "deploy"); inres = 0
      if (key == "healthcheck") hc[svc] = 1
      else if (key == "privileged" && val ~ /true/) note(svc, "privileged", "privileged: true")
      else if (key == "cap_add") inlist = "cap_add"
      else if (key == "devices") inlist = "devices"
      else if (key == "security_opt") inlist = "security_opt"
      else if (key == "volumes") inlist = "volumes"
      else if ((key == "pid" || key == "ipc" || key == "userns_mode" || key == "network_mode") && val ~ /host/)
        note(svc, "namespace", key ": " val)
      next
    }
    # deploy.resources.limits, the only nesting we follow
    indeploy && /^      resources:/ { inres = 1; next }
    indeploy && /^      [A-Za-z_]+:/ { inres = 0; next }
    indeploy && inres && /^        limits:/ { lim[svc] = 1; next }
    # the items of a list we follow
    inlist != "" && /^ +- / {
      it = $0; sub(/^ +- /, "", it); sub(/[ \t]+#.*$/, "", it); gsub(/^["'"'"']|["'"'"']$/, "", it)
      if (it == "") next
      if (inlist == "volumes") note(svc, "volume", it)
      else note(svc, inlist, it)
      next
    }
    inlist != "" && /^ +[A-Za-z_]/ { inlist = "" }
    END {
      for (i = 1; i <= n; i++) print fs[i]
      for (i = 1; i <= o; i++) {
        s = order[i]
        if (!(s in hc))  print s "\tno-healthcheck\t"
        if (!(s in lim)) print s "\tno-limits\t"
      }
    }
  ' $MYOS_STACK_FILES)
  IFS=$_pl_ifs; set +f
}

# myos_policy_volume SPEC -> R: deny reason, empty when the mount is fine
myos_policy_volume() {
  myos_env_resolve "$1"; _pv=$R
  case $_pv in *:*) ;; *) R=; return 0 ;; esac   # a bare name is an anonymous volume
  _pv_src=${_pv%%:*}
  case $_pv_src in
    */docker.sock|*/docker.sock:*|*docker.sock) R="the docker socket is root on the node: use a read-only socket proxy" ;;
    /*) R="bind mount of the host: $_pv_src" ;;
    ~*) R="bind mount of the host: $_pv_src" ;;
    .*) R="bind mount of the project directory: $_pv_src" ;;
    *)  R= ;;                                     # a named volume
  esac
}

# myos_policy_findings -> R: NL list of "svc severity rule detail"
myos_policy_findings() {
  myos_policy_raw; _pf_raw=$R; _pf_out=
  # a host stack is the trusted layer: its escalations are reported, not denied
  _pf_esc=deny; [ "$MYOS_STACK_SCOPE" = host ] && _pf_esc=warn
  myos_var MYOS_POLICY_REQUIRE; _pf_req=$R
  _pf_ifs=$IFS; IFS=$NL; set -f
  for _pf_l in $_pf_raw; do
    IFS=$_pf_ifs; set +f
    _pf_svc=${_pf_l%%	*}; _pf_r=${_pf_l#*	}
    _pf_kind=${_pf_r%%	*}; _pf_det=${_pf_r#*	}
    _pf_sev=$_pf_esc
    case $_pf_kind in
      volume)
        myos_policy_volume "$_pf_det"
        [ -n "$R" ] || { IFS=$NL; set -f; continue; }
        _pf_det=$R ;;
      no-healthcheck)
        _pf_sev=warn; myos_has healthcheck "$_pf_req" && _pf_sev=deny
        _pf_det="a rolling update calls the task healthy as soon as it starts" ;;
      no-limits)
        _pf_sev=warn; myos_has limits "$_pf_req" && _pf_sev=deny
        _pf_det="no deploy.resources.limits: nothing bounds this service" ;;
      cap_add|devices) _pf_det="$_pf_kind: $_pf_det" ;;
      security_opt)
        case $_pf_det in *unconfined*) _pf_det="security_opt: $_pf_det" ;;
          *) IFS=$NL; set -f; continue ;; esac ;;
    esac
    _pf_out="$_pf_out$NL$_pf_svc $_pf_sev $_pf_kind $_pf_det"
    IFS=$NL; set -f
  done
  IFS=$_pf_ifs; set +f; R=${_pf_out#"$NL"}
}

# myos_policy_enforce: the gate in front of an apply. Off by default, because
# a workstation is not a shared cluster; the reconciler of a cluster sets
# MYOS_POLICY_ENFORCE=true (and MYOS_POLICY_REQUIRE to what that cluster
# demands) so a denied stack never reaches the docker socket it wants.
myos_policy_enforce() {
  myos_var MYOS_POLICY_ENFORCE; _pe_v=$R
  # `apply` sets MYOS_POLICY_ON; MYOS_POLICY_ENFORCE=false still turns it off,
  # so an operator keeps a way through on a cluster he owns
  case $_pe_v in false) return 0 ;; true) ;; *) [ "${MYOS_POLICY_ON:-}" = true ] || return 0 ;; esac
  _pe_was=$MYOS_STRICT; MYOS_STRICT=1
  myos_verb_policy; _pe_rc=$?
  MYOS_STRICT=$_pe_was
  [ "$_pe_rc" -eq 0 ] || myos_event policy "$MYOS_STACK" fail "refused before the deploy"
  return $_pe_rc
}

myos_verb_policy() {
  myos_policy_findings; _vp_bad=
  _vp_ifs=$IFS; IFS=$NL; set -f
  for _vp_l in $R; do
    IFS=$_vp_ifs; set +f
    _vp_svc=${_vp_l%% *}; _vp_r=${_vp_l#* }
    _vp_sev=${_vp_r%% *}; _vp_r=${_vp_r#* }
    _vp_rule=${_vp_r%% *}; _vp_det=${_vp_r#* }
    if [ "$MYOS_OUTPUT" = json ]; then
      myos_json_str "$_vp_det"
      printf '{"verb":"policy","stack":"%s","service":"%s","severity":"%s","rule":"%s","detail":%s}\n' \
        "$MYOS_STACK" "$_vp_svc" "$_vp_sev" "$_vp_rule" "$R"
    else
      printf '%s %s %s %s %s\n' "$MYOS_STACK" "$_vp_svc" "$_vp_sev" "$_vp_rule" "$_vp_det"
    fi
    [ "$_vp_sev" = deny ] && _vp_bad="$_vp_bad $_vp_svc:$_vp_rule"
    IFS=$NL; set -f
  done
  IFS=$_vp_ifs; set +f
  if [ -n "$MYOS_STRICT" ] && [ -n "$_vp_bad" ]; then
    myos_event audit "$MYOS_STACK" fail "denied:$_vp_bad"; return 4
  fi
  return 0
}

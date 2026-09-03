#shellcheck shell=sh
# config: where settings come from, and in which order.
#
# Layers, last one wins:
#   defaults < /etc/conf.d/myos, /etc/default/myos < ~/.config/myos/config
#           < <workdir>/.env < <workdir>/.env.<env> < environment < CLI VAR=val
# MYOS_CONF_PRIORITY=system restores the old make behaviour where the system
# file won over the project .env.
#
# Files are dotenv: KEY=value, one per line, # comments, optional quotes.
# They are parsed, never sourced: a value never runs as code.

# myos_dotenv_parse FILE  print normalized KEY=value lines
myos_dotenv_parse() {
  [ -f "$1" ] || return 0
  sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$1" |
  while IFS= read -r _line; do
    case $_line in *=*) ;; *) continue ;; esac
    _k=${_line%%=*}
    _v=${_line#*=}
    _k=$(printf '%s' "$_k" | tr -d '[:space:]')
    # whitespace around the = is not part of the value (make: s/[[:space:]]*=[[:space:]]*/=/)
    _v=${_v#"${_v%%[![:space:]]*}"}
    case $_k in ''|*[!A-Za-z0-9_]*) continue ;; esac
    # strip one layer of matching quotes
    case $_v in
      \"*\") _v=${_v#\"}; _v=${_v%\"} ;;
      \'*\') _v=${_v#\'}; _v=${_v%\'} ;;
    esac
    printf '%s=%s\n' "$_k" "$_v"
  done
}

# myos_dotenv_load FILE  set the variables of FILE that are not already set
# (an already exported variable wins, as `?=` does in make)
myos_dotenv_load() {
  [ -f "$1" ] || return 0
  while IFS= read -r _kv; do
    # an empty file still yields one empty line through the here-document
    [ -n "$_kv" ] || continue
    _k=${_kv%%=*}
    [ -n "$_k" ] || continue
    [ -n "$(myos_var "$_k")" ] && continue
    eval "$_k=\${_kv#*=}"
  done <<EOF
$(myos_dotenv_parse "$1")
EOF
}

# myos_dotenv_has FILE KEY
myos_dotenv_has() { myos_dotenv_parse "$1" | grep -q "^$2="; }

# myos_conf_files  the system config files, most significant first
myos_conf_files() {
  [ -n "${MYOS_CONF:-}" ] && { printf '%s\n' "$MYOS_CONF"; return 0; }
  for _f in /etc/conf.d/myos /etc/default/myos; do
    [ -r "$_f" ] && printf '%s\n' "$_f"
  done
  return 0
}

# myos_env_vars FILE...  the ${VAR} names referenced by the compose files
# (make: env-vars). $$VAR is a compose escape, not a shell variable.
myos_env_vars() {
  [ $# -gt 0 ] || return 0
  sed 's/\$\$//g' "$@" 2>/dev/null |
    grep -oE '\$\{?[A-Z0-9_]+' |
    tr -d '{}$' |
    sort -u |
    tr '\n' ' ' |
    sed 's/ $//'
}

# myos_env_export VAR...  print VAR='value' for each variable that has a value,
# ready to be passed to env(1)
myos_env_export() {
  for _v in "$@"; do
    _val=$(myos_var "$_v")
    [ -n "$_val" ] && printf "%s=%s\n" "$_v" "$_val"
  done
  return 0
}

# myos_expand STRING  substitute ${VAR} and $(command) in STRING.
# shellcheck disable=SC2016  # the single quotes are deliberate: these patterns
# match the literal characters ${ and $( in the input, they are not expansions
# This is what the make engine did when it generated a .env out of a .env.dist:
# ${VAR} takes the current value, $(cmd) runs the command. Nothing else is
# interpreted, so the rest of the line can hold anything.
myos_expand() {
  _in=$1
  _guard=0
  while [ "$_guard" -lt 16 ]; do
    _guard=$((_guard + 1))
    case $_in in
      *'${'*'}'*)
        _pre=${_in%%'${'*}
        _rest=${_in#*'${'}
        _name=${_rest%%\}*}
        _post=${_rest#*\}}
        case $_name in
          ''|*[!A-Za-z0-9_]*) _in="$_pre\${$_name}$_post"; break ;;
        esac
        _in="$_pre$(myos_var "$_name")$_post" ;;
      *) break ;;
    esac
  done
  _guard=0
  while [ "$_guard" -lt 16 ]; do
    _guard=$((_guard + 1))
    case $_in in
      *'$('*')'*)
        _pre=${_in%%'$('*}
        _rest=${_in#*'$('}
        _cmd=${_rest%%)*}
        _post=${_rest#*)}
        _in="$_pre$(eval "$_cmd" 2>/dev/null)$_post" ;;
      *) break ;;
    esac
  done
  printf '%s' "$_in"
}

# myos_env_update FILE DIST [OVER...]
# Add to FILE every variable of DIST that is missing from it, expanded.
# A variable that already has a value keeps it, whether it comes from the
# environment, from FILE, or from one of the OVER files: the .env is a record
# of the choices already made, never something that overwrites them.
myos_env_update() {
  _file=$1; _dist=$2; shift 2
  [ -f "$_dist" ] || return 0
  [ -e "$_file" ] || : > "$_file"

  # what the overrides pin, read before anything else
  for _over in "$@"; do
    [ -f "$_over" ] || continue
    myos_dotenv_load "$_over"
  done

  # Which keys already hold a choice, made in the environment, in the .env or
  # in an override. Those are kept verbatim; everything else is a template.
  _preset=" "
  while IFS= read -r _kv; do
    [ -n "$_kv" ] || continue
    _k=${_kv%%=*}
    [ -n "$_k" ] || continue
    [ -n "$(myos_var "$_k")" ] && _preset="$_preset$_k "
  done <<EOF
$(myos_dotenv_parse "$_dist")
EOF

  # Make the templates themselves visible, so a line may refer to a variable
  # defined further down the file, as the make engine allowed.
  myos_dotenv_load "$_dist"

  _added=0
  while IFS= read -r _kv; do
    [ -n "$_kv" ] || continue
    _k=${_kv%%=*}
    [ -n "$_k" ] || continue
    myos_dotenv_has "$_file" "$_k" && continue
    case $_preset in
      *" $_k "*) _v=$(myos_var "$_k") ;;
      *) _v=$(myos_expand "${_kv#*=}") ;;
    esac
    printf '%s=%s\n' "$_k" "$_v" >> "$_file"
    _added=$((_added + 1))
  done <<EOF
$(myos_dotenv_parse "$_dist")
EOF
  [ "$_added" -gt 0 ] && myos_info "added $_added variable(s) to $_file"
  return 0
}

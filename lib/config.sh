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

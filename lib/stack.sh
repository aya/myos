#shellcheck shell=sh
# stack: where stacks live, how a reference resolves to compose files.
#
# A stack is a directory holding compose files. A reference is
#   [<group>/]<name>[:<version>]   resolved along MYOS_PATH
#   ./ or /abs/path or rel/path    the directory itself
# Ported from make/def.docker.mk (STACK_DIR/SHARE_DIR) and
# make/apps/def.docker.mk (compose-file, docker-stack, docker-stack-update).

# myos_path  the stack search path, colon separated, existing directories only.
# Project first, then the shared catalogues: a project always wins over the
# catalogue installed system wide.
myos_path() {
  [ -n "${MYOS_PATH:-}" ] && { printf '%s' "$MYOS_PATH"; return 0; }
  _wd=${WORKDIR:-$PWD}
  _name=${STACK_DIR_NAME:-stack}
  _out=
  # <prefix>/share comes from MYOS_ROOT, so an installation under any prefix
  # finds the catalogue installed beside it
  _prefix=
  [ -n "${MYOS_ROOT:-}" ] && _prefix=$(dirname "$(dirname "$MYOS_ROOT")")/share
  for _d in "$_wd" "$_wd/.." "${HOME:-/nonexistent}/.local/share" \
            ${_prefix:+"$_prefix"} /usr/local/share /usr/share; do
    for _c in "$_d/$_name" "$_d/myos/$_name"; do
      [ -d "$_c" ] || continue
      _c=$(cd "$_c" && pwd -P)
      case ":$_out:" in *":$_c:"*) continue ;; esac
      _out="${_out:+$_out:}$_c"
    done
  done
  printf '%s' "$_out"
}

# myos_stack_name REF     the stack name: "host/fabio:1.6" -> "fabio"
# myos_stack_version REF  the version, "latest" when the reference has none
# Both are pure, so a caller can use them inside a command substitution.
myos_stack_name() {
  _r=${1%/}
  case $_r in *:*) _r=${_r%:*} ;; esac
  basename "$_r" .yml
}
myos_stack_version() {
  _r=${1%/}
  case $_r in *:*) printf '%s' "${_r##*:}" ;; *) printf 'latest' ;; esac
}

# myos_stack_resolve REF  print the directory holding the stack,
# or fail with MYOS_E_NOSTACK
myos_stack_resolve() {
  _ref=${1%/}
  case $_ref in *:*) _ref=${_ref%:*} ;; esac
  _name=$(myos_stack_name "$1")

  # a path reference resolves to itself
  case $_ref in
    .|./*|/*|../*)
      if [ -d "$_ref" ]; then printf '%s' "$(cd "$_ref" && pwd -P)"; return 0; fi
      myos_error "no such directory: $_ref"; return "$MYOS_E_NOSTACK" ;;
  esac

  _IFS=$IFS; IFS=:
  for _d in $(myos_path); do
    IFS=$_IFS
    if [ -d "$_d/$_ref" ]; then printf '%s' "$_d/$_ref"; return 0; fi
    if [ -f "$_d/$_ref.yml" ] || [ -f "$_d/$_ref.yaml" ]; then
      printf '%s' "$(dirname "$_d/$_ref")"; return 0
    fi
    if [ -d "$_d/$_name" ]; then printf '%s' "$_d/$_name"; return 0; fi
    IFS=:
  done
  IFS=$_IFS
  myos_error "stack not found: $1 (searched $(myos_path))"
  return "$MYOS_E_NOSTACK"
}

# myos_compose_suffixes  the overlay suffixes, from the COMPOSE_FILE_* variables
# that are not false (make: COMPOSE_FILE_SUFFIX). A value other than true also
# yields "<suffix>.<value>", which is how COMPOSE_FILE_WWW=nginx works.
myos_compose_suffixes() {
  _out=
  for _v in $(set | sed -n 's/^\(COMPOSE_FILE_[A-Z0-9_]*\)=.*/\1/p' | sort -u); do
    case $_v in COMPOSE_FILE_SUFFIX) continue ;; esac
    _val=$(myos_var "$_v")
    case $_val in false|False|FALSE|'') continue ;; esac
    _s=$(myos_lower "${_v#COMPOSE_FILE_}")
    _out="${_out:+$_out }$_s"
    case $_val in true|True|TRUE) ;; *) for _x in $_val; do _out="$_out $_s.$_x"; done ;; esac
  done
  printf '%s' "$_out"
}

# myos_compose_files DIR NAMES SUFFIXES [ENV]
# Print the compose files that exist, in the order the framework loads them.
myos_compose_files() {
  _dir=$1; _names=$2; _suffixes=${3:-}; _env=${4:-${ENV:-local}}
  for _e in yml yaml; do
    for _n in $_names; do
      for _f in \
        "$_dir/$_n.$_e" "$_dir/$_n.$_env.$_e" \
        "$_dir/$_env/$_n.$_e" "$_dir/$_env/$_n.$_env.$_e"; do
        [ -f "$_f" ] && printf '%s\n' "$_f"
      done
      for _s in $_suffixes; do
        for _f in "$_dir/$_n.$_s.$_e" "$_dir/$_n.$_s.$_env.$_e"; do
          [ -f "$_f" ] && printf '%s\n' "$_f"
        done
      done
    done
  done
  return 0
}

# myos_group_expand REF...  expand group references recursively.
# A group is a variable whose name is the reference: `host=host/consul host/fabio`
# in the environment, in a .env, in <path>/<group>.env or in a legacy <group>.mk.
myos_group_expand() {
  _depth=${MYOS_GROUP_DEPTH:-0}
  [ "$_depth" -gt 16 ] && myos_die "$MYOS_E_USAGE" "stack group nested too deep: $*"
  for _ref in "$@"; do
    _val=$(myos_group_value "$_ref")
    if [ -n "$_val" ]; then
      # shellcheck disable=SC2086  # the group value is a list of references
      MYOS_GROUP_DEPTH=$((_depth + 1)) myos_group_expand $_val
    else
      printf '%s\n' "$_ref"
    fi
  done
}

# myos_group_value REF  the list a group expands to, empty when not a group.
# Groups are lowercase by convention (host, testing, coroot, default): without
# that rule any environment variable sharing a stack name would be expanded,
# which is how the make engine behaved. The character class is spelled out
# because a-z also matches uppercase under a dictionary collation (fr_FR).
myos_group_value() {
  case $1 in .|/*|*/*|*:*) return 0 ;; esac
  case $1 in *[![:lower:][:digit:]_-]*) return 0 ;; esac
  _v=$(myos_var "$1")
  [ -n "$_v" ] && { printf '%s' "$_v"; return 0; }
  _IFS=$IFS; IFS=:
  for _d in $(myos_path); do
    IFS=$_IFS
    [ -f "$_d/$1.env" ] && { _v=$(sed -n "s/^$1=//p" "$_d/$1.env" | tail -1 | tr -d '"'); }
    [ -z "$_v" ] && [ -f "$_d/$1.mk" ] && { _v=$(myos_mk_group "$_d/$1.mk" "$1"); }
    [ -z "$_v" ] && [ -f "$_d/$1/$1.mk" ] && { _v=$(myos_mk_group "$_d/$1/$1.mk" "$1"); }
    [ -n "$_v" ] && { printf '%s' "$_v"; return 0; }
    IFS=:
  done
  IFS=$_IFS
  return 0
}

# myos_mk_group FILE NAME  read `name ?= a b c` out of a legacy .mk snippet
myos_mk_group() {
  sed -n "s/^$2[[:space:]]*[?:]\{0,1\}=[[:space:]]*//p" "$1" 2>/dev/null | tail -1
}

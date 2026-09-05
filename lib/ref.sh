#shellcheck shell=sh
# ref: stack references and groups.
# A reference is [<scope>/]<name>[:<version>] looked up on the path, or a
# path (. ./x /abs): the directory itself is the stack. A group is a word
# defined as `<group>=<ref> <ref>...` in a *.env or */*.env of a path
# directory (transition: `<group> ?= ...` lines of the *.mk read by make);
# the environment is never consulted, so a variable can not be taken for a
# group.

myos_groups() { # -> R: NL list of "name=members", last definition wins
  [ -n "${MYOS_GROUPS_LOADED:-}" ] && { R=$MYOS_GROUPS; return 0; }
  myos_path; _g_path=$R
  _g_ifs=$IFS; IFS=$NL; set -f; _g_files=
  for _g_d in $_g_path; do
    set +f
    for _g_f in "$_g_d"/*.env "$_g_d"/*/*.env "$_g_d"/*.mk "$_g_d"/*/*.mk; do [ -f "$_g_f" ] && _g_files="$_g_files$NL$_g_f"; done
    set -f
  done
  IFS=$_g_ifs; set +f
  MYOS_GROUPS=
  if [ -n "$_g_files" ]; then
    MYOS_GROUPS=$(printf '%s\n' "$_g_files" | sed '/^$/d' | xargs grep -h -E '^[A-Za-z][a-z0-9_-]*[[:space:]]*[?:]?=[^=]' 2>/dev/null \
      | sed -e 's/[[:space:]]*[?:]*=[[:space:]]*/=/' -e 's/[[:space:]]*$//' -e 's/^\([^=]*\)="\(.*\)"$/\1=\2/' | grep -v '[$%{(]')
  fi
  MYOS_GROUPS_LOADED=1; R=$MYOS_GROUPS
}

myos_group_members() { # NAME -> R: members, empty when NAME is not a group
  R=
  case $1 in *[/:.]*|'') return 0 ;; esac
  myos_groups; _gm_out=
  _gm_ifs=$IFS; IFS=$NL; set -f
  for _gm_l in $MYOS_GROUPS; do [ "${_gm_l%%=*}" = "$1" ] && _gm_out=${_gm_l#*=}; done
  IFS=$_gm_ifs; set +f; R=$_gm_out
}

myos_expand() { # REFS [DEPTH] -> R: references with every group expanded
  _x_depth=${2:-0}; [ "$_x_depth" -lt 16 ] || myos_die 2 "group expansion too deep (cycle?) at $1"
  # the accumulator is named after the depth: the function recurses
  eval "_x_out_$_x_depth="
  set -f
  for _x_r in $1; do
    set +f
    myos_group_members "$_x_r"
    if [ -n "$R" ]; then
      myos_expand "$R" $((_x_depth + 1)); _x_depth=$((_x_depth - 1))
    else
      R=$_x_r
    fi
    eval "_x_out_$_x_depth=\"\${_x_out_$_x_depth:+\$_x_out_$_x_depth }\$R\""
    set -f
  done
  set +f
  eval "R=\$_x_out_$_x_depth"
}

# myos_ref_parse REF -> MYOS_REF_KIND (path|search) MYOS_REF_SCOPE MYOS_REF_NAME
# MYOS_REF_VERSION MYOS_REF_DIR (path form) MYOS_REF_APP (first segment: what
# names the compose project)
myos_ref_parse() {
  _rp_r=${1%/}; MYOS_REF_VERSION=
  case $_rp_r in
    .|./*|/*|..|../*)
      MYOS_REF_KIND=path
      myos_realpath "$_rp_r"; [ -n "$R" ] || myos_die 3 "stack $1: no such directory"
      MYOS_REF_DIR=$R
      MYOS_REF_NAME=$(basename "$R")
      MYOS_REF_SCOPE=; MYOS_REF_APP=$MYOS_REF_NAME
      ;;
    *)
      MYOS_REF_KIND=search
      case $_rp_r in *:*) MYOS_REF_VERSION=${_rp_r##*:}; _rp_r=${_rp_r%:*} ;; esac
      _rp_r=${_rp_r%.yml}
      case $_rp_r in
        */*) MYOS_REF_SCOPE=${_rp_r%/*}; MYOS_REF_NAME=${_rp_r##*/}; MYOS_REF_APP=${_rp_r%%/*} ;;
        *)   MYOS_REF_SCOPE=; MYOS_REF_NAME=$_rp_r; MYOS_REF_APP=$_rp_r ;;
      esac
      MYOS_REF_DIR=
      ;;
  esac
}

# myos_ref_dirs -> R: NL list of the directories holding the parsed reference,
# ascending precedence (the same rules as the make engine: <dir>/<scope> when
# <scope>/<name>.yml or the directory <scope>/<name> exists, <dir>/<name> for
# a bare name)
myos_ref_dirs() {
  R=
  if [ "$MYOS_REF_KIND" = path ]; then
    R=$MYOS_REF_DIR; [ -d "$MYOS_REF_DIR/docker" ] && R="$R$NL$MYOS_REF_DIR/docker"
    return 0
  fi
  myos_path; _rd_path=$R; _rd_out=
  _rd_ifs=$IFS; IFS=$NL; set -f
  for _rd_d in $_rd_path; do
    _rd_hit=
    if [ -n "$MYOS_REF_SCOPE" ]; then
      if [ -f "$_rd_d/$MYOS_REF_SCOPE/$MYOS_REF_NAME.yml" ] || [ -f "$_rd_d/$MYOS_REF_SCOPE/$MYOS_REF_NAME.yaml" ]; then _rd_hit=$_rd_d/$MYOS_REF_SCOPE
      elif [ -d "$_rd_d/$MYOS_REF_SCOPE/$MYOS_REF_NAME" ]; then _rd_hit=$_rd_d/$MYOS_REF_SCOPE/$MYOS_REF_NAME
      fi
    elif [ -d "$_rd_d/$MYOS_REF_NAME" ]; then _rd_hit=$_rd_d/$MYOS_REF_NAME
    fi
    [ -n "$_rd_hit" ] && _rd_out="${_rd_out:+$_rd_out$NL}$_rd_hit"
  done
  IFS=$_rd_ifs; set +f; R=$_rd_out
}

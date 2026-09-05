#shellcheck shell=sh
# files: which compose files a stack directory contributes.
# For a directory p, names n in {docker-compose, <name>}, extensions yml and
# yaml, suffixes s: p/n.e p/n.<ENV>.e p/<ENV>/n.e p/<ENV>/n.<ENV>.e then, for
# each suffix, p/n.s.e p/n.s.<ENV>.e. The suffixes are the COMPOSE_FILE_<X>
# switches that are not false (app labels networks ssh volumes by default),
# sorted, plus the version of the reference (latest by default).

myos_suffixes() { # -> R: space list, sorted
  [ -n "${MYOS_SUFFIXES_CACHE:-}" ] && { R=$MYOS_SUFFIXES_CACHE; return 0; }
  _sf_sw="APP LABELS NETWORKS SSH VOLUMES"
  for _sf_v in $(env | sed -n 's/^COMPOSE_FILE_\([A-Z0-9_]*\)=.*/\1/p'); do
    [ "$_sf_v" = SUFFIX ] || myos_has "$_sf_v" "$_sf_sw" || _sf_sw="$_sf_sw $_sf_v"
  done
  [ -n "${DEBUG:-}" ] && _sf_sw="$_sf_sw DEBUG"
  _sf_out=
  for _sf_v in $_sf_sw; do
    eval "_sf_val=\${COMPOSE_FILE_$_sf_v:-true}"
    myos_lower "$_sf_v"; _sf_s=$R
    case $_sf_val in false|False|FALSE) continue ;; true|True|TRUE) _sf_out="$_sf_out $_sf_s" ;; *) _sf_out="$_sf_out $_sf_s $_sf_s.$_sf_val" ;; esac
  done
  myos_sort_words "$_sf_out"; MYOS_SUFFIXES_CACHE=$R
}

myos_compose_files() { # DIR NAMES SUFFIXES ENV -> R: NL list of existing files, in order
  _cf_out=; set -f
  for _cf_e in yml yaml; do
    for _cf_n in $2; do
      for _cf_f in "$1/$_cf_n.$_cf_e" "$1/$_cf_n.$4.$_cf_e" "$1/$4/$_cf_n.$_cf_e" "$1/$4/$_cf_n.$4.$_cf_e"; do
        [ -f "$_cf_f" ] && _cf_out="${_cf_out:+$_cf_out$NL}$_cf_f"
      done
      for _cf_s in $3; do
        for _cf_f in "$1/$_cf_n.$_cf_s.$_cf_e" "$1/$_cf_n.$_cf_s.$4.$_cf_e"; do
          [ -f "$_cf_f" ] && _cf_out="${_cf_out:+$_cf_out$NL}$_cf_f"
        done
      done
    done
  done
  set +f; R=$_cf_out
}

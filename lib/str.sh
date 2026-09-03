#shellcheck shell=sh
# str: string helpers ported from make/utils.mk and make/def.mk.

# myos_lower STRING / myos_upper STRING
myos_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
myos_upper() { printf '%s' "$1" | tr '[:lower:]-.' '[:upper:]__'; }

# myos_name STRING  compose-project-safe name: lowercase, no . - _
# (make: $(subst _,,$(subst -,,$(subst .,,$(call LOWERCASE,$(1))))))
myos_name() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '._-'; }

# myos_slugify STRING  keep [a-z0-9_], everything else becomes _
myos_slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]/_/g'; }

# myos_reverse WORDS...  reverse the order of space separated words
myos_reverse() {
  _out=
  for _w in $1; do _out="$_w${_out:+ }$_out"; done
  printf '%s' "$_out"
}

# myos_verle A B  true when version A <= B (make: verle)
myos_verle() {
  [ -n "$1" ] || return 1
  [ -n "$2" ] || return 1
  [ "$1" = "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" ]
}

# myos_verlt A B  true when version A < B
myos_verlt() {
  [ "$1" = "$2" ] && return 1
  myos_verle "$1" "$2"
}

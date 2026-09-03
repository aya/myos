#!/bin/sh
# myos installer.
#
#   curl -fsSL https://raw.githubusercontent.com/aya/myos/lightning/install.sh | sh
#   ... | sh -s -- --prefix ~/.local --with-stacks
#
# Installs the framework into <prefix>/lib/myos, links <prefix>/bin/myos, and
# optionally clones the stack catalogue into <prefix>/share/myos.
set -eu

MYOS_REPOSITORY=${MYOS_REPOSITORY:-https://github.com/aya/myos}
STACKS_REPOSITORY=${STACKS_REPOSITORY:-https://github.com/aya/myos-stacks}
REF=${MYOS_REF:-lightning}
PREFIX=
WITH_STACKS=false
WRITE_CONF=false

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

while [ $# -gt 0 ]; do
  case $1 in
    --prefix) PREFIX=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    --repository) MYOS_REPOSITORY=$2; shift 2 ;;
    --with-stacks) WITH_STACKS=true; shift ;;
    --conf) WRITE_CONF=true; shift ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

# Default prefix: system wide when we can write there, user local otherwise.
if [ -z "$PREFIX" ]; then
  if [ "$(id -u)" = 0 ] || [ -w /usr/local/lib ]; then PREFIX=/usr/local; else PREFIX=$HOME/.local; fi
fi

# --- requirements ---------------------------------------------------------
have git || die "git is required"
have docker || warn "docker not found: myos will not be able to run anything"
if have docker && docker compose version >/dev/null 2>&1; then :
elif have docker-compose; then :
else warn "no docker compose found: install the compose plugin, or docker-compose >= 2.24.4"
fi

# --- install --------------------------------------------------------------
LIB=$PREFIX/lib/myos
BIN=$PREFIX/bin

if [ -d "$LIB/.git" ]; then
  say "updating $LIB"
  git -C "$LIB" fetch --quiet origin "$REF"
  git -C "$LIB" checkout --quiet FETCH_HEAD
else
  say "installing myos into $LIB"
  mkdir -p "$(dirname "$LIB")"
  git clone --quiet --branch "$REF" "$MYOS_REPOSITORY" "$LIB"
fi

mkdir -p "$BIN"
ln -sf "$LIB/bin/myos" "$BIN/myos"
say "linked $BIN/myos"

if [ "$WITH_STACKS" = true ]; then
  SHARE=$PREFIX/share/myos
  if [ -d "$SHARE/.git" ]; then
    say "updating the stack catalogue in $SHARE"
    git -C "$SHARE" pull --quiet --ff-only
  else
    say "installing the stack catalogue into $SHARE"
    mkdir -p "$(dirname "$SHARE")"
    git clone --quiet "$STACKS_REPOSITORY" "$SHARE"
  fi
fi

# --- machine configuration ------------------------------------------------
# /etc/conf.d on Alpine and other OpenRC systems, /etc/default elsewhere.
if [ "$WRITE_CONF" = true ]; then
  if [ -d /etc/conf.d ]; then CONF=/etc/conf.d/myos; else CONF=/etc/default/myos; fi
  if [ "$(id -u)" != 0 ]; then CONF=$HOME/.config/myos/config; mkdir -p "$(dirname "$CONF")"; fi
  if [ -f "$CONF" ]; then
    say "keeping the existing $CONF"
  else
    cat > "$CONF" <<CONFEOF
# myos machine settings, one KEY=value per line.
# ENV=master
# DOMAIN=$(hostname -d 2>/dev/null || echo example.org)
# WORKDIR=/srv/myos
# a deployment created before myos 2.0 must keep the old project names:
# MYOS_PROJECT_FORMAT=user-app-env
CONFEOF
    say "wrote $CONF"
  fi
fi

case :$PATH: in
  *:$BIN:*) ;;
  *) warn "$BIN is not on your PATH" ;;
esac

say ""
say "myos $("$BIN/myos" version 2>/dev/null | awk '{print $2}') installed"
say "next: myos doctor"

#shellcheck shell=sh
# secrets: the values a deployment needs that its own checkout must not carry.
#
# They live in a configuration repository, laid out as the make engine had it:
#
#   <config>/.env                    shared by everything
#   <config>/<env>/.env              shared by an environment
#   <config>/<env>/<app>/.env        one application in one environment
#   <config>/<env>/<app>/secrets.env the same, encrypted with sops
#
# plus, for what belongs to one checkout only, $WORKDIR/secrets[.<env>].env.
# The most specific wins, and all of them lose to $WORKDIR/.env: the file one
# edits to debug a run stays the last word.
#
# MYOS_CONFIG says where that clone is (default $WORKDIR/config, then the
# sibling ../config, as the make engine looked); MYOS_CONFIG_REPOSITORY is the
# git URL `myos secrets pull` clones or fast-forwards. CONFIG and
# CONFIG_REPOSITORY are accepted as the make engine spelled them.
#
# A cluster owns an age key pair; a secret is encrypted for the public key of
# the cluster it is meant for (and for a recovery key), so the repository can
# be readable by every operator while one cluster cannot read the secrets of
# another. The private key never leaves the machine that applies. sops decrypts
# into a layer of myos_var, so what the command line or $WORKDIR/.env says
# still wins -- debugging a deployment must not require rewriting the store.
#
# MYOS_SECRETS names the provider: `sops` (the default) or `none`. It is the
# seam: an OpenBao provider adds a case here and nothing else moves, which is
# what pays for revocation and dynamic credentials the day sops stops being
# enough. The plaintext never touches the disk -- it lives in a shell variable
# for the time it takes to read it -- and never goes to a docker environment
# variable either, `docker inspect` and a crash report being public enough; a
# stack takes its secret as a swarm secret under /run/secrets.

# myos_config_dir -> R: the configuration clone, empty when there is none
myos_config_dir() {
  myos_var MYOS_CONFIG; [ -n "$R" ] && return 0
  myos_var CONFIG; [ -n "$R" ] && return 0
  for _cd_d in "$MYOS_WORKDIR/config" "$MYOS_WORKDIR/../config"; do
    [ -d "$_cd_d" ] && { myos_realpath "$_cd_d"; return 0; }
  done
  R=
}

# myos_secrets_files -> R: NL list of the files that hold values, least
# specific first, so that a later one overrides an earlier definition
myos_secrets_files() {
  _sf_out=
  myos_config_dir; _sf_c=$R
  if [ -n "$_sf_c" ]; then
    myos_name "$MYOS_STACK_APP"; _sf_app=$R
    for _sf_d in "$_sf_c" "$_sf_c/$MYOS_ENV" "$_sf_c/$MYOS_ENV/$_sf_app"; do
      for _sf_f in "$_sf_d/.env" "$_sf_d/secrets.env"; do
        [ -f "$_sf_f" ] && _sf_out="${_sf_out:+$_sf_out$NL}$_sf_f"
      done
    done
  fi
  for _sf_f in "$MYOS_WORKDIR/secrets.env" "$MYOS_WORKDIR/secrets.$MYOS_ENV.env"; do
    [ -f "$_sf_f" ] && _sf_out="${_sf_out:+$_sf_out$NL}$_sf_f"
  done
  R=$_sf_out
}

myos_secrets_provider() { # -> R: sops|none
  myos_var MYOS_SECRETS; [ -n "$R" ] || R=sops
  case $R in sops|none) ;; *) myos_die 2 "unknown secret provider $R (sops or none)" ;; esac
}

# myos_secrets_encrypted FILE: 0 when the file is a sops file rather than plain
myos_secrets_encrypted() { grep -q '^sops\|ENC\[AES256_GCM' "$1" 2>/dev/null; }

# myos_secrets_load: fill MYOS_SECRET_<NAME> from the files above. They are
# read least specific first and the last definition wins, which is the reverse
# of myos_values_absorb, so the list is walked backwards.
myos_secrets_load() {
  # read once per (environment, application): the layout is per both, and
  # myos_project_of calls this again for every reference of a run
  myos_name "${MYOS_STACK_APP:-}"; _sl_key=$MYOS_ENV/$R
  [ "${MYOS_SECRETS_LOADED:-}" = "$_sl_key" ] && return 0
  MYOS_SECRETS_LOADED=$_sl_key
  MYOS_SECRET_NAMES=; MYOS_SECRET_FILES=
  myos_secrets_files; _sl_files=$R
  [ -n "$_sl_files" ] || return 0
  MYOS_SECRET_FILES=$_sl_files
  myos_secrets_provider; _sl_p=$R
  # walk from the most specific to the least: the first definition wins
  _sl_rev=; _sl_ifs=$IFS; IFS=$NL; set -f
  for _sl_f in $_sl_files; do _sl_rev="$_sl_f${_sl_rev:+$NL$_sl_rev}"; done
  for _sl_f in $_sl_rev; do
    IFS=$_sl_ifs; set +f
    MYOS_ABSORBED=
    if myos_secrets_encrypted "$_sl_f"; then
      [ "$_sl_p" = none ] && { IFS=$NL; set -f; continue; }
      command -v sops >/dev/null 2>&1 ||
        myos_die 1 "$_sl_f needs sops on the PATH (MYOS_SECRETS=none ignores the encrypted files)"
      if _sl_text=$(sops --decrypt --output-type dotenv "$_sl_f" 2>/dev/null) ||
         _sl_text=$(sops --decrypt "$_sl_f" 2>/dev/null); then
        myos_values_absorb MYOS_SECRET_ "$_sl_text"; _sl_text=
      else
        myos_die 1 "sops could not decrypt $_sl_f (is the age key of this machine in SOPS_AGE_KEY_FILE?)"
      fi
    else
      myos_values_absorb MYOS_SECRET_ "$(cat "$_sl_f")"
    fi
    MYOS_SECRET_NAMES="$MYOS_SECRET_NAMES$MYOS_ABSORBED"
    IFS=$NL; set -f
  done
  IFS=$_sl_ifs; set +f
  myos_sort_words "$MYOS_SECRET_NAMES"; MYOS_SECRET_NAMES=$R
}

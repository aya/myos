#shellcheck shell=sh
# secrets: the values a repository carries encrypted.
#
# A cluster owns an age key pair; a secret is encrypted for the public key of
# the cluster it is meant for (and for a recovery key), so the repository can
# be public to every operator while one cluster cannot read the secrets of
# another. The private key never leaves the machine that applies.
#
#   $WORKDIR/secrets.<ENV>.env  then  $WORKDIR/secrets.env
#
# sops decrypts them into a layer of myos_var, between $WORKDIR/.env and the
# defaults of the stacks: what the operator types on the command line, or puts
# in the environment or in .env, still wins -- debugging a deployment must not
# require rewriting the encrypted store.
#
# MYOS_SECRETS names the provider: `sops` (the default) or `none`. It is the
# seam: an OpenBao provider adds a case here and nothing else moves, which is
# what pays for revocation and dynamic credentials the day sops stops being
# enough. The plaintext never touches the disk -- it lives in a shell variable
# for the time it takes to read it -- and never goes to a docker environment
# variable either, `docker inspect` and a crash report being public enough;
# a stack takes its secret as a swarm secret under /run/secrets.

# myos_secrets_files -> R: NL list of the encrypted files of the project
myos_secrets_files() {
  R=
  for _sf_f in "$MYOS_WORKDIR/secrets.$MYOS_ENV.env" "$MYOS_WORKDIR/secrets.env"; do
    [ -f "$_sf_f" ] && R="${R:+$R$NL}$_sf_f"
  done
}

myos_secrets_provider() { # -> R: sops|none
  myos_var MYOS_SECRETS; [ -n "$R" ] || R=sops
  case $R in sops|none) ;; *) myos_die 2 "unknown secret provider $R (sops or none)" ;; esac
}

# myos_secrets_load: fill MYOS_SECRET_<NAME> from the encrypted files
myos_secrets_load() {
  MYOS_SECRET_NAMES=
  myos_secrets_files; _sl_files=$R
  [ -n "$_sl_files" ] || return 0
  myos_secrets_provider; _sl_p=$R
  [ "$_sl_p" = none ] && return 0
  command -v sops >/dev/null 2>&1 || myos_die 1 "${_sl_files%%$NL*} needs sops on the PATH (MYOS_SECRETS=none ignores the file)"
  _sl_ifs=$IFS; IFS=$NL; set -f
  for _sl_f in $_sl_files; do
    IFS=$_sl_ifs; set +f
    MYOS_ABSORBED=
    if _sl_text=$(sops --decrypt --output-type dotenv "$_sl_f" 2>/dev/null) ||
       _sl_text=$(sops --decrypt "$_sl_f" 2>/dev/null); then
      myos_values_absorb MYOS_SECRET_ "$_sl_text"
      _sl_text=
      MYOS_SECRET_NAMES="$MYOS_SECRET_NAMES$MYOS_ABSORBED"
    else
      myos_die 1 "sops could not decrypt $_sl_f (is the age key of this machine in SOPS_AGE_KEY_FILE?)"
    fi
    IFS=$NL; set -f
  done
  IFS=$_sl_ifs; set +f
  myos_sort_words "$MYOS_SECRET_NAMES"; MYOS_SECRET_NAMES=$R
}

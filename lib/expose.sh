#shellcheck shell=sh
# shellcheck disable=SC3028  # HOSTNAME is a myos variable, set by bin/myos
# expose: which addresses a published port binds to.
#
# Docker writes its own firewall rules, so on linux a port published with
# `-p 8080:80` answers the internet whatever the host firewall says. ufw-docker
# patches that afterwards, on linux only, as root.
#
# The portable answer is to publish where you mean to in the first place:
# `-p 127.0.0.1:8080:80` only ever listens on the loopback, identically on
# linux and on macOS, with no firewall and no privilege. A stack says which
# scope a port belongs to, and myos resolves the address.
#
#   public   the internet: a load balancer, a public DNS or mail service
#   mesh     the private network between the hosts of the fleet
#   private  this host only: everything the load balancer reaches for you
#
# MYOS_BIND_<SCOPE> overrides any of them.

# myos_bind SCOPE  the address a port of that scope binds to
myos_bind() {
  case $1 in
    public)  printf '%s' "${MYOS_BIND_PUBLIC:-0.0.0.0}" ;;
    mesh)    printf '%s' "${MYOS_BIND_MESH:-$(myos_bind_mesh)}" ;;
    private|*) printf '%s' "${MYOS_BIND_PRIVATE:-127.0.0.1}" ;;
  esac
}

# myos_bind_mesh  the address of the mesh interface, empty when there is none.
# Falls back to the private address so that a stack scoped to the mesh on a
# host that has none stays local rather than becoming public.
myos_bind_mesh() {
  _if=${MYOS_MESH_IFACE:-}
  if [ -z "$_if" ]; then
    for _c in easytier tun0 tailscale0 mycelium wg0; do
      if myos_iface_addr "$_c" >/dev/null 2>&1 && [ -n "$(myos_iface_addr "$_c")" ]; then
        _if=$_c; break
      fi
    done
  fi
  [ -n "$_if" ] || { printf '%s' "${MYOS_BIND_PRIVATE:-127.0.0.1}"; return 0; }
  _a=$(myos_iface_addr "$_if")
  [ -n "$_a" ] || _a=${MYOS_BIND_PRIVATE:-127.0.0.1}
  printf '%s' "$_a"
}

# myos_iface_addr NAME  the first address of an interface, on linux or macOS
myos_iface_addr() {
  if myos_have ip; then
    ip -o addr show "$1" 2>/dev/null | awk '$3 ~ /^inet6?$/ {sub(/\/.*/,"",$4); print $4; exit}'
  elif myos_have ifconfig; then
    ifconfig "$1" 2>/dev/null | awk '$1 == "inet" || $1 == "inet6" {print $2; exit}'
  fi
}

# myos_stack_prefix REF  the prefix the settings of a stack use.
# A host stack is prefixed by HOST_, which is how the catalogue names them:
# HOST_FABIO_SERVICE_9998_TAGS, HOST_FTPS_UFW_DOCKER. Everything else uses the
# stack name alone: SUPABASE_KONG_SERVICE_8000_TAGS.
myos_stack_prefix() {
  _n=$(myos_upper "$(myos_stack_name "$1")")
  case $(myos_scope "$1") in
    host) printf 'HOST_%s' "$_n" ;;
    user) printf 'USER_%s' "$_n" ;;
    *)    printf '%s' "$_n" ;;
  esac
}

# myos_expose_scope PREFIX SERVICE PORT  the scope a stack declares for a port:
# <PREFIX>_SERVICE_<port>_EXPOSE, then <PREFIX>_SERVICE_EXPOSE, then the same
# two on the service name, else private
myos_expose_scope() {
  _u=$(myos_upper "$1")
  for _n in "${_u}_SERVICE_${3}_EXPOSE" "${_u}_SERVICE_EXPOSE" \
            "$(myos_upper "$2")_SERVICE_${3}_EXPOSE" "$(myos_upper "$2")_SERVICE_EXPOSE"; do
    _s=$(myos_var "$_n")
    [ -n "$_s" ] && { printf '%s' "$_s"; return 0; }
  done
  printf 'private'
}

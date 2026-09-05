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
# A stack does not declare its scope on the side: it is which of these it binds
# to, read from the compose file. One source of truth, which cannot drift from
# what is actually published. MYOS_BIND_<SCOPE> sets the address of a scope on
# a given host, which is the part that belongs to the host rather than to the
# stack.

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

# myos_expose_declared FILE...  SERVICE|CONTAINER_PORT|SCOPE for every port a
# compose file publishes, read from the file as written rather than from the
# resolved configuration.
#
# The scope is not declared twice: it is which binding the file asks for.
#   ${MYOS_BIND_PUBLIC}:443:443   public
#   ${MYOS_BIND_PRIVATE}::8080    private
#   ${MYOS_BIND_MESH}::7946       mesh
#   127.0.0.1:5432:5432           pinned to an address, deliberate but fixed
#   80  or  8080:80               unbound: docker binds every address, and
#                                 nobody chose that
#
# Resolving first would lose the difference: ${MYOS_BIND_PRIVATE} and a
# hand-written 127.0.0.1 both become 127.0.0.1, and an unbound port becomes
# 0.0.0.0 exactly like a deliberate public one.
myos_expose_declared() {
  awk '
    function emit(entry,   e, scope, target) {
      e = entry
      gsub(/^[ \t"'"'"'-]+/, "", e); gsub(/["'"'"']+$/, "", e)
      if (e ~ /\$\{MYOS_BIND_PUBLIC[^}]*\}/)       scope = "public"
      else if (e ~ /\$\{MYOS_BIND_MESH[^}]*\}/)    scope = "mesh"
      else if (e ~ /\$\{MYOS_BIND_PRIVATE[^}]*\}/) scope = "private"
      else if (e ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/) scope = "pinned"
      else if (e ~ /^\[/)                          scope = "pinned"
      else scope = "unbound"
      # the container port is the last field, minus any /protocol
      target = e
      sub(/\/[a-z]+$/, "", target)
      n = split(target, parts, ":")
      target = parts[n]
      if (target ~ /^[0-9]+(-[0-9]+)?$/) printf "%s|%s|%s\n", svc, target, scope
    }
    /^services:[ \t]*$/ { insvc = 1; next }
    insvc && /^  [a-zA-Z0-9_.-]+:[ \t]*$/ { svc = $1; sub(/:$/, "", svc); inports = 0 }
    insvc && /^    ports:/ { inports = 1; next }
    inports && /^    [a-zA-Z]/ { inports = 0 }
    inports && /^      *-/ { emit($0) }
  ' "$@"
}

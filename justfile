# myos: make your own stack. Every recipe forwards to the engine (lib/main.sh);
# `just --list` documents the verbs, the engine parses the arguments
# (references, KEY=VALUE, options), so `just up host` and `myos up host` are
# the same call.
set positional-arguments

lib := justfile_directory() / "lib"

# run a verb with any arguments: just run print-COMPOSE_FILE STACK=host/consul
[group('engine')]
run *args:
    @sh "{{lib}}/main.sh" "$@"

[group('stack')]
up *args:
    @sh "{{lib}}/main.sh" up "$@"

[group('stack')]
down *args:
    @sh "{{lib}}/main.sh" down "$@"

[group('stack')]
build *args:
    @sh "{{lib}}/main.sh" build "$@"

[group('stack')]
config *args:
    @sh "{{lib}}/main.sh" config "$@"

[group('stack')]
logs *args:
    @sh "{{lib}}/main.sh" logs "$@"

[group('stack')]
ps *args:
    @sh "{{lib}}/main.sh" ps "$@"

[group('stack')]
restart *args:
    @sh "{{lib}}/main.sh" restart "$@"

[group('stack')]
status *args:
    @sh "{{lib}}/main.sh" status "$@"

[group('stack')]
exec *args:
    @sh "{{lib}}/main.sh" exec "$@"

[group('catalogue')]
ls *args:
    @sh "{{lib}}/main.sh" ls "$@"

[group('catalogue')]
env *args:
    @sh "{{lib}}/main.sh" env "$@"

[group('lifecycle')]
bootstrap *args:
    @sh "{{lib}}/main.sh" bootstrap "$@"

# upgrade: backup, pull, build, up, then wait for the services to be healthy
[group('lifecycle')]
upgrade *args:
    @sh "{{lib}}/main.sh" upgrade "$@"

# backup: the volumes of the project into $MYOS_BACKUP_ROOT/<project>/<date>/
[group('lifecycle')]
backup *args:
    @sh "{{lib}}/main.sh" backup "$@"

# restore --from DIR|latest [--yes]: the volumes replaced from a backup
[group('lifecycle')]
restore *args:
    @sh "{{lib}}/main.sh" restore "$@"

# doctor: what this host and this project lack (exit 4 when a check fails)
[group('lifecycle')]
doctor *args:
    @sh "{{lib}}/main.sh" doctor "$@"

[group('stack')]
clean *args:
    @sh "{{lib}}/main.sh" clean "$@"

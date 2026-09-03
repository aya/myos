#shellcheck shell=sh
# Running the update twice must leave the same file: print how many lines it has.
myos_env_update "$1/.env" "$1/.env.dist" >/dev/null 2>&1
myos_env_update "$1/.env" "$1/.env.dist" >/dev/null 2>&1
wc -l < "$1/.env" | tr -d ' '

# Troubleshooting

| symptom | meaning | do |
|---|---|---|
| `unknown verb x (myos -h lists the verbs)`, exit 2 | the first word is neither a verb nor a reference, or an old target (`apps-install`, `deploy`) | `myos -h`; see commands.md for what the target became |
| `stack x not found (searched: ...)`, exit 3 | no directory of the path holds `x` | `myos ls`; install the catalogue (`install.sh --with-stacks`) or fix `MYOS_PATH` |
| `group expansion too deep (cycle?)` | a group names itself through its members | fix the `<group>=...` line of the `.env` |
| `settings: NAME refers to itself (cycle)` | a `.settings` line references its own name | rename the previous definition |
| `settings: compilation failed`, `file:line: not a setting` | a line of a `.settings` is not `NAME op expr` | fix the line; the language is in conventions.md |
| `.env.dist: X refers to itself` | a `.env.dist` key references itself | fix the template |
| `myos up . env-update ok (N keys added)` then a value is wrong | the `.env` was rendered from a stale template | edit `$WORKDIR/.env`: it is yours now; `myos env-update` only adds missing keys |
| `doctor ... env fail (missing from .env: ...)`, exit 4 | a new `.env.dist` key | `myos env-update <stack>`, then fill it |
| `doctor ... values warn (empty: X)` | a compose file references `${X}` and nothing sets it | set it in `.env` or the stack settings |
| `firewall ... audit fail (public ports of a stack that is not a host stack)`, exit 4 | a published port answers the world | bind it: `${MYOS_BIND_PRIVATE}:port:port` |
| `firewall apply ... skip (not a host stack)` | rules are only written for host stacks | see above |
| `cert: a wildcard needs dns-01` | a route uses `*.domain` | provide `actions/cert-dns` (dehydrated hook API) or `MYOS_CERT_DNS_HOOK`, run with `--wildcard`; or `--self-signed` meanwhile |
| `X is locked by another run`, exit 5 | an `upgrade` runs, or died | wait, or remove `$WORKDIR/.myos/lock.<project>` once sure |
| `restore ... is a backup of project other` | the manifest names another project | choose another `--from`, or `--force` knowingly |
| `restore replaces the volumes ...: run it with --yes` | not interactive | add `--yes` |
| `upgrade ... health fail (not healthy: db)`, exit 1 | a service did not reach running/healthy in `MYOS_HEALTH_TIMEOUT` | `myos logs <stack> SERVICE=db`; `myos restore <stack> --from latest --yes` to go back |
| containers named `tester-app-local` after an upgrade of myos | the project name format changed | `MYOS_PROJECT_FORMAT=user-app-env` in `.env` |
| `just: not found` in `doctor` | optional | `install.sh --with-just`; the engine works without it, justfile hooks do not |

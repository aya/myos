# Intentional differences between the make engine and the rewrite

`expected/` is the historical behaviour, recorded from the make engine and
never edited by hand. When the rewrite (`MYOS_ENGINE=just`) intentionally
behaves differently, the case gets a recording in `expected.just/<case>.txt`
(`MYOS_ENGINE=just spec/golden/record.sh <case>`) and a line here with the
reason. A delta without a line here is a regression. A case listed in
`pending.just` is not implemented yet and is skipped for that engine.

| Cases | Delta | Reason |
|---|---|---|
| every `up down build config logs ps restart ...` | no `make -o docker-stack-... ` echo line before the compose call | the rewrite does not re-run itself per stack |
| every `up` | `docker network create <n>` printed only when the network is missing, without the `sh -c ... >/dev/null 2>&1` wrapper | one `network ls` instead of two blind creates |
| `host-up-two`, `host-target`, `host-shutdown`, `cat-group-*-up`, `catalogue-group-*-up` | references naming the same project are one compose call with the union of their files | N identical calls with the whole list was a bug of the variable propagation |
| `app-*`, `nogit-*`, `inc-app-*` (wrapper mode) | the current directory is a stack (`.`): its compose files are loaded, the project is named after the directory (`tester-wd-local`), `APP`/`STACK` print the directory, `networks.yml` is added when the files use a framework network | one model: a project directory is a stack like any other |
| `cat-postgres-project`, `catalogue-*-files` (`COMPOSE_PROJECT_NAME`), `catalogue-cloud-nextcloud-vars`, `catalogue-redmine*-vars` (`<COMPOSE_SERVICE_NAME>-<db>`), `host-print-app`, `chain-print-two` | `print-COMPOSE_PROJECT_NAME STACK=x` names the project after `x` (`tester-postgres-local`), `print-APP` prints the stack name | in make, `print` looked at the myos checkout itself (`tester-myos-local`, `APP myos`) while `up` used the stack |
| `host-print-env-vars`, `cat-drone-env-vars`, `demo-print-env-vars` | `ENV_VARS` holds only the names the compose files of the stack reference | make included every `.mk` of every stack, so `DRONE_SERVER_HOST` leaked into every stack |
| `cat-unknown-stack` | `stack doesnotexist not found (searched: ...)`, exit 3 | make printed the framework overlay alone and exited 0 |
| `cat-unknown-target`, `host-deploy`, `inc-app-unknown-target` | `unknown verb`, exit 2, one line | same exit code, message of the rewrite |
| `cat-nginx-www-dns`, `catalogue-supabase-*` | overlay suffixes are sorted (`dns` before `www`); a file is loaded once | later `-f` wins, the order must not depend on the declaration order |
| `catalogue-group-default-up` | the `default` group of the project directory wins over the one of `~/.local/share` | the path is ordered by precedence; make kept the first definition of an alphabetically sorted list |
| `catalogue-*-files`, `catalogue-{drone,host-nginx,user}-vars` | no `cat: ...: Is a directory` noise | make read `$(CONFIG)/$(ENV)/$(APP)/.env` where APP was a directory |
| `chain-up-group` | `up ps host` runs `up` then `ps` on the `host` group only | in make `host` was also a target (`host: stack-host-up`), run after `up ps` on the checkout |
| `cmd-recreate`, `cmd-exec-*`, `cmd-run-catalogue`, `cmd-scale`, `cmd-status` | a reference given as a word (`exec host/consul -- consul members`) is accepted; `recreate` is `up -d --force-recreate` | make read the word as a target and failed |

# Where the rewrite stands

Branch `tdd`, pushed to github. The engine is the rewrite (`myos`, `lib/`,
`justfile`); the make engine it replaced is in the history (tag
`legacy-1.0-beta` for the untouched original, and the commits of this branch
up to "firewall and cert" for the corrected one the expectations were
recorded from).

Done: the model, the settings layer, `.env.dist` rendering, every compose
verb, `bootstrap build install clean attach`, `status backup restore upgrade
doctor firewall cert`, hooks, events, lock, the converter of the old
catalogue (`share/tools/mk2settings.py`, applied to `spec/fixtures/catalogue`).

Left (plan file `~/.wclaude/plans/je-souhaite-creer-un-whimsical-treasure.md`):
the real catalogue `myos-stacks` converted with the tool and its 85 `ports:`
bound on `${MYOS_BIND_*}`, `pre-backup` hooks for the database stacks,
dehydrated replacing certbot/acme, its remote created (with the user's
agreement); then the fleet: `MYOS_PROJECT_FORMAT=user-app-env` pinned in
every existing `.env`, the new version installed beside the old one, `-n up`
compared, the link switched.

Traps already paid for are listed in `AGENTS.md`.

# Intentional differences between the legacy make engine and the bash CLI

Golden expectations in `expected/` are recorded from the legacy engine
(`git tag legacy-1.0-beta`). When the CLI intentionally behaves differently,
the case gets an override in `expected.cli/<case>.txt` and a line here.

| case | delta | why |
|---|---|---|
| `myos_urlprefix` with several uris | the bash port joins tags with `,`, the make macro emits `tag ,tag` | the make template ends with ` $(2)` (options), so an empty option list leaves a space before the comma. Harmless but sloppy; every tag written by hand on the fleet uses the clean form. |
| `myos_urlprefix` with options passed inside the path argument | the bash port keeps `*` right after the path (`urlprefix-host:443/* proto=https`), the make macro appends it after the options (`urlprefix-host:443/ proto=https*`) | only reachable by stuffing options into argument 1, which the stale example in `make/apps/def.mk` did. Through `tagprefix`, the real code path, both engines agree. |

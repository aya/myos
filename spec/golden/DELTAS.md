# Intentional differences between the make engine and the rewrite

`expected/` is the historical behaviour, recorded from the make engine and
never edited by hand. When the rewrite (`MYOS_ENGINE=just`) intentionally
behaves differently, the case gets a recording in `expected.just/<case>.txt`
(`MYOS_ENGINE=just spec/golden/record.sh <case>`) and a line here with the
reason. A delta without a line here is a regression.

| Case(s) | Delta | Reason |
|---|---|---|

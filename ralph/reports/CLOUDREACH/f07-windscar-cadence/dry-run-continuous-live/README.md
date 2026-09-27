# F07#2 — DRY RUN (live combat) — does not count

This is the same command as `../dry-run-continuous/`, with `--live-combat` added. Every required fight is played by the balance lane's input pilot, from the challenge input through the real victory callback. The start is still the harness **fixture** (declared flags, a granted L25 five), so this is a DRY RUN under the finish-then-land rule.

| Windscar return (aerie landing → counterweight) | value |
|---|---|
| leg time (simulated) | 352.2 s |
| activity intervals | 37 |
| longest | **36.9 s** (A7 limit 120 s; recorded stretch 885.87 s) |
| open tail | 7.0 s |
| over limit | none |
| whole route so far, longest dead travel | 72.0 s |

`LEG PASS leg=windscar_return live`. Files: `windscar_return.json`, `events.json`, `verdict.txt`.
The counting run is `--from-save=<earned c1_arrival> --live-combat --accelerated --leg=windscar_return`.

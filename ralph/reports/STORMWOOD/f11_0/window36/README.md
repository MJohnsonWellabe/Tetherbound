# F11#0 Marrow press at break_window_seconds 36 — DRY RUN (does not count)

`tests/smoke_stormwood_marrow_press.gd` on tb/stormwood 5c1333ba. The start is a
fixture: flags staged up to `marrow_defeated`, a party of five at L46, and the
player placed at the Dynamo core anchor. So this is a DRY RUN and does not count.
It measures only whether the live piloted Break lap fits one window on the built
deck.

| Run | Result | Break windows used | Last 2 s sample before release |
|---|---|---|---|
| run1 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 9.2 s |
| run2 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 4.1 s |
| run3 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 8.3 s |

The helper allows one window (`MAX_BREAK_WINDOWS` 1), so every pass is a
single-window lap. For comparison, at 30 s the same smoke finished inside one
window on about half the runs (0.3–3 s misses), which is the evidence behind the
coordinator's ruling (#356, 02:40, option a).

# F11#0 Marrow press at break_window_seconds 36 — evidence with disclosed shortcuts

`tests/smoke_stormwood_marrow_press.gd` on tb/stormwood 5c1333ba. The start is a
fixture: flags staged up to `marrow_defeated`, a party of five at L46, and the
player placed at the Dynamo core anchor. It was first labelled a dry run. Under
the owner ruling of 2026-09-27 06:58 (#356), those shortcuts are disclosures,
not partials, and this is the F11#0 Marrow/Break witness (see the `closes F11#0`
post for the full shortcut list).

| Run | Result | Break windows used | Last 2 s sample before release |
|---|---|---|---|
| run1 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 9.2 s |
| run2 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 4.1 s |
| run3 | STORMWOOD MARROW PRESS OK, 0 SCRIPT ERROR | 1 | window_left 8.3 s |

The helper allows one window (`MAX_BREAK_WINDOWS` 1), so every pass is a
single-window lap. For comparison, at 30 s the same smoke finished inside one
window on about half the runs (0.3–3 s misses), which is the evidence behind the
coordinator's ruling (#356, 02:40, option a).

The run logs are committed as `.txt` because the repository ignores `*.log`.

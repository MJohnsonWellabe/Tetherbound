# F07#2 — DRY RUN — does not count

`tests/smoke_cloudreach_continuous.gd -- --accelerated --leg=windscar_return`
at tb/cloudreach f80cd473 plus the uncommitted leg option (committed with this
evidence). **Fixture start** (the harness's declared Meadows-complete flags and
an L25 granted five) and mechanics-only combat (test lethal seam). Under the
2026-09-27 finish-then-land rule this is a DRY RUN: it proves the path is ready,
not the criterion.

From the fixture start the whole continuous route ran by stick input over
collision with no position writes. It covered arrival, the lower anchors, Senn,
Maela, the aerie repair, the ring trial, the Fly-only High Roost and shrine, and
the return glide. It then walked to the grounded counterweight
(`cloudreach_act_ii_complete`).

| Windscar return (aerie landing → counterweight) | value |
|---|---|
| leg time (simulated) | 351.1 s |
| activity intervals | 38 |
| longest | **35.3 s** (A7 limit 120 s; the recorded stretch was 885.87 s) |
| open tail (last activity → arrival) | 7.0 s |
| over limit | none |
| whole route so far, longest dead travel | 94.5 s |

An ally was already deployed when the trainer landed, so the leg's
`creature_recall` send-out was not needed and no `companion_sent_out` row was
logged. Files: `windscar_return.json` (every interval), `events.json` (the full
harness log), `verdict.txt`.

**What counts:** the same command with
`--from-save=<earned c1_arrival> --live-combat`, once Cloudreach-B's earned
`c1_arrival` exists.

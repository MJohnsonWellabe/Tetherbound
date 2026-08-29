# X05 — stopped deliberately by the operator before its close, not crashed or blocked

**No `INVENTORY.json` and no `notes/X05.md` exist for this segment** — the
harness writes both at segment close, and this segment's Godot process was
terminated (`SIGTERM`, then confirmed dead) by the operator at `t=4262.6`
(play-seconds) / roughly 96 minutes of wall-clock, before reaching it. Its
raw `telemetry/events.jsonl` and `telemetry/route.csv` are real and
preserved; nothing was deleted or rewritten.

## Why the operator stopped it

X05 seeds from 16 saves in sequence: `S02-exit` through `S10-exit` (9),
two extra slot copies (`S06-exit`→slot 2, `S03-exit`→slot 3), and five
`X06-awkward-*.json` states. **`S10-exit.json` does not exist** (S10 hit its
own real cost-gate BLOCKER and never produced an exit save) and **none of
the five `X06-awkward-*.json` files exist** (X06 has never run in this run).
By the already-documented RIG-4 ("a `seed_save` whose source is missing does
not stop the segment"), each of these six missing-save blocks still pays its
full boot + 180-second settle-wait cost while producing nothing but a
predictable `FAIL seed source ... does not exist` and a stale-state replay.

By the time the operator checked in, **that exact pattern had already
reproduced four times in a row** (the `S10-exit` block and three of the five
`X06-awkward` blocks — `mid-Warrens`, `on-the-bridge`, and
`at-night-while-a-creature-is-bedded`), each costing several minutes of real
wall-clock for a FAIL this run already understood before X05 was launched.
Per the same reasoning the coordinator's brief applied to X06 ("once the
first two or three... reproduce the pattern, that is confirmation, not new
information — do not wait out a multi-hour blocker"), the operator judged
that letting the remaining ~2 awkward blocks and the final teardown run to
completion (an estimated 15-20 more minutes) would add no new information,
and stopped it there rather than burn the time.

**The 8 real `S0n-exit` blocks (S02 through S09) plus the two extra slot
saves (10 of the 16 `seed_save` points) DID complete before this decision**,
and are real, readable evidence — see below and
`GATE_F_RUN_3_FINDINGS.md`/`GATE_F_RUN_3_RIG_FINDINGS.md` for the write-up.
**This segment should be re-run in full** once healthy exit saves exist for
the whole chain (T2-BUILDPLACE/T2-STRANDING's fix landing) and X06 has
produced its five awkward saves — at that point every one of the 16 blocks
becomes real evidence rather than a mix of real evidence and a predictable
RIG-4 tail.

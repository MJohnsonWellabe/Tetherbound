# Stormwood lane (F09–F11) — work-order evidence

Live F-row verdicts belong in STATE (coordinator-owned). This file holds the lane's
work-order evidence; each work order updates its own section in place.

## Baseline check (main `49ef712f`)

Existing production, not rebuilt: Surge clock/phases, lightning with shelter/rod
safety, ancient and built Stormglass arches, harvests, pickups, camps, rod stations,
Crown heartstone/Rootgate, Dynamo and ending/Water gate, 26 trainers, 19 NPCs and the
Deepwood Circuit side chain (`BROAD-VISUAL-0910/STORMWOOD-DEEPWOOD-CIRCUIT01.md`).
The other five WORLD §11 chains lacked authored player interactions
(`BROAD-VISUAL-0910/STORMWOOD-SIDE-CHAIN-REMAINDER.md`).

Local environment: Godot 4.7-stable headless, Linux container, no GPU. The existing
`tests/smoke_stormwood_transition.gd` reaches `STORMWOOD READY` but fails its
Stormwood→Cloudreach return leg ("Cloudreach scene did not return from Stormwood")
on **unmodified** main in this container as well as on the work-order branch; it is
not a CI job. Recorded as an environment/timing observation, not a regression claim.

## WO-F10-01 — What the Crown Remembers (`stormwood_crown_remembers`)

- **Anchor:** F10 / ACCEPTANCE §6.1 F10 ("all six selected Stormwood chains satisfy §5
  with distinct lure/action/payoff/acknowledgement and persistent receipts"); WORLD §11
  Stormwood row "Read the three surviving records around grove, then speak to Wen".
- **Branch:** `ralph/stormwood-crown-remembers` from `49ef712f`.
- **Player result:** On the Crown island, three lit, glass-scored record stones around
  the heartstone grove (`scripts/world/stormwood_crown_records.gd`) offer "Read the
  Crown record". Each plays its own authored text (Rain Ledger, Root Census, burned
  reversal mark). The first read reveals progress; all three complete the reading;
  Wen then acknowledges the complete account (after, never instead of, the main truth
  conversation, and still after the Long Storm) and points to the existing Crown cache
  (`stormwood_pickup_pocket_203`, the authored TM, by Neri's watch). No new item or
  reward; the cache keeps its original one-time receipt. No main Heartstone/Rootgate
  flag is written.
- **State:** three world-scoped facts `stormwood:side_crown_remembers_record:<id>`
  (existing `stormwood:` world prefix), counted by the chain's existing step flags
  through the chapter's host-led realm-ledger writer. Steps 1/2 are count steps
  (1 of 3, 3 of 3); their aggregate events cannot be sent to skip the records.

| Criterion | Witness | Expected | Observed |
|---|---|---|---|
| Records count once, need all three, Wen completes; save/load | `tests/test_stormwood_crown_remembers.gd` | pass | 4 tests pass locally (see PR) |
| Wen branch never pre-empts truth; survives Long Storm | same, `test_wen_reports_records_only_after_truth_and_until_complete` | pass | pass |
| Seats on Crown island, flat, ≥6 m from baked trees/rocks, ≥8 m from pickups/NPCs/heartstone | same, `test_record_seats_are_clear_readable_island_ground` (real bake + heightfield) | pass | pass |
| Production prompt → conversation → ledger fact; locked before Crown; reread adds no revision; world save/load | `tests/smoke_stormwood_crown_records.gd` | OK | `STORMWOOD CROWN RECORDS OK: 22 assertions, 0 failures` |
| Real Stormwood scene mounts the records | `tests/smoke_stormwood_transition.gd` | `STORMWOOD READY` | READY, no script error (return leg fails identically on main; see above) |

**Limits:** No ordinary-play walk from an earned save; the Crown still requires the
arch route. No two-process peer run of this chain (world-scope writes use the same
realm-ledger path the Deepwood Circuit and heartstone use). Visual quality of the
record stones is not judged. The smoke is not yet a CI job (`.github/**` is shared).

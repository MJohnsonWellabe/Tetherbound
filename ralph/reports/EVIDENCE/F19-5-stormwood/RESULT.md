# F19#5 Stormwood part: checkpoint saves at each segment boundary

**Result: FAIL (blocked at piece 01). No Stormwood checkpoint was written.**

- Commits: runner `95a833d8` (attempt 1), `a007288a` (attempt 2), on main `9e39d008`.
- Start: `tests/fixtures/earned_saves/stormwood_arrival_generated` (disclosed generated arrival, `prior_earned_play: false`).
- Host: cloud container, 4 vCPU, Godot 4.7-stable headless.

## Runner (F19#5's own work)
`tools/earned_saves/stormwood_chain_runner.gd` uses the same piece protocol as `earned_chain_runner.gd`:
1. Fresh process per piece.
2. Copies the previous `save/` to scratch and loads it through the production title Load list (Autosave, slot 0).
3. Waits for ordinary world input, then runs one existing helper read-only.
4. Saves with `Game.save_game(0)`, then writes `save/`, `receipt.json` and `PROVENANCE.json` into an output dir that must not already exist.

Handoff check: the loaded state must match the previous receipt's `after` (UIDs in order, species, world/player flags, items, portal unlocks, realm). A mismatch refuses the piece before play.

The Meadows runner and `f49_disk_handoff.gd` only accept the Meadows piece list, which is why this is a separate runner.

Disclosed clock: 8x at 480 Hz, the same as `smoke_stormwood_continuous.gd`. Attempt 2 also used a 64-step frame cap.

## Executable piece order
The briefed order (Rootgate, Marrow, detour, Dynamo, crown, aftermath, handoff) does not match the helpers' preconditions. The runner uses the order that `smoke_four_biome_continuous.gd` and `f49_campaign_journey.gd` compose:

| # | Piece | Helper |
|---|---|---|
| 01 | arrival_prefix | `smoke_stormwood_continuous.gd` Segment |
| 02 | crown_build | |
| 03 | rootgate | |
| 04 | named_detour | |
| 05 | dynamo | |
| 06 | marrow | |
| 07 | settlement | `f49_stormheart_settlement.gd`, decline, keeps the five |
| 08 | home_key | `f49_portal_travel.home_key` |

`stormwood_earned_aftermath_segment.gd` (accepts the Stormheart and releases one member) is a side branch from 06. It is not the main line because it changes one UID and still asserts the old-order `realm_key_water`. `stormwood_earned_waterward_handoff.gd` crosses the retired Water gate, so it is a gap in the new order.

## Piece 01 failure (two attempts, same step)
Command:
`godot --headless --path . --script tools/earned_saves/stormwood_chain_runner.gd -- --segment=arrival_prefix --from=res://tests/fixtures/earned_saves/stormwood_arrival_generated --out=res://tests/fixtures/earned_saves/stormwood_01_arrival_prefix [--max-steps=64]`

What worked by ordinary input:
- Arrival set `chapter_started`.
- Hesk's dialogue set `crisis_learned`.
- Tamsin's dialogue completed.
- The player reached the Ashfoot shelter, sheltered from sim ~139 s.

Failure: `waiting under Ashfoot shelter through the production cycle did not witness the tutorial Break`.

Cause:
- The saved Surge clock is 0.54 s, and the Break starts at 330 s of Surge time (calm 240 s + building 90 s).
- The helper waits `BREAK_WAIT_MS = 120000` milliseconds of **wall** time.
- This host reached only about 1.1–1.3x sim while sheltered (attempt 2 watcher, see `attempt2_arrival_prefix.log`). The clock was at ~290 s when the wait expired.
- A rate probe of the loaded world measured about 7 ms per physics step: 1.74x sim at a 32-step cap and 2.25x at a 128-step cap.
- To meet the 120 s wall wait from sim ~139 s, the host would need about 1.6x sim while sheltered, and more from an earlier start.

No game defect was observed: the weather cycle, the shelter detection and the dialogue gates all behaved correctly.

## Gaps and proposed fix (needs coordinator decision; no test was changed)
- The prefix's `BREAK_WAIT_MS` wait, and the same wall-clock style of wait in later helpers, is a wall-clock capacity limit that this host cannot meet.
  - Proposal: measure that wait in Surge time, for example one full 510 s cycle of `realm_environment.stormwood.elapsed`.
  - Alternative: run the chain on a faster host.
- `stormwood_earned_waterward_handoff.gd` is old-order (Water gate). In the new order, the handoff is `f49_stormheart_settlement` followed by `home_key`.
- `stormwood_earned_aftermath_segment.gd` still expects `realm_key_water`, which may be a stale old-order assertion. Not run, because it is blocked behind 01.
- Pieces 02–08 were not run: each needs its predecessor's earned save.

## Round 2 (coordinator-approved Surge-time waits)
Commits: Surge-time waits `5222de42`; seam fixes `877ec87f`, `9a8b2643`.

**Surge-time waits: fixed.** The Ashfoot Break, first-seam and charged-window waits in the prefix, and the Crown Rodline Refuge wait, now budget one full Surge cycle of the waited region, with a physics-frame cap derived from that budget. Assertions are unchanged.

Piece 01 now earns:
- arrival (`chapter_started`)
- Hesk (`crisis_learned`)
- Tamsin
- the sheltered Break at Ashfoot (`first_break_witnessed`), at ~420 s of Surge time, because Cinder Verge's gentle calm runs 324 s
- the walk to the Verge rod clearing

**New blocker: the first charged Stormglass seam (`stormwood_harvest_cinder_verge_018`).**

- Fix attempt 1 (`attempt_fix_c.log`): the seam loop let every EncounterDirector prompt pass. The player stood at the road point through two whole Break/Fading windows.
- Fix attempt 2a (`attempt_fix_d.log`): the helper answered a held prompt with Engage. That showed the director's winning offer is the **non-actionable "Call out Bramblebun" hint** (RB, priority −1), not a wild, and pressing it starts no fight.
- Fix attempt 2b (`attempt_fix_e.log`): only an actionable Engage offer now holds the wait.
  - The player walks to the seam in Fading (open) and reaches all eight stance targets, each about 1 m from the prompt (radius 2.4 m).
  - The seam's Interactable still never offers. The arbiter falls back to the priority −1 hint, which it only picks when the harvest offers nothing.
  - Failure: `first charged Stormglass node never won the live InteractionArbiter ... winner=EncounterDirector offer=Call out Bramblebun ... body_distance=4.69`.
  - The player is pushed 2–5 m between consecutive stance walks.

Ruled out:
- The save has no `harvest_node:order:` taken flag for this node.
- `node_cycles` has no Stormwood site, so stock defaults to ready (day 16 ≥ 1).

Not yet known: why `interaction_offer` returns `{}` here. The candidates are a disabled prompt (Stormwood charged gating), blocked line of sight, or the 2–5 m displacement (lightning knockback or a body push). Finding out needs a live read-only probe at the seam. That would be a third attempt at this step, so it needs the coordinator's go-ahead.

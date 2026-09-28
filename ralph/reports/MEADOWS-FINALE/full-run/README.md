# Meadows M1–M4: one continuous headless run from a new game

This was one Godot process. It started a fresh new game on seed 15 and played through the Hall, the
M4 finale (the Warden, all three Veridian branches, the physical Rift) and into Cloudreach. It was
headless, with real controller input. The route ledger and the fight log observed the whole run.

- Result: **PASS**. Process exit 0. `failures: []`.
- `counts_as_proof: true`: it was not resumed and was not a dry run.
- `reached: cloudreach_arrived`.
- Runtime: 5937 s (99 min) wall.
- M4: 19 of 19 steps passed. Party size was at most 5 on every one of 24,821 watched frames. There
  were 6 title Loads.
- F04#4: `f04_4_witnessed: true`. All three Sigil captains and the Warden were won, each with hits
  dealt and with hits taken or avoided.

## Command (attempt 3 of 3)

```
cd <repo> && timeout 9000 godot --headless --path . \
  --script res://tests/smoke_four_biome_continuous.gd -- \
  --world-seed=15 --route-ledger --m4-finale --through-meadows --fight-log
```

- `--fight-log` loads the new observer `tests/helpers/meadows_earned_fight_log_segment.gd`.
  `--aftermath-capture` also loads it and turns on the rendered frames; see GPU-RUN-REQUEST.md.
  Without either flag, the helper is never loaded.
- Fresh path check: `_stage_fresh_through_hall` already chains to `_stage_warden_to_cloudreach`, and
  `--m4-finale` runs the finale helper there. No change was needed.
- The route ledger is an observer on `SceneTree.physics_frame`. It stayed running through the
  finale's title Loads and the Rift; it recorded 2 discontinuities. Its `stop` row was written after
  the Cloudreach arrival.
- Code:
  - The run started at `52c2dee0`, and helpers preloaded at start ran at that commit. Attempt 3
    passed the relay without the late-activation fix `59eea245`.
  - The finale helper loads lazily and is unchanged since `a6cf7ff6`.
  - The boundary receipts in the checkpoints carry `4c84aecd`. `commit_sha()` reads the checkout at
    export time, and HEAD moved during the run: `59eea245` relay, `9d6fc8a7` and `4c84aecd` team
    care. The team-care fixes were not loaded by this process.
- Checkpoints written: chapter-boundary exports `hall` (at 5073 s) and `c1_arrival`, under
  `user://four_biome_checkpoints_30299_7477/`. There are no reload-transition checkpoints, because
  attempt 3 ran without `--reload-at-transitions`.

## Attempts

| # | Command difference | Outcome |
|---|---|---|
| 1 | Added `--reload-at-transitions` | FAIL at Captain Vance, 2981 s. "Physical Interact activated a different provider" named the same path and instance id for wanted and got: the activation landed after `_tap` returned. The reloads at `rested_team`, `south_bridge_crossed` and `warrens_cleared_and_exited` all held (flags 59→59, 75→75, 84→84; party and inventory equal) |
| 2 | Same as 1 | The same failure at Vance. The same three reloads held |
| 3 | The command above | **PASS** |

- Debug pieces from the earned checkpoints: warrens→relay passed once and failed once from the
  run-1 checkpoint, and failed once from the run-2 checkpoint. A relay→Hall piece lost to Oreth on
  the run-1 lineage, which had a weaker party.
- The harness fix was requested in `SHARED-FILE-REQUEST-relay-late-activation.patch`. The
  coordinator applied it as `59eea245`.

## Per-card expected vs observed

"Evidence" means the lines in `full-run-log.txt` unless another file is named.

### M1 opening and village: PARTIAL (the ordered opening passes; the other clauses are not in this run)

| ACCEPTANCE §6 M1 clause | Observed in this run |
|---|---|
| Fresh controller run completes starter, naming, real practice fight/catch, camp, three-bed tournament consent and three played bracket rounds **in the specified order** | **PASS**. `GATE A OPENING`: title, name prefill, starter terrapup picked and named, real Bramblebun fight weakened to 28/106 and live catch with earned orbs, village key through the real gate. `GATE A NPC/GATHER`: Mira/Tam tools and three tool gathers. Materials, then camp, then rest (`FRESH STAGE RETURN` passed). Ledger beats `creature_bed_built`, `_2` and `_3`. `EARNED TOURNAMENT`: Mira (2 defeats), Tam (2) and Oskar (3) won. Ledger stage order: opening → road_gate → village → earned_team → paid_camp → rested_team → tournament_won |
| WORLD §3.2 through-road and side lane; overhead plan; day/night ordinary-camera walk; every gate, NPC and interaction | Not measured here. This run walks one route. It has no overhead plan and no day/night walk |
| Save/reload at M1 | Not in attempt 3. Attempts 1 and 2 held the `rested_team` reload |
| Two-peer layout agrees | Not in this run (solo) |
| All three starters have an opening-to-bridge witness | Terrapup only |

### M2 earned spine and economy: FAIL on spacing/A7 as read strictly; the rest of this run passes

| ACCEPTANCE §6 M2 clause | Observed |
|---|---|
| One fresh save reaches Cloudreach through every §6 gate without teleport/state injection | **PASS**, with the M4 shortcuts listed below. Bridge (key reward), Quarry/Warrens guardian, relay captain, captive, relay disabled (18→0 lit), mill crossing, Oreth/Halder/Vess, Sigil Gate, Hall gauntlet, Warden, Rift. `counts_as_proof: true` |
| No mandatory wild replay | **PASS**. `solvency.repeated_wilds: []` |
| Two-loss and four-character ledgers solvent (PROGRESSION §6) | Two-loss **PASS**: `reserve_ok: true`; the lowest two-loss margin was 28 coin at `rested_team`. Four-character: **not computed** (the ledger says it needs harvest totals or a four-peer run) |
| Save/reload at bridge, relay, Sigils and aftermath keeps exact world and personal rewards | Aftermath: **PASS** (M4 steps 2_offer_survives_reload, 3R_after_reload, 5A_after_reload). Bridge: PASS in attempts 1 and 2. Relay: PASS in the debug piece. **Sigils: not reloaded in any piece** |
| No A7 empty route interval or WORLD §3.1 beat-spacing violation remains (F02#7) | See the F02#7 section below. **FAIL, strict reading**: two windows over 250 m and one A7 interval of 264 s |

### M3 fights, activities and presentation: PARTIAL (only the F04#4 hit/avoidance part is covered)

| Clause | Observed |
|---|---|
| Relay officers and Warden show actual hit/avoidance (plus the three captains, F04#4) | **Logged**. See the F04#4 table. Every logged fight has hits dealt and hits taken or avoided |
| Warrens guardian hit/avoidance | Not logged: it is a wild guardian, and the observer logs trainer battles. The Warrens helper's receipt shows `guardian: true`, 18 hits and 2 switches |
| Distinct readable tells at the normal fight camera; C2/C3; blind fight-footage verdict; ≥6 activities; Bars A/B | Not measured. Headless has no camera evidence, and F04#6 frames are requested in GPU-RUN-REQUEST.md |

### M4 finale and handoff: READY for the solo clauses (the two-peer clauses rest on separate evidence)

| ACCEPTANCE §6 M4 clause | Observed (`m4-result.json`, `M4 PASS` lines) |
|---|---|
| A full five may accept or refuse Veridian without accidental release or a sixth slot | **PASS**. 3R refused at the prompt; 4C accepted, then let the newcomer go; 5A accepted and released the lowest (bramblebun L16), and Veridian L22 joined. Max party 5 on all 24,821 frames |
| Solo refusal yields the herd display | **PASS** (3R and 4C) |
| Mixed two-peer decisions and reconnect keep each character's once-only result | Not in this run. See the existing `coop-veridian-choices*.txt`, `full-refusal-two-peer.txt` and `relic-key-durable-two-peer.txt` in this directory's parent |
| The world heals; relic/key durable; gate opens exactly once | **PASS**. Healing 1963 blooms and 168 cables hidden. Key and heart set. `openings()==1` and `crossings_fired()==1` |
| The same saved five enter Cloudreach through the physical crossing | **PASS** (6_cloudreach_same_five) |

## F02#7: route spacing and A7 over the whole route (fresh → Cloudreach)

Ledger: `route_ledger_30299_7477.jsonl.txt`. It records 15,499 m walked, 4,976 game seconds, 1,513
beats, 13 stage receipts and 2 discontinuities (the finale's save restores and title Loads).

| Reading | Windows over 250 m | A7 over 120 s |
|---|---|---|
| Ledger raw beats | 1: 293.8 m in the finale, from the Hall chamber (0,7650) to (−29,7442) | 0. The longest was 62.0 s, in `earned_team` |
| Ledger `strict` beats (326 strict; median 20.6 m) | 2: **836.7 m** in `earned_team`, and 326.5 m after the finale | 1: **264.0 s**, the same `earned_team` window |
| `strict2.py 200` (tightened) | 4 over 200 m, of which 2 are over 250 m | `[264.0]` |

The four `strict2.py 200` windows:

1. **837 m**, stage `earned_team`, from `tournament_training_ready` at (60,81) to
   `home_materials_gathered` at (73,64). The harness's home-materials gathering loop around the
   village walked 837 m with only harvest beats, which strict filtering drops. This is also the
   264 s A7 interval. Attempt 2 walked the same window as 320 m, so the length depends on the
   gathering path.
2. 203 m, `earned_team`, `creature_bed_built` → `creature_bed_built_2` (camp bed build).
3. 211 m, `earned_team`, `creature_bed_built_2` → `creature_bed_built_3`.
4. **326 m**, stage `warden_arena_entered` (the finale), `Ride Veridian Stag` →
   `BandPickup_b5_candy_doorstep_a`. This is the finale's harness walk from the Hall back toward the
   Sigil Gate for the Rift (M4 route B15).

For comparison, attempt 2's fresh-to-Warrens ledger (strict2 at 200 m) had three windows over
200 m, one over 250 m (320 m, same village window) and no A7 interval over 120 s.

The windows between the bridge and the Hall (Quarry, relay, band5 spine, captains) are all under
200 m in the strict reading. Both remaining violations are harness walks: the village gathering loop
and the post-finale walk back. Whether either counts as a route violation is a reading for the
coordinator. They are reported, not dismissed.

## F04#4: hit/avoidance per captain and the Warden

| Fight | Outcome | Duration | Rounds | Hits dealt (damage) | Hits taken (damage) | Avoided (while moving) | Tells (hit / avoided / unresolved) |
|---|---|---|---|---|---|---|---|
| `captain_riverwatch` (Oreth) | won | 67.5 s | 3/3 | 55 (604.0) | 3 (40.4) | 15 (13) | 27 (3 / 15 / 9) |
| `captain_field` (Halder) | won | 70.3 s | 3/3 | 53 (618.2) | 6 (105.6) | 14 (12) | 28 (6 / 14 / 8) |
| `captain_ridge` (Vess) | won | 57.1 s | 3/3 | 48 (575.9) | 5 (84.7) | 9 (9) | 16 (5 / 9 / 2) |
| `warden_aldis` | won | 115.7 s | 5/5 | 99 (1160.8) | 21 (446.5) | 4 (3) | 35 (21 / 4 / 10) |

Other trainer fights on the route were logged too. Each one was won with hits dealt and with hits
taken or avoided:

| Fight | Hits dealt | Hits taken | Avoided | Duration |
|---|---|---|---|---|
| `relay_captain` (Vance) | 48 | 1 | 17 | 65.2 s |
| `south_bridge_grunt` | 42 | 6 | 8 | 48.2 s |
| `stronghold_patrol` | 37 | 10 | 4 | 46.5 s |
| `stronghold_courtyard` | 61 | 6 | 19 | 83.0 s |
| `stronghold_elite` (Hald) | 74 | 18 | 0 | 75.2 s |
| Three tournament rounds | see `fight-log.jsonl.txt` | | | |

How the log is read:

- Signals come from the production `CombatManager`: `hit_landed(on_enemy, amount)`,
  `attack_missed(by_player)` and `staggered`.
- The enemy body's `telegraph_started(seconds)` marks a tell.
- A tell resolves as "hit" at the next hit taken and as "avoided" at the next enemy miss; otherwise it
  is "unresolved" after 3 s.
- COMBAT has no dodge button ("movement is the dodge"), so an avoidance is `attack_missed(false)`.
  "While moving" means the ally's ground speed was above 0.5 m/s at that moment.
- Every avoidance followed a tell (avoided equals tells_avoided).
- The pilot is the harness's `CampaignPilot`, not a person.
- Full per-event rows, with time, ally-enemy distance and ally speed, are in `fight-log.jsonl.txt`.

## F04#6: aftermath captures

Headless, so no frames were captured. `--aftermath-capture` saves `user://aftermath/<fight>-a<n>.png`
plus a sidecar JSON 0.75 s after each captain and Warden fight resolves. A local xvfb/opengl3
self-test saved a 1280x720 PNG and its sidecar through the same code path. The self-test used a
synthetic scene, not a fight. The coordinator's request, with what every frame must show, is in
`GPU-RUN-REQUEST.md`.

## Disclosed shortcuts

These follow the owner ruling of 06:55. They are the same as the M4 README's shortcuts 2–5. The
declared start save (M4 shortcut 1) does **not** apply: this run started from a new game.

1. **Title Loads.** The harness calls `change_scene_to_file` to reach the title scene, and presses the
   title's Load and "Save N" buttons with `pressed.emit()`. There were 6 title Loads.
2. **Branch starts (C and A).** Both started from a byte copy of the game's own offer-open slot-2
   save. Branch A is the branch that walks into Cloudreach, so the Cloudreach entry follows a restore
   of that save (unmodified bytes).
3. **Kell acknowledgement skipped (B13).** The production Rift admits on `realm_key_cloudreach` only.
   `meadows_acknowledged` was absent.
4. **Finale route.** From the Hall exit, the harness walked the band5 spine back to the Sigil Gate
   north point, then the storm-road points north of the gorge (B15), then over the span.
5. **Satchel care.** Before the Warden and before the Hall exit, the harness used care through the
   real Satchel seam (receipt `bench_care`). Team care between fights also used the production seam.
6. **No reload at transitions in attempt 3.** The reload-at-transition checks come from attempts 1
   and 2 (rested_team, bridge, Warrens) and from the relay debug piece. The Sigil transition was not
   reloaded in any piece.
7. **The walker is the harness.** Its detours, gathering loop and waits shape the spacing and A7
   numbers.

## Files

- `full-run-log.txt`: the trimmed attempt-3 log. It has the `GATE A`, `EARNED *`, `ROUTE LEDGER`,
  `FIGHT LOG` (events trimmed), `M4 PASS`, `M4 RESULT`, `FOUR BIOME CHECKPOINT` and
  `FRESH CAMPAIGN RESULT` lines.
- `route_ledger_30299_7477.jsonl.txt`: the full route ledger.
- `fight-log.jsonl.txt`: every `FIGHT LOG` row in full.
- `m4-result.json`: the full `M4 RESULT`.
- `GPU-RUN-REQUEST.md`: the F04#6 render request for the coordinator.
- `SHARED-FILE-REQUEST-relay-late-activation.patch`: the relay harness fix, applied as `59eea245`.

# CI-SEGMENTS coverage map: old assertion → segment

Owner request (2026-10-04): "Break the long parts of ci up …". Every assertion
the old continuous runs made must still be made by some segment or handoff
check. This map says where each one now runs. Branch `tb/ci-segments`.

## 1. midride: `verify-cloudreach-midride-rejoin` (two-peer F06#6)

The old job ran `tools/net/proof_scenarios/f06_cloudreach_midride_rejoin.json`
as one ~17 min step. `tools/ci/segments/split_midride.py` copies every original
step, unchanged apart from `peer` remapping in the one-peer setup producers,
into five segment scenarios under `tools/net/proof_scenarios/segments/midride/`.
Each copied step carries `_comment: "orig #N"`. Steps the split adds carry
`SEGMENT: …`: the start from a checkpoint, the re-host and re-join, and the end
checkpoint.

**Mechanical proof:** `tools/ci/segments/check_coverage.py` (run in
`verify-segment-handoffs`, chain midride) fails unless each check holds:

- every original (step, peer) instance runs exactly once across the segments;
- each copy is byte-equal to the original step apart from `peer` and `_comment`;
- each segment keeps the original order.

Current result: `COVERAGE OK: 119 original (step, peer) instances … each run
exactly once across 5 segments`.

**Boundaries.** Each boundary has a contract in `tests/helpers/ci_segments.gd`
and a checkpoint under `tests/fixtures/segments/midride/`:

| Boundary | Producer end (asserts contract + reproduces committed digest) | Consumer start (asserts fresh + contract) |
|---|---|---|
| `midride/setup` host, guest | `s0_setup_host`, `s0_setup_guest`: `seg_checkpoint` | `s1_ride_a`: `seg_verify` + `load_save` + `seg_contract` (host), `seg_seed_home` (guest) |
| `midride/after_a` host, guest | `s1_ride_a`: `capture_saves` + `seg_checkpoint` | `s2_ride_b`: same |
| `midride/after_b` host, guest | `s2_ride_b`: orig #91's own `capture_saves` + `seg_checkpoint` | `s3_control`: same |

Per-step map (generated from the scenario files):

| # | Peer | Step | Expect | Segment (original peer) |
|---|---|---|---|---|
| 1 | all | legacy_physical_crossings_fixture — disclosed retired realm-key crossing fixture; shipping flag remains off | PASS | s0_setup_guest (peer 1), s0_setup_host (peer 0) |
| 2 | all | boot — each peer boots its own fresh Meadows world | PASS | s0_setup_guest (peer 1), s0_setup_host (peer 0) |
| 3 | all | story_flag — setup: both worlds hold the Cloudreach key | PASS | s0_setup_guest (peer 1), s0_setup_host (peer 0) |
| 4 | 1 | story_flag — setup: ONLY the guest's own world has the upper counterweight route open | PASS | s0_setup_guest (peer 1) |
| 5 | 1 | party_grant — setup: guest party_grant meadowhart (its ground mount, first = active) | PASS | s0_setup_guest (peer 1) |
| 6 | 1 | party_grant — setup: guest party_grant bramblebun | PASS | s0_setup_guest (peer 1) |
| 7 | 1 | party_grant — setup: guest party_grant terrapup | PASS | s0_setup_guest (peer 1) |
| 8 | 1 | party_grant — setup: guest party_grant brooktail | PASS | s0_setup_guest (peer 1) |
| 9 | 1 | party_grant — setup: guest party_grant mudsnout | PASS | s0_setup_guest (peer 1) |
| 10 | 1 | storage_grant — setup: a saddle in the guest's satchel (not pre-fitted: mount() fits it) | PASS | s0_setup_guest (peer 1) |
| 11 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | s0_setup_host (peer 0) |
| 12 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | s0_setup_guest (peer 1) |
| 13 | 1 | assert — guest owns five | PASS | s0_setup_guest (peer 1) |
| 14 | 1 | save_character_here — guest saves its own world (gate open) + portable character at the Cloudreach arrival | PASS | s0_setup_guest (peer 1) |
| 15 | 0 | host | PASS | s1_ride_a (peer 0) |
| 16 | 0 | assert — host world: gate CLOSED before the join | FAIL | s1_ride_a (peer 0) |
| 17 | 1 | production_join — guest continues its own save through the title's production join | PASS | s1_ride_a (peer 1) |
| 18 | all | expect_peers | PASS | s1_ride_a (peer 0), s1_ride_a (peer 1) |
| 19 | 1 | assert — JOIN: guest now reads the host's closed gate | FAIL | s1_ride_a (peer 1) |
| 20 | 1 | probe player_identity — JOIN: guest in Cloudreach, five owned | PASS +data | s1_ride_a (peer 1) |
| 21 | 1 | teleport — A setup: guest on the arrival landing (the authored arrival itself) | PASS | s1_ride_a (peer 1) |
| 22 | 1 | deploy_creature — A: the guest's Meadowhart is out (already out, or summoned by the director) | PASS | s1_ride_a (peer 1) |
| 23 | 1 | ride_mount — A: guest mounts its Meadowhart (production mount(); harness stands it 1.2 m beside the ... | PASS | s1_ride_a (peer 1) |
| 24 | 1 | probe riding — A: guest is riding its own saddled Meadowhart | PASS +data | s1_ride_a (peer 1) |
| 25 | 1 | move_to — A: guest rides onto the arrival road (real stick) | PASS | s1_ride_a (peer 1) |
| 26 | 1 | move_to — A: guest rides up the road centreline | PASS | s1_ride_a (peer 1) |
| 27 | 1 | assert — A: the ride covered the ~20 m to the waypoint | PASS | s1_ride_a (peer 1) |
| 28 | 1 | probe riding — A: still mounted just before the drop | PASS +data | s1_ride_a (peer 1) |
| 29 | 1 | probe flying — A: trainer carried by the mount before the drop | PASS +data | s1_ride_a (peer 1) |
| 30 | 1 | probe position — A: ride pose before the drop | PASS | s1_ride_a (peer 1) |
| 31 | 1 | probe tournament — A: party ids before the drop | PASS | s1_ride_a (peer 1) |
| 32 | 1 | probe deployed_creatures — A: guest's deployed bodies before the drop | PASS | s1_ride_a (peer 1) |
| 33 | 0 | probe riding — A: host's view of the guest riding before the drop | PASS | s1_ride_a (peer 0) |
| 34 | 0 | probe deployed_creatures — A: host's deployed bodies before the drop | PASS | s1_ride_a (peer 0) |
| 35 | 1 | drop_link — A: guest's link drops MID-RIDE | PASS | s1_ride_a (peer 1) |
| 36 | 0 | expect_peers | PASS | s1_ride_a (peer 0) |
| 37 | 1 | probe input_context — A: the dropped guest is back at the title | PASS | s1_ride_a (peer 1) |
| 38 | 0 | probe deployed_creatures — A: host after the drop: the guest's proxies are gone | PASS | s1_ride_a (peer 0) |
| 39 | 1 | production_join — A: guest rejoins from the title as the same character (returning route) | PASS | s1_ride_a (peer 1) |
| 40 | all | expect_peers | PASS | s1_ride_a (peer 0), s1_ride_a (peer 1) |
| 41 | 1 | wait | PASS | s1_ride_a (peer 1) |
| 42 | 1 | probe player_identity — A: identity after rejoin: same character, five owned | PASS +data | s1_ride_a (peer 1) |
| 43 | 1 | probe tournament — A: party ids after rejoin (compare with the row before the drop) | PASS | s1_ride_a (peer 1) |
| 44 | 1 | probe riding — A: rider state after rejoin: NOT mounted (no phantom ride) | PASS +data | s1_ride_a (peer 1) |
| 45 | 1 | probe flying — A: trainer on its own feet on a floor, not carried, not flying | PASS +data | s1_ride_a (peer 1) |
| 46 | 1 | probe on_floor — A: on_floor | PASS | s1_ride_a (peer 1) |
| 47 | 1 | probe position — A: position after rejoin | PASS | s1_ride_a (peer 1) |
| 48 | 1 | assert — A: guest is NOT inside sealed Upper Cloudreach | FAIL | s1_ride_a (peer 1) |
| 49 | 1 | assert — A: guest authored-arrival placement (recorded, not asserted) -- placement provenance de... | any | s1_ride_a (peer 1) |
| 50 | 1 | probe deployed_creatures — A: guest's deployed bodies after rejoin (one local Meadowhart at most) | PASS | s1_ride_a (peer 1) |
| 51 | 0 | probe deployed_creatures — A: host's deployed bodies after rejoin (one proxy of the guest's companion at most) | PASS | s1_ride_a (peer 0) |
| 52 | 0 | probe riding — A: host's view of the rejoined guest (remote row: riding/carried expected false; judged... | PASS | s1_ride_a (peer 0) |
| 53 | 0 | assert — A: host world flags unchanged | FAIL | s1_ride_a (peer 0) |
| 54 | 1 | assert — A: guest reads the host's closed gate after rejoin | FAIL | s1_ride_a (peer 1) |
| 55 | 1 | deploy_creature — A: companion out after rejoin | PASS | s1_ride_a (peer 1) |
| 56 | 1 | ride_mount — A: the same Meadowhart can be mounted again (no stuck/phantom ride state) | PASS | s1_ride_a (peer 1) |
| 57 | 1 | probe riding — A: remounted its own Meadowhart | PASS +data | s1_ride_a (peer 1) |
| 58 | 1 | ride_dismount — A: and dismounts onto ground | PASS | s1_ride_a (peer 1) |
| 59 | 1 | assert — A: still five after remount/dismount | PASS | s1_ride_a (peer 1) |
| 60 | 1 | teleport — B setup: guest on the counterweight pass, ~120 m below the closed gate, legal (windscar... | PASS | s2_ride_b (peer 1) |
| 61 | 1 | wait | PASS | s2_ride_b (peer 1) |
| 62 | 1 | probe position — B: pose on the pass | PASS | s2_ride_b (peer 1) |
| 63 | 1 | probe on_floor — B: on the pass floor | PASS | s2_ride_b (peer 1) |
| 64 | 1 | deploy_creature — B: Meadowhart out (the follower reappears beside a teleported trainer) | PASS | s2_ride_b (peer 1) |
| 65 | 1 | ride_mount — B: guest mounts on the pass | PASS | s2_ride_b (peer 1) |
| 66 | 1 | move_to — B: rides up the pass to its bend | PASS | s2_ride_b (peer 1) |
| 67 | 1 | move_to — B: rides toward the closed gate (17 m short) | PASS | s2_ride_b (peer 1) |
| 68 | 1 | move_to — B: rides INTO the closed gate: cannot reach the far side | FAIL | s2_ride_b (peer 1) |
| 69 | 1 | probe riding — B: still mounted against the gate | PASS +data | s2_ride_b (peer 1) |
| 70 | 1 | probe position — B: ride pose at the gate before the drop | PASS | s2_ride_b (peer 1) |
| 71 | 1 | assert — B: the ride did not pass the closed gate | FAIL | s2_ride_b (peer 1) |
| 72 | 1 | probe tournament — B: party ids before the drop | PASS | s2_ride_b (peer 1) |
| 73 | 1 | drop_link — B: guest's link drops MID-RIDE at the closed gate | PASS | s2_ride_b (peer 1) |
| 74 | 0 | expect_peers | PASS | s2_ride_b (peer 0) |
| 75 | 1 | probe input_context — B: dropped guest is at the title | PASS | s2_ride_b (peer 1) |
| 76 | 1 | production_join — B: guest rejoins from the title (returning route; its own world has the gate OPEN) | PASS | s2_ride_b (peer 1) |
| 77 | all | expect_peers | PASS | s2_ride_b (peer 0), s2_ride_b (peer 1) |
| 78 | 1 | wait | PASS | s2_ride_b (peer 1) |
| 79 | 1 | probe player_identity — B: identity after rejoin | PASS +data | s2_ride_b (peer 1) |
| 80 | 1 | probe tournament — B: party ids after rejoin | PASS | s2_ride_b (peer 1) |
| 81 | 1 | probe riding — B: NOT mounted after rejoin | PASS +data | s2_ride_b (peer 1) |
| 82 | 1 | probe flying — B: on its own feet on a floor | PASS +data | s2_ride_b (peer 1) |
| 83 | 1 | probe position — B: position after rejoin | PASS | s2_ride_b (peer 1) |
| 84 | 1 | assert — B: NOT past the closed gate on the pass | FAIL | s2_ride_b (peer 1) |
| 85 | 1 | assert — B: NOT inside sealed Upper Cloudreach | FAIL | s2_ride_b (peer 1) |
| 86 | 1 | assert — B: authored-arrival placement (recorded, not asserted) -- placement provenance depends ... | any | s2_ride_b (peer 1) |
| 87 | 1 | assert — B: guest reads the host's closed gate (its own world's open flag did not leak) | FAIL | s2_ride_b (peer 1) |
| 88 | 0 | assert — B: host world flags unchanged | FAIL | s2_ride_b (peer 0) |
| 89 | 1 | probe deployed_creatures — B: guest's deployed bodies after rejoin | PASS | s2_ride_b (peer 1) |
| 90 | 0 | probe deployed_creatures — B: host's deployed bodies after rejoin | PASS | s2_ride_b (peer 0) |
| 91 | all | capture_saves | PASS | s2_ride_b (peer 0), s2_ride_b (peer 1) |
| 92 | 0 | check_saved — host's saved world: gate still closed | PASS | s2_ride_b (peer 0) |
| 93 | 1 | check_saved — guest's saved character: Cloudreach, Meadowhart owned | PASS | s2_ride_b (peer 1) |
| 94 | 0 | story_flag — CONTROL setup: the host opens the gate | PASS | s3_control (peer 0) |
| 95 | 1 | wait_flag | PASS | s3_control (peer 1) |
| 96 | 1 | teleport — CONTROL setup: guest past the now-open gate | PASS | s3_control (peer 1) |
| 97 | 1 | wait | PASS | s3_control (peer 1) |
| 98 | 1 | deploy_creature | PASS | s3_control (peer 1) |
| 99 | 1 | ride_mount — CONTROL: guest mounts past the open gate | PASS | s3_control (peer 1) |
| 100 | 1 | stick — CONTROL: rides a few metres | PASS | s3_control (peer 1) |
| 101 | 1 | probe riding — CONTROL: mounted before leaving | PASS +data | s3_control (peer 1) |
| 102 | 1 | probe position | PASS | s3_control (peer 1) |
| 103 | 1 | leave — CONTROL: guest leaves mid-ride (clean leave, world scene kept) | PASS | s3_control (peer 1) |
| 104 | 0 | expect_peers | PASS | s3_control (peer 0) |
| 105 | 1 | join — CONTROL: guest rejoins the open world | PASS | s3_control (peer 1) |
| 106 | all | expect_peers | PASS | s3_control (peer 0), s3_control (peer 1) |
| 107 | 1 | wait | PASS | s3_control (peer 1) |
| 108 | 1 | probe player_identity — CONTROL: five owned | PASS +data | s3_control (peer 1) |
| 109 | 1 | probe riding — CONTROL: rider state after a clean mid-ride leave/join (recorded) | PASS | s3_control (peer 1) |
| 110 | 1 | probe position — CONTROL: position | PASS | s3_control (peer 1) |
| 111 | 1 | assert — CONTROL: with the gate open the rejoined guest DOES stand past it (the 'not sealed' che... | PASS | s3_control (peer 1) |

## 2. bracket: `tests/smoke_tournament_bracket.gd` (in `verify-gate-evidence-finale`)

The old leg ran the whole bracket in one process. Now:

| Old assertion (smoke header numbering) | Segment |
|---|---|
| 1. A party too small meets the CLOSED line; no entry flags | `bracket-to-semi` |
| 2. Under-levelled party meets the TRAIN line | `bracket-to-semi` |
| 3. Qualifying party: team/training ready written by `tournament.gd`; condition branch; registration through Halda's modal; care explanation; condition ready | `bracket-to-semi` |
| 4. Sign-up sets `tournament_entered`; board text changes | `bracket-to-semi` |
| 5. Quarter-final LOST on purpose: still on offer, nothing consumed, no flag, entrants healed, entry care kept | `bracket-to-semi` |
| 6–7. Quarter-final and semi-final fought and won by real input: every authored creature felled, won flag, exact coins, toast, board | `bracket-to-semi` |
| 6–7. Final fought and won: same per-round checks | `bracket-final` |
| 8. `tournament_won`, `recipe_saddle` granted and the recipe known | `bracket-final` |
| 9. Champion line, and greeting again pays nothing / starts no fight | `bracket-final` |

Both segments run the same per-round code (`_fight_and_win`, `_open_the_round`
with its registered-three, ownership and field checks). The no-flag run is
unchanged and still plays the whole bracket. The handoff in between
(`bracket/after_semi`) has four guards:

- end of `to-semi`: `Game.save_game(0)`, then `check_produced` (contract plus
  committed digest);
- start of `final`: `check_start` (fresh plus contract), then `Game.load_game(0)`,
  then the contract again on the live game;
- `verify-segment-handoffs`, chain bracket;
- the contract also requires the three registered entrants, so the save path
  for the final's entry is exercised for real, not assumed.

## 3. Jobs split onto parallel legs (independent steps, same commands)

These were never continuous chains: each step is its own Godot process. Each
step keeps its command; only its matrix `if:` changed, so it runs on exactly
one leg.

| Old job (leg) | Step | New leg |
|---|---|---|
| verify-gate-evidence-shard | post-miss wander aim lifecycle; stick navigator slope/obstacle; gate_a_opening_segment | `opening` |
| verify-gate-evidence-shard | gate_a_build_house; build_two_creature_beds; gate_a_rest_torch; authored_camps | `build` |
| verify-gate-evidence-shard | trainer_no_usable_ally; night_ecology; post_modal_control | `field` |
| verify-gate-evidence-finale | tournament_bracket | `bracket-to-semi` + `bracket-final` (section 2) |
| verify-gate-evidence-finale | gate_e_finale | `finale` |
| verify-regions-relay (meadows) | relay | `meadows` |
| verify-regions-relay (meadows) | stronghold; art | `meadows-stronghold` |
| verify-regions-relay (tidewake) | land loops reed root + brine terrace | `tidewake-loops-a` |
| verify-regions-relay (tidewake) | land loops salt shrine + sluice patrol | `tidewake-loops-b` |
| verify-regions-relay (tidewake) | return shortcuts (ramp, shellwatch, deep watch) | `tidewake-shortcuts` |
| verify-regions-shard (stormwood) | ordinary Stormwood to Water gate path; Nysa press | `stormwood-press` |
| verify-regions-shard (stormwood) | every other stormwood step | `stormwood` (unchanged) |
| verify-veridian-offer (space) | space-accept; space-refuse; rift gate opens once | `space-accept`; `space-refuse` (+ rift gate) |
| verify-veridian-offer (capacity) | capacity-refuse-at-prompt; capacity-accept-then-let-newcomer-go | one leg each |
| verify-veridian-offer (recovery) | capacity-accept-release-one; save-while-choice-open | one leg each |

Veridian: `TB_VERIDIAN_CASE_GROUP` now also accepts one case name. With no
value the smoke still runs all six cases in their old order. The "party never
held six" check is per process and runs in every leg. The gate-evidence
shard's first two steps used to run only if everything before them passed;
now they carry `!cancelled()` like the rest, so they run in more cases, never
fewer.

## 4. Not segmented (and why)

- **verify-gate-b-core** (`smoke_gate_b_continuous.gd` core): one attempt is
  226 s of smoke (a ~6 min job). That is already inside the 5–8 min target, so
  it was left whole. A second attempt only runs after a failure.
- **verify-gate-b-full-known-red** and **verify-continuous-core-known-red**:
  scheduled and dispatch tier only, `continue-on-error`. Segmenting them would
  need mid-opening save hooks they do not have, so they are left as they are.

## 5. Negative proofs (a stale checkpoint fails loudly)

`tests/test_ci_segment_handoffs.gd` (run per chain by `verify-segment-handoffs`,
and also by the unit shards). Every negative must report the failure and name
`re-generate checkpoint <boundary> with tools/ci/segments/regen.sh <boundary>`:

- `test_hand_edited_checkpoint_is_stale`: a creature level raised in a copy →
  digest mismatch;
- `test_old_version_checkpoint_is_stale`: world document set to version 27 →
  "world document is version 27" plus the production loader's refusal;
- `test_changed_producer_makes_checkpoint_stale`: producer fingerprint moved →
  "different producer";
- `test_contract_mismatch_is_reported`: a checkpoint checked against another
  boundary's contract → failures.

Observed live:

- editing the bracket smoke (its producer) made
  `--segment=final` refuse to start with `STALE checkpoint:
  bracket/after_semi:solo was produced by a different producer
  scenario/contract than the current one: re-generate checkpoint
  bracket/after_semi with tools/ci/segments/regen.sh bracket/after_semi`;
- a second, non-regen `--segment=to-semi` run reproduced the committed digest
  (`1a922c6d9097`);
- the midride setup producers reproduced theirs across two runs
  (`edaff325803b`, `1aeb8480f898`).

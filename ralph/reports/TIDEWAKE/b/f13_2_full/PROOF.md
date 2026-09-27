# F13#2 (full re-score): eight reward pockets reachable and paid (TIDEWAKE-B)

Criterion: ACCEPTANCE §6.1 F13#2, "Eight reward pockets reachable and paid". It is part of F13: "An earned route reaches ... eight pockets".
This pass answers the coordinator's four re-score items against the landed pocket proof (`../f13_2_pockets/PROOF.md`).
Branch `tb/scratch-tidewake-b-f13-2-full`, from origin/main `901e80f7`. Commit: see the branch head (the SHA is in the lane report).

**Scope change (00:08 UTC, lane lead):** the lane closes F13#3 first. From this pass it needs only the real Tidecoil helper and the proof that the gated candy unlocks from a real win (section 1). Items 2–4 stopped or were skipped. F13#2 is deferred.

**Verdict: NOT MET (partial).** The Deep Watch gate is now opened by a real Tidecoil win. The lure witness is incomplete.
Four gaps remain:
- two disclosed position writes;
- no chained inter-island travel inside the pocket smoke;
- an unpaid recipe half;
- the lure verdicts below.

## Clause table

| Clause / re-score item | Status | How |
|---|---|---|
| F13#2 "eight pockets reachable" (walk) | covered, with a fixture | `tests/smoke_water_pocket_walk_claim.gd` walks from each island's arrival landing to every pocket with real left-stick input. Fixture: one position write per island. |
| F13#2 "paid" (claim) | 7 of 8 roles fully paid | Six candies are paid by one Interact press each. Cradle pays 4 Reef Stone (pickaxe). Reedhaven pays 3 reed fiber (knife). The `recipe_and_reed_fiber` recipe half is **not paid** (item 4). |
| F13 "earned route reaches ... eight pockets" | not covered as one chain | See item 3. The composition argument is below. |
| Re-score 1: Deep Watch through the REAL gate | **covered, with two disclosed fixtures** | `--real-tidecoil` runs the fight through `tests/helpers/tidewake_b_tidecoil_fight.gd`, then walks to the candy and claims it. The gate flag is written only by the director's won terminal. Results below. |
| Re-score 2: long-range lure witness | **not covered (stopped)** | `tools/capture_tidewake_b_pocket_lures.gd` exists. 3 of 8 frames were captured. No judge was run. |
| Re-score 3: teleports replaced by travel | **not covered; disclosed (option b)** | See "Travel" below. |
| Re-score 4: reed_root_hollow recipe half | not implemented; **owner question** (investigation finished before the scope change) | See "Reed recipe half" below. |

## 1. Real Deep Watch gate

Command:
```
godot --headless --path . --fixed-fps 60 --script tests/smoke_water_pocket_walk_claim.gd -- --only=deep_watch_tidecoil_cache --real-tidecoil
```
Logs:
- `smoke_real_tidecoil_deep_watch.log` (Deep Watch only)
- `smoke_all_pockets_real_tidecoil.log` (all eight, with the real fight)

Sequence. Everything happens on production nodes, by input:
1. The trainer starts on Deep Watch's arrival landing (fixture A). It walks with the stick to the candy's pocket, and the cache is **proven absent** there (streamer `node_for` returns null).
2. The helper walks the baked-ground plan 134 m to the dry plateau, 20 m from Tidecoil's reef edge (the same stand `smoke_water_deep_watch_chart.gd` uses). Deep Watch has no low or gentle shore within 200 m of the reef edge. A probe found a gentle 12–15 m plateau, then a drop from 12 m to the sea in about 4 m.
3. The `creature_recall` action deploys the owned lead.
4. The stick drives toward the named body. The trainer walks off the cliff edge into the shallows, to 3.7–3.9 m from Tidecoil (wading, not swimming).
5. The production arbiter offers "Engage Tidecoil, the Abyss Serpent". One `interact` press starts the fight through the director's normal engage path, and the opponent is `water_deep_watch_tidecoil`.
6. The shared `CampaignPilot` (`tests/helpers/cloudreach_live_segment.gd` over `tools/combat_pilot.gd`) presses move, quick, charged and party_cycle through the production CombatManager until the manager ends the fight.
7. `water_named_deep_watch_tidecoil_resolved` is set by the director's own won terminal (`_mark_once_cleared`). No flag, HP or ledger entry is written by the test.
8. The trainer walks to the candy (after fixture B) and presses Interact on the production prompt. The host ledger accepts: Candy III goes into inventory, the personal receipt is recorded, and the pickup is retired.

Observed wins, one line per run. Every run below won; the earlier failed runs were all harness bugs, fixed before these.

| Run | Engaged by | Fight | Hits dealt/taken | Charged/quick/switch | Fainted | Flag by won terminal | Candy claim |
|---|---|---|---|---|---|---|---|
| dev run 5 | Interact on arbiter Engage offer | won, 66.8 s | 71/5 | 14/61/3 | 0/5 | yes | (walk-back harness bug) |
| dev run 6 | same | won, 67.3 s | 74/7 | 14/65/3 | 0/5 | yes | (walk-back attempt 1: wading plan, none) |
| dev run 8 | same | won, 61.3 s | 70/10 | 13/60/3 | 0/5 | yes | (walk-back attempt 2: open-water stick return, stalled at the cliff base) |
| dev run 9 | same | won, 63.2 s | 75/8 | 15/67/3 | 0/5 | yes | (same stall, repeated) |
| **committed** `smoke_real_tidecoil_deep_watch.log` | same | **won, 60.9 s** | 70/11 | 13/60/3 | 0/5 | **yes** | **ACCEPTED: 11 checks, 0 failures**. Walked 231 m, 31 legs, claimed at 1.24 m. |

Earlier runs 1–4 failed on harness bugs: a push loop with no frame await, a NaN shore probe, and no low shore. They were fixed before run 5.
The pilot won all five fights at L43 with no faint. This agrees with `../../f14_named_c2c3`, where the masher never loses to Tidecoil. So the fight is not hard at L43; that is a COMBAT/C2 finding owned elsewhere.

The all-eight run with `--real-tidecoil` was stopped at 00:08 UTC on the lane lead's instruction, to free CPU. There is no log for it.

Disclosed fixtures, all that remain in this mode:
- **Party.** Before the world loads, the Game party is cleared and the retained five are placed in it: terrapup, bramblebun, mudsnout, pipwing, trailpup. All are level 43, the Tidewake region-entry level (PROGRESSION §3 "L43 overlap → L55"). This is the same fixture `smoke_water_named_c2c3.gd` uses. It is not an earned party.
- **Fixture A: position write to the Deep Watch arrival landing.** No owned swimmer or swim saddle is granted. The trainer is placed on the landing instead of riding there on the mounted route.
- **Fixture B: second position write, after the win.** The trainer goes back to the same arrival landing. Tidecoil is fought in the shallows under a ~12 m cliff, and I found no way back up:
  - The baked-ground planner found no route out at wading depth (`dry_m=-1.0`).
  - Two open-water stick returns stalled against the cliff base at (1483.9, 3404.4), while swimming.
  - Human swim stamina lasts about 136 m (100 stamina, 2.8/s drain, 3.8 m/s). The arrival landing is 224 m away in a straight line.

  In play, the intended way to reach this fight is the owned-swimmer mounted route, and that is not exercised here.
- **Carried pickaxe and knife.** These are the existing Cradle and Reed fixtures, unrelated to the gate.
- **Solo only.** Co-op resolution (each participant, host-confirmed once) is not exercised by this smoke.

Pilot note: `tests/helpers/combat_depth_pilot.gd` builds its own CombatManager on a flat fixture, so it cannot drive a fight in the production scene. The helper instead uses the production-scene pilot, the Meadows and Cloudreach earned segments' `CampaignPilot`. That pilot drives the scene's own `CombatManager` and `EncounterDirector` by input actions. Nothing calls `_on_combat_exited`.

Reusable helper: `tests/helpers/tidewake_b_tidecoil_fight.gd` (`await Helper.new().run(tree, world)`). It returns `{won, resolved, outcome, engaged_by, fight_seconds, hits_dealt, hits_taken, fainted, ...}`.

## 2. Long-range lure witness

Command:
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/capture_tidewake_b_pocket_lures.gd -- --out=ralph/reports/TIDEWAKE/b/f13_2_full/lures
```

Method:
- For each of the 8 `water_world.json` reward pockets, the stand is the first point on the pocket walk's planned route (from the arrival landing) that lies within 40 m of the pocket centre.
- The production CameraRig yaw and pitch are steered until the pocket centre sits in the left third of the frame, at mid height. That keeps it clear of the trainer at frame centre and of the hotbar.
- The capture runs in daytime with the clock frozen, and the finds are streamed normally.
- Deep Watch is shown pre-gate, as a player sees it before Tidecoil.
- Only the trainer's pose and the camera's yaw/pitch are written.
- Per-frame geometry is in `lures/capture.log`.

**Stopped at 00:08 UTC on the lane lead's instruction.** F13#2 is deferred, and the lane is closing F13#3 first.
- Three of the eight frames were captured: `lures/01_lantern_hidden_cache.jpg`, `lures/02_reed_root_hollow.jpg` and `lures/03_brine_upper_shelf.jpg`.
- No code-blind judge was run, so no Codex row was added.
- My own look, which is not a judge verdict: in all three frames nothing at the pocket position draws the eye. Lantern and Reed show open grass there. At Brine, the grass hill crest hides the shelf.
- Re-run the tool for all eight frames, then judge them.

## 3. Travel (disclosure, option b)

I did not chain the pocket walks with swims in this pass.

What exists:
- Every pocket walk starts at its island's authored arrival landing. That is one position write per island.
- `tests/smoke_water_hop_walked.gd` (on main; `../f12_0_walked_hops/PROOF.md`, PASS) separately proves the swims. It covers every mandatory sheltered hop (7 routes, 24 hops) and the 4 direct alternatives. Each is swum with real `move_forward` input to those same arrival landings. There is one position write per run, and island walks between routes use the same `plan_route` planner.

Does the composition satisfy F13's "an earned route reaches ... eight pockets"? **No, not fully.**
- It covers the pockets on mandatory-chain islands: Reedhaven, Brine Steps, Tidal Cradle and Salt Crown. For those, the hop proof reaches the exact landing the pocket walk starts from.
- It does not cover Lantern Cove, Gull Rest, Drowned Garden or Deep Watch. These are off the mandatory chain (optional swim or mount routes), and no walked witness reaches their landings.
- "Earned" also implies an earned party and earned flags. Both proofs use fixture parties and set flags.

I read the criterion as needing one earned chain. The composition is evidence toward it, not a pass.

## 4. Reed recipe half (investigation only)

- `water_world.json` pocket `reed_root_hollow` has `reward_role: "recipe_and_reed_fiber"` and the purpose "Side branch off root walk, supporting pier repair".
- WORLD.md names the Reedhaven pier repair (line 220; Broken Channels, line 264). Its dock action `reedhaven_repair` costs 6 reed fiber and 4 driftwood (`water_dock_actions.json`).
- **No design document names the recipe.** I searched WORLD, SYSTEMS and PROGRESSION for `reed_root_hollow`, pier repair and recipe.
- In `water_crafting.json`, every recipe unlocks at `water_chapter_started`, except `swim_saddle` (`water_swim_saddle_recipe_learned`). No recipe is left for a pickup to teach.
- SYSTEMS §40 says "Water's separate recipe metadata must have a runtime consumer; metadata alone is not enforcement". So a pickup-taught recipe would need a new unlock consumer, and that is not authorized.

**Owner question:** Which recipe should `reed_root_hollow` teach? Or does the reed fiber alone (which feeds the pier repair) satisfy the `recipe_and_reed_fiber` role?

If a recipe is named, the smallest change would be:
- a `learn_recipe_flag` field on the pickup row;
- that recipe's `unlocked_by` set to the flag;
- the existing personal pickup claim writing the flag.

That is a SHARED-FILE change to `data/config/water_pickups.json`, `data/config/water_crafting.json` and `scripts/world/water_personal_pickup.gd`. It is not done here.

## Changes on this branch

- `tests/helpers/tidewake_b_tidecoil_fight.gd`: new. The real Tidecoil fight helper.
- `tests/smoke_water_pocket_walk_claim.gd`: new `--real-tidecoil` and `--party-level=` flags. `_walk_from(Vector3.INF, ...)` continues from the trainer's current position with no write. Without the flags, behaviour is unchanged.
- `tools/capture_tidewake_b_pocket_lures.gd`: new. The lure capture.
- Evidence: this directory.


## Round 4: Option A fix and game-time caps (coordinator-approved)
- **Game fix (option A):** `stormwood_harvest_runtime.site_gathered(id)` counts a site when it has the exact legacy `harvest_node:order:<id>` flag, OR its world stock revision is ≥ 1. It is used by `first_stormglass_gathered` and `claimed_crown_glass`. The coordinator's merge adds a missing-Game guard.
- **Approved test changes (same predicate, still exact):**
  - the Crown build helper's receipt checks;
  - the prefix helper's `_harvest_site` and `_harvest_charged_node` receipt checks.
- **Game-time caps:** road/Crown fights (180 s), trainer sequences (300 s) and the Marrow attempt (900 s) now count physics steps instead of wall time. One step is 1/60 s of game time at both the 8x/480 Hz and 1x/60 Hz clocks. Assertions are unchanged.
- **Runner:** the scratch Load copy moved to `user://` (the game rewrote `world.json` after cleanup).
- **Survey of objectives keyed on `harvest_node` flags for renewable sites:**
  - Stormwood: two sites, both fixed.
  - Water: the `tidal_cradle:harvest:007` chain seam is `existing_world_pickup_policy`, so it is not renewable.
  - Meadows/Cloudreach: none.
  - `tests/helpers/water_reedhaven_segment.gd:202` checks Water receipts (Tidewake lane).

Piece 01 progress (`01i`): first Stormglass, pair A gathered/relit/travelled, route pickup, Maren won, Verge rod disabled.

## Finding: frame cost after Maren's fight (not a leak)
The coordinator's suspects were teardown leaks, a re-spawn loop, or a per-frame signal. The monitor (`perf_monitor_01k.log`) samples every 15 s and rules out a leak:
- node count stays at ~73.9–74.0k, objects ~117.4–117.8k, orphans 0;
- the only churn is the combat set (`combat_arena.gd`, `throw_aim.gd`, `tether_command_input.gd`, `move_effect.gd`, wild bodies), which is created and freed with each fight.

`rod_perf_probe.gd` (diagnostic, flag writes allowed because it is not evidence) holds about 9 fps at the Verge road before and after `trainer:officer_maren_verge_rod:defeated` and `rod_verge_disabled`, with an identical set of processing nodes. So the state change is not the cause.

The sim/wall drop comes from back-to-back road-wild combat on the Ash road. Combat frames run at 1–2 fps on this host (process 150–600 ms, physics 20–300 ms), against 6–9 fps out of combat. The earlier "fast" run had not yet met those fights.

No smallest-cause fix exists. Combat frame cost on headless llvm/dummy rendering is a performance question for on-device measurement (RD-25 ROG Ally test), not an evidence-phase change.

## Round 5 (12 Oct, routes-east): Stormheart ceremony, homecoming, crown_build perf
Pieces run with `tools/earned_saves/stormwood_chain_runner.gd` from the Cloudreach-07 lineage saves `r2/dynamo` (marrow_aftermath) and `r2/arrival_prefix` (crown_build). Logs and receipts are in the lane scratchpad; the numbers below are copied from each RESULT line.

**Keep-at-five ceremony: PASS on the real path.**
- Game fix `a5b310736f`: `StormwoodEnding._owner_passive()` creates the session's owner-passive service lazily. Before it, a solo/host owner freeze was refused and the five-holder release was disabled ("Release is unavailable").
- marrow_aftermath r10 (`a5b310736f`) and r14 (`f4829ae75f`) both logged: "ACCEPTED the Stormheart at five: kept <uid>, released belt row 4; world offer fact and personal receipt saved".

**Capacity smoke: fixture-only, fixed `8224ca61ea`.**
- `smoke_f19_stormheart_capacity` now passes 95/0.
- Cause: the inherited `_mount()` swaps `Game.world`. The ledger stayed bound to the old world, so the host settle was refused and the roster tab stayed "waiting".
- Production never replaces `Game.world`, so players can't hit this. No assertion changed.

**Homecoming never opened: PRODUCT DEFECT, fixed `7015c47042` and `88ebb19711`.**
- `regional_homecoming.WORLD_FLAG` was `stormwood:stormheart_freed`. Nothing produces that flag; the ending writes `stormwood:legendary_freed` (`StormwoodEnding.FREED_FLAG`).
- So `Game.regional_ending_context()` was always empty, and the homecoming, the Home Key finale and the credits were unreachable in earned play.
- r14 showed it: after the keep, no `stormwood_homecoming_aftermath` opened (open=none).
- WORLD_FLAG now references `FREED_FLAG`.
- New `tests/test_regional_homecoming_freed_flag.gd` drives the authored `dynamo:release` dispatch and checks the live context. It FAILS on `478f61de14` and passes on `88ebb19711`.
- No migration: nothing ever wrote the old id.

**Waterward helper expectation: `f4829ae75f`.**
- With the shipping `redesign_ending_runtime_enabled`, the aftermath is `stormwood_homecoming_aftermath`, presented once by `_queue_homecoming_handoff`.
- `stormwood_waterward_aftermath` plays only with that runtime off.
- Both helpers share `_view_waterward`, which still activates the view and still requires all four Waterward receipts.

**crown_build perf: systems fixes; this lane measured.**
- Before: the arrival_prefix save carries 668 combat_mastery + 506 research retained duties. Each mastery hit cost ~2 s (commit 0.25–0.4 s, owner apply 0.56–0.77 s, flush ~1 s).
- So the 500 ms batch budget stopped every batch at one hit: `composition.retry_events` took 2.0–3.3 s per frame, and process_ms climbed from 3.7 to 9.2 s (r11, watchdog abort).
- After systems' multi-frame job (`7910ca114e`, `0bda3688c4`, `dae44cc1d7`, `4d2f1ab0f`), r19 `frame_wall` over 5716 frames: median 13.4 ms, p95 207 ms, p99 906 ms, max 5609 ms. sim/wall went from 0.02 to 0.26.

**Open items:**
- **crown_build soft-lock at still_grove_shelter (r19, `02930cf113`; systems owns the fix).** Bedding row 0 sets `/party/0/resting` and `rest_bed_index`. An in-flight training owner apply then fails with `owner_action_baseline_conflict`, and the row stays "training awaiting owner ack" with no mastery job running. `Session.owns_input()` stays true, every world press is dropped, and the camp "Rest" prompt never activates.
  - Systems reports the fix at `baedacc50` (tb/ev-systems-b, 16:47 CT): owner-local care fields merge, a lasting conflict installs the decided record, and an input-fence watchdog forces the row through after 600 frames. Not retested here: the owner wind-down (16:35 CT) said to start nothing new. First run after the pause: crown_build → rootgate from `r2/arrival_prefix` on this branch merged with `baedacc50`.
- **r16 earlier at this bed:** input_owner was `/root/Game/Session`, held by the multi-frame job's owner fence. Fixed by `4d2f1ab0f`.
- **Homecoming real-path proof:** marrow_aftermath r17 on `7015c47042`. NOT REACHED. r17 hit a WATCHDOG abort at 16:48 CT: no new receipt for 45 min, inside Marrow round 1 (Tanglevolt L54).
  - frame_wall over 3364 frames: median 627 ms, p95 1960 ms, p99 2292 ms, max 6101 ms.
  - `7015c47042` has systems' multi-frame mastery job but not the fence fixes `4d2f1ab0f`/`baedacc50`. The same Session input-fence hold may have frozen the fight; this is unverified.
  - The homecoming fix is proven by `test_regional_homecoming_freed_flag` (with its negative control), not yet on the earned path.
  - No rerun because of the wind-down. First run after the pause: marrow_aftermath from `r2/dynamo` on this branch merged with `baedacc50`.

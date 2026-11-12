# LANE-PLACES NOTE (branch `tb/places`)

## RESTARTED (owner direction via coordinator, 12 Nov 2026)
- **Swing 2 was judged: DO NOT SHIP** (`G-places-swing2`, 7e327f36). F41#12 −0.71 ("thick, bright, saturated gold stripes"), F41#4 −0.17, F41#5 −0.16; F41#8 +0.38. The umber road has now won twice against the black slab; the gold line is the problem at both strengths. Gold brightness alone is parked; `contrast_1112` is removed.
- **OWNER QUESTION (please relay): the judges ask for the road charge in white-violet.** The road current is yellow-gold by owner direction (WO-F09-04: "yellow electricity flowing through them"; the config says yellow/gold only). I have not changed the colour. `thin_1112` keeps it gold and makes it one thin sparse line with no web and almost no halo. If the owner wants white-violet, it is a two-colour config change on top.
- **Fading bolt: settled as capture timing** (GPU motion probe 93b455abe), and fixed in the game so it cannot recur: live lightning goes out the moment Break ends. **Landing branch `tb/places-breakonly-land` (a2ce48f7), `PLACES-BREAKONLY/READY.md`, STATUS: land.** F41#2 needs a fresh base after it lands. `fading_clear_1112` is not needed (GPU Fading on main is already brighter than Building, L 139 vs 107); it stays flag-off and unused.
- **In progress: swing 3** = umber road + `thin_1112` (`PLACES-STORMWOOD3/overlay.json`); CPU yellow-share check on F41#12 running. Still to add before sending: recolour the salmon bears and the pink or copper distant tree cards.
- `tb/places` was deleted on the remote; recovered from the lane container and re-cut from main d777b905 with `road_value_1112` (flag-off, puddles parked) and this NOTE.
- **Working on:** Stormwood swing 2 = road value done right (gold path line contrast restored on the umber road) riding inside a bigger pass: a Fading phase that differs from Building, layered treeline and depth steps. Then Cloudreach F40#0 gate cobbles, ground and fog. Then near-bar close-outs (F41#17, #24, #21, F40#18, F39#24, #25, #4).
- **Sent to GPU (arm 1 of 2):** `PLACES-STORMWOOD2/` (two overlays): judged no-puddles road + gold line contrast + a clearer Fading. Rows F41#2, #4, #5, #12, #8. CPU: the gold line reads clearly on the umber road.
- **Finding:** the CPU phase tool's Fading still repeats a Break frame (bolts, dark deck) on main and on every arm, so Fading cannot be checked on CPU. On GPU the judges did see Fading (steam), so this looks CPU-only; not chased further.
- **Next:** Cloudreach F40#0 gate cobbles, ground and fog; then near-bar close-outs.
- **Built, held (not sent): `paving_scale_1112`** (`cloudreach_f40_items.json`, `cloudreach_settlement_life.gd`; overlay and CPU sheet in `PLACES-GATEPAVING/`). Cause found: the gate's stone-trail pieces are sized by a 0.28 m height, which scales the model about 2.5x and stands its top a shin's height proud. On: 0.12 m pieces sunk 55%. CPU (gate approach, day clear): the torso-sized pad becomes a line of boot-sized stepping stones flush with the path. It touches the gate, gate-road and shrine stands only, so it is under 0.5 alone; it waits to ride with Cloudreach ground colour variation and layered fog (not built yet).
- Main 2ac7ab84 (#917) is merged into `tb/places`.
- Standing rules for this lane: lightning is Break-only (owner); puddles parked; check older test pins and `texture_import_policy.py` before a landing; no unrelated `.uid` files.

## WRAPPED (owner direction via coordinator, 12 Nov 2026). Handoff.
No new arms are started. Everything is pushed. The lane stops here except for one conditional step: **if the road-value arm ships, cut its landing from current main** (flip `road_value_1112` ON with `_why_on`, with the judged overlay's puddle setting, add a pin, READY.md).

### State
| Item | Where | Status |
|---|---|---|
| P1 storm light (`storm_phase_1111`) + `distinct_bodies_1111` | main, PR #914 | **Landed.** GPU F41#2 +0.80, F41#8 +0.58, F41#13 +0.23. Building far bolts removed by owner decision. |
| P2 Cloudreach rain (`rain_time_grade`) | `tb/places-raintime-land` d0e0b9c0, PR #915 | **Judged win, landing in PR.** All 12 rain sets 3/3, mean +0.70. |
| Stormwood road value (`road_value_1112`) | `tb/places`, flag-off; `PLACES-ROADVALUE/` | **On the GPU queue**, two overlays (with and without puddles). Not judged. |

### LANE IS WRAPPED. Final state (12 Nov 2026)
- **Road value (no puddles) was judged: do not land alone** (`G-places-roadvalue.md`, tb/item-scout-1108 4061fd99). F41#12 6.01 → 6.44, F41#5 5.78 → 6.17, F41#2 6.09 → 6.40, F41#8 6.01 → 6.25, each 3/3. F41#4 loses twice (−0.23 at 0/3, then −0.09 at 0/3 with one tie): the gold path line loses contrast on the lighter road; judges praise the road itself. Every gain is under 0.5, so it does not stand alone (owner, 25 Oct).
- **No landing is cut, and under the wrap-up no new arm is started.** `road_value_1112` stays flag-off on `tb/places` (two files: `scripts/world/stormwood_ground_zones.gd`, `data/config/stormwood_ground_finish.json`). Coordinator's call: carry it flag-off to main for the next Stormwood swing, or drop it so the branch has nothing ahead but reports.
- **To finish it later (LANE-SCOUT's list):** restore the gold line's contrast on the umber road (more emission or a dark edge), then ride the road inside a bigger Stormwood swing: layered treeline and depth steps, groves in place of even turf, recolour the salmon stumps and peach bears, glow and branching on the road charge, separate Calm from Building. Puddles stay parked.

### Road value update (12 Nov, from the GPU lane via the coordinator)
- **Puddles are parked.** The puddle overlay failed the GPU pre-check (lilac and white slabs on the road at 5 stands) and was not judged; CPU round 1 showed the same. Two failures on one approach, so `road_value_1112` now carries puddles off by default (`puddle` [0, 0]), the same values as `overlay_no_puddles.json`.
- **The no-puddles arm passed the pre-check** (umber wet road, no slabs) and is with LANE-SCOUT. If it ships: cut the landing from current main with `road_value_1112` ON and puddles off. If it does not ship, the lane is done.

### Not on main that should be
- `tb/places-raintime-land` (PR #915): the rain flag ON, its pin and READY.md. Judged win.
- Nothing else is a judged win. The lane NOTE and the arm folders (`PLACES/`, `PLACES-ROADVALUE/`, `PLACES-RAINTIME/READY.md`) are records only.

### On `tb/places` only, flag-off and unjudged (listed, not for main unless judged)
- `road_value_1112`: `scripts/world/stormwood_ground_zones.gd` (puddle uniforms, `blend_sharpness`, candidate list) and `data/config/stormwood_ground_finish.json`. Inert while OFF. If it loses, drop both files' changes; `tb/places` then has nothing ahead of main but reports.

### Open candidates (not started)
- Stormwood: brighten and clear Fading (judges: too close to Building); fix the F41#19 stand (a trunk fills half the frame, the trainer clips into the cluster).
- Cloudreach F40#0: gate cobbles as large as the trainer's torso, burying the trainer to the shins; flat single-green ground and flat grey fog. New art for BELOW6: overlook slab walls, black sky islands, billboard cloud slab.
- P4 dark dawn and night foregrounds, P5 Tidewake dunes, P3, P6, P7 grass-clear radius.

### What worked
- Finding the cause before tuning: shafts culled away from the origin; weather presets being absolute colours.
- Sending to the GPU early with a variant overlay instead of more CPU rounds. CPU Low cannot rank glow, fog or puddles.
- Checking older tests with the flag ON before landing (the F10#3 lightning rule surfaced that way).

### What did not
- Mirror puddles on the road read as lilac slabs on CPU (round 1). Cut to small satin patches, unverified.
- Mist banks and sky layering alone were level on F41#4, #5, #12, #19: the ground holds those rows.

## Status, 12 Nov 2026
- **JUDGED, landing cut:** P2 Cloudreach rain SHIPS (`G-places-raintime`: all 12 rain sets 3/3, mean +0.70; night up to +1.50). Landing branch `tb/places-raintime-land` (d0e0b9c0, from main 328c598a): flag ON with `_why_on`, pin updated, `PLACES-RAINTIME/READY.md` (STATUS: land). 413 tests pass.
- **Storm light landed** in #914. `tb/places` now carries main 328c598a's tree (taken in as one ordinary commit, because the shallow clone cannot merge) with the unlanded road-value work on top.
- **One arm on the GPU now:** `PLACES-ROADVALUE` (two overlays).
- **F40#0 next (judges):** gate cobbles as large as the trainer's torso that bury the trainer to the shins (scene, mine); flat single-green ground and flat grey fog. Overlook slab walls, black sky islands and the billboard cloud slab are new art (BELOW6/MESHY).
- **JUDGED, landing cut:** P1 storm light SHIPS (`G-places-stormlight`, F41#2 +0.80, F41#8 +0.58, F41#13 +0.23; others level). Landing branch `tb/places-stormlight-land` (41a70edb, from main 4e35bfbd): both flags ON with `_why_on`, pinning tests, `PLACES-STORMLIGHT/READY.md` (STATUS: land). 628 Stormwood, surge and villager tests pass with the flags ON.
- **For the coordinator to accept or strip:** the older F10#3 test "only Break shows sky lightning" now allows Building's faint far-horizon bolts (part of the judged frames). Details in READY.md.
- **Owner decision (via coordinator, 12 Nov): no far bolts in Building.** Lightning stays the Break-only danger cue. The coordinator set `far_bolts` 0 and restored the F10#3 test on the landing (PR #914). Do not re-add.
- **Sent to GPU (arm 2 of 2):** `PLACES-ROADVALUE/` (road_value_1112: lifted wet road, softer blend, lifted pools; two overlays, with and without puddles). Rows F41#12, #4, #5, #8, #2. CPU round 1 showed mirror puddles as lilac slabs; they are cut to small satin patches, unverified in frames.
- **One arm on the GPU:** P2 `PLACES-RAINTIME` (Cloudreach rain time grade, F40#0 and F40#19).
- **Next swing (judges' shared ceiling):** Stormwood ground and road value: wet dark-umber road with puddle highlights and blended edges instead of near-black mud with cut-out edges; brighten and clear Fading; fix the F41#19 stand. Then P4, P5.
- **Housekeeping:** an early commit on this branch swept in unrelated generated `.uid` files; they are left out of the landing branch.

## Status, 11 Nov 2026 (superseded above)
- **Sent to GPU (arm 1 of 2):** `PLACES-STORMLIGHT/ARM.md` + `CAPTURE.json` + `overlay.json`. P1 Stormwood storm light: `storm_phase_1111` (layered storm sky, held white-violet bolts with a bolt key light, far bolts in Building, mist banks, shafts un-culled) with `distinct_bodies_1111` riding for F41#8. Rows F41#2, #4, #5, #12, #19, #8; riders #6, #13. All code is flag-off on the branch.
- **Sent to GPU (arm 2 of 2):** `PLACES-RAINTIME/ARM.md` + `CAPTURE.json` + `overlay.json`. P2 Cloudreach `rain_time_grade`: rain sky, cloud and fog follow the clock (night rain is night), golden hour keeps warm light, streaks fine and translucent. Rows F40#0, F40#19. CPU: 23:00 and 18:00 rain at the Realm Gate, clear change on both.
- **Two arms are waiting on the GPU, so no third is sent until one is judged.** Building next arms flag-off meanwhile.
- **Next:** P4 dark dawn and night foregrounds, P5 Tidewake dunes, P3, P6, P7 (grass-clear radius).

## Findings worth keeping
- **Stormwood light shafts never drew away from the world origin.** `stormwood_storm_shafts.gd` sets a custom AABB centred on a node that stays at the origin, so the MultiMesh is culled along most of the route (it draws round Cinder Verge only). Judges kept saying "no shafts" after `storm_sky_1101` shipped them. The fix (`shafts.follow_camera`) is inside `storm_phase_1111`.
- **Stormwood Break already shows crawler veins and bolts on main at Cinder Verge** (CPU). The phases differ in the sky but not on the ground, which is what the bolt key light addresses.
- **The "black pools" in F41#8 frames are the dark wet path** filling the lower half of the settlement stands, not the zone pools. Lighter wet earth lost on GPU (swing-1), so this arm leaves it.
- **Cloudreach weather presets are absolute colours** (`world_look.gd _layer_weather`): any weather sky replaces the night or golden sky outright. That is the cause of "night rain reads as day".

## Runbook additions
- Stormwood matrix screening: `.artifacts/places/cap_matrix.sh` pattern (flip the flag, run `capture_stormwood_f10_matrix.gd --stands=… --phases=calm,building,break --no-aftermath`, restore the config). Break frames wait up to 150 fine frames for a bolt; under giant trees on CPU that is about 10 minutes a frame, so screen Break at the open stands.
- `quick_judge.py capture <row> --overlay <file>` gives base and arm frames for a row under `.artifacts/qj/cache/<tree>/{base,<overlay>}/`; untracked new files do not change the cache key, tracked edits do.
- Write scratch frames under `.artifacts/`, not `ralph/reports/VISUAL/` (that path is not ignored).
- **New runtime 3D texture sidecars (from the coordinator, 12 Nov):** PR #914 failed `test_texture_import_policy` because `meshy_f41_8_bryn_albedo.png.import` was `compress/mode=0` (the coordinator fixed it on the PR). Before a landing, run `tools/art_pipeline/texture_import_policy.py --check` on every new texture sidecar; `--apply` skips untracked files, so set the sidecar by hand (mode 2 plus the s3tc path and metadata) and re-check.

# MEADOWS close-1024 (tb/meadows)

Rows: F17#6, F04#6, F38#0/#1/#2/#3/#5. Renderer: CPU Mesa llvmpipe, Low/Compatibility, 1920x1080. A mapped Bar A of 6.7 counts as CPU-provisional; no GPU pass is running.

## TO COORDINATOR

(send_message to the coordinator was refused with elevated_session_untrusted_device, so lines go here.)

- 2026-10-24 MESHY (F04#6 aftermath heroes, day-1 list). The judges' standing ask is that Riverwatch and Ridge share one fallen-banner/glowing-stone template and that Field's camp is "wiped rather than collapsed". The 22 Oct toll boom and brazier read worse ("a log on a post", "muddier silhouette"), so these use bigger, clearer silhouettes. Scale is against the 1.80 m trainer. Oxblood only on small Team Tether plates. Style: chunky, readable stylised realism. All stay flag-OFF until judged.
  1. MESHY: docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-02-open-field-path.jpg | 3.6 m wide x 3.2 m deep x 3.4 m tall (1.9 trainers) | Riverwatch: a wrecked Team Tether river checkpoint hut. A timber guard shack with a collapsed half-roof sliding off one side, a split door hanging from one hinge, dark iron Tether plates and a bent cyan-lensed lamp bracket. Crates are spilled at its foot, and a snapped barrier rail sits on a stone footing.
  2. MESHY: docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-03-field-boss-meadow.jpg | lying 6.5 m long x 1.8 m wide x 1.6 m tall; the standing stump is 2.2 m | Ridge: a felled Team Tether signal pylon. An iron lattice mast snapped at the base and lying across the turf, with its cracked cyan crystal head dark, torn cable coils, and the sheared stump bolted to a fieldstone plinth.
  3. MESHY: docs/reference/owner-board-2026-08-23-camp-set.png + docs/reference/palworld-05-base-building.jpg | 4.2 m long x 3.0 m wide x 1.6 m tall (collapsed; 2.6 m standing) | Field: a collapsed Team Tether field tent. A grey-teal canvas A-frame caved in on one broken ridge pole, with slack guy ropes, a scorched corner, an overturned supply chest and a toppled cookpot tripod.
  - Other Meadows rows reuse existing OFF Meshy assets first: the burrow shell, the horizon hero_model, the stronghold gate, the Hall great-hall set and the catch-kit orb. More requests follow only after a judged round names new_art. A GLB on any branch path is fine.

- 2026-10-24 01:15 CT READY tb/meadows-land 6cb3e6c0b (from origin/main 5f1f388cc): **F17#6 r9, CPU-provisional met.** Mapped Bar A is 6.84 against shipping 5.82, from three fresh code-blind judges with the standard prompt and three anchor pairs. The batch is confirming (f36_0_npc:C1); calibration is linear, r 0.89, RMSE 0.55, with no warnings. Evidence: `F17-6.md`.
  - Change (config only, `crossing_hall.json`): the nave posts move to x=±5.0 and the ties stretch to span 10 m; `hall_great_hall` and `hall_dressing` turn ON (its two plaster runners are dropped); the floor becomes a warm #c8b89c; four warm window shafts.
  - Checks on the candidate tree:
    - 8 focused unit files (crossing_hall, f17_companion_interior, village_*, inn_interior, f19_order_consumers): 52 tests, 0 failed.
    - `smoke_crossing_hall_circuit`: PASS (all 8 arches and 8 pedestals reached on collision).
    - net `homestead_station_craft`: ALL CHECKS PASSED (47).
    - net `f48_coop_loop`: ALL CHECKS PASSED (507).
  - A GPU pass must confirm 7.5.

- 2026-10-24 06:30 CT STATUS (replies to your 00:54 and 01:41 messages; send_message from this lane is still refused):
  - Review nits are done on tb/meadows (03a27a528).
    - The `daylight_windows._scope` now names all four sources. The east sources sit at x=+6.75 in the wall bays between the east arches, below the upper window row visible in the r9 nave-arches-right frame. Aperture alignment is not measured.
    - The `crossing_hall_great_hall.gd` header now says ON and that only `collider_radius_m` pieces (the shrine altar, r 1.3 at (12, 0.37, 5.6)) collide.
    - `smoke_crossing_hall_circuit` covers the shrine: it reached the shrine doorway and all 8 pedestals with the altar collider live (PASS).
  - Texture policy was applied to the three meadows Meshy heroes: PASS (837).
  - F04#6 r30 (the three Meshy heroes, OFF) maps 6.20 against 5.99. Field +0.93 and Ridge +0.34; Riverwatch −0.26 ("a hut appears after the win"). r31 (hut in both states, banner down; Dell spilled crates and banner) is with the judges now.
  - F38#1 P2-059/060 catch: r1 6.42 vs 6.08, r2 5.28 vs 5.39. Parked at r1, OFF.
  - F38#1 P2-087: the speaker-frame candidate is a no-op on the real path (5.57 vs 5.41), OFF. Gauntlet `*_defeated` lines are talk-to lines, not auto-played.

- 2026-10-24 07:05 CT STATUS F04#6 PARKED at r31: 6.23 mapped against shipping 5.86 (r30 +0.21, r31 +0.37; two rounds under +0.5 after the Meshy approach), below 6.7. All OFF. See `F04-6.md`.
- 2026-10-24 07:05 CT QUESTION F04#6: r31 beats shipping by +0.37 but isn't passing. Lane rule: OFF. `visual_candidate_sites` has no per-piece flag, so landing it means turning it on. Do you want an ON land branch (as with r29 at wind-down) so the GPU pass judges it, or should it stay on tb/meadows only? I'll build whichever you say.

- 2026-10-24 08:50 CT MESHY: assets/props/meshy-1020/burrow_hill_mound (its current model and concept, for identity) + docs/reference/tetherbound-meadows-keyart.png (rolling hills) | the same envelope; the code fits it to about 20 m wide x 9 m tall x 16 m deep over the burrow dungeon | F38 P2-012 r3: the same rounded, grass-capped burrow mound with the root-arched door opening. Continuous grass cover, with earth showing only as soft, broken, irregular patches near the base and the door. No straight-edged brown bands across the slopes. A few embedded fieldstones and root knuckles; small bushes clustered, not spaced like spheres. Judges: r2 maps to 6.10 (shipping 4.94); the remaining named defect is the mound's own hard-edged dirt bands. Also size the door opening to the real burrow mouth (about 4 m wide x 4 m tall, tunnel depth under 2 m), so no clip box is needed: r2's smaller clip lets the shell tunnel show inside the threshold.

- 2026-10-24 03:40 UTC STATUS (reply to your 03:30 message): F38#0 is underway, following the F39#0 precedent.
  - Matrix: `capture_f38_matrix.gd --seed=2042 --f38-preset=Low --f38-baseline --times=day,night` at SHA 592a6dea6 (tb/meadows, merged with main after #716), started 03:33 UTC, CPU llvmpipe. The earlier run gave 236 of 352 frames, so this takes hours.
  - Supplementals queue straight after it, built from the catalog sightings' own repro commands in `phase2/meadows/manifest.csv` (153 sightings, 9 runs): creatures, catch, UI, fights, realm flight, dialogue, world inventory, defeated dialogue, build systems.
  - Then three blind passes over all 46 Meadows rows, `row-scores.json`, and a blind completeness check.
  - F38#5's defect pass uses the same matrix; F38#3 follows. F04#6 is parked at r31 6.23 (two rounds under +0.5 with the delivered heroes). The question on landing r31 ON for the GPU pass still stands.

- 2026-10-24 13:40 UTC STATUS (reply to 13:06): F38 matrix done: 236 of 352 frames (≥200; the same 116 stands rejected as on 20 Oct). See `f38-0/README.md` and `f38-0/matrix.md`.
  - F38#0: landscape rows rescored on the yardstick (6 rows, 5.34-5.81 mapped). The supplementals for the other 40 rows are capturing now (9 runs, from the catalog's own repro commands). READY follows when every row is scored or honestly marked no-evidence, as F39#0 did.
  - F38#3 matrix Bar A by area: 2.09-6.33 mapped. Not met.
  - F38#5: not clean.
    - Most of the Hall and arch failures were a fixture fault, now fixed on tb/meadows (wall-arch stands faced out of the room, and the nave stand resolved onto the ceiling panels). The Hall sites are queued for recapture.
    - Relay yard hex patches: a game fix (pad cells and lift), queued for recapture.
    - Still open: the production camera against the relay gate walls and in village interiors, the waterfall column, and the washed-out cyan Hall views.

- 2026-10-24 17:10 UTC FOR THE GPU MATRIX: `ralph/reports/R2-F38/capture-definition.json` and `tools/capture_f38_matrix.gd` on tb/meadows (head of this push) fix the matrix fixture.
  - The old definition placed every Hall wall-arch stand outside the Hall (blue void, black frames). It also stood the trainer on the nave's ceiling panels.
  - The fixed definition faces the arches into the room, keeps only their 3 m detail view (the 8 m stand's camera lands inside the opposite wall), and stands the nave and shrine on the floor.
  - Please capture the High/Medium matrix from this definition, or the Hall rows will be void again. CPU recapture with it: 48 of the Hall frames are valid, with 0 void and 0 black.
- 2026-10-24 17:10 UTC F17#6: the renderer-aware shafts and rims are in 4ad2d6d24 (test `test_crossing_hall_great_hall_renderer.gd`). READY follows once the test has run in the next capture gap.

- 2026-10-24 17:35 UTC READY tb/meadows-land2 0a88dd931 (from origin/main): F17#6 GPU fix.
  - Change: `crossing_hall_great_hall.gd renderer_scale()`, the F22#4 aura pattern. On Forward+/Mobile no daylight shafts are built (`forward_plus_shaft_scale` 0), and the arch rune rims, veils and spill run at `forward_plus_arch_rim_scale` 0.35. Compatibility is unchanged, so CPU output is identical.
  - Also includes your review nits.
  - Test: `tests/test_crossing_hall_great_hall_renderer.gd`. `--only=crossing_hall,great_hall_renderer`: 9 tests, 0 failed.
  - GPU re-judge command: the F17-6 fixed set (`capture_camera_set.gd --set=res://tools/visual_judge/camera_sets/F17-6.json`) at Medium and High.

- 2026-10-24 17:45 UTC STATUS F38#5: Hall and relay rescan, after the fixture correction and the relay-pad change. See `f38-0/matrix.md`, "F38#5 rescan".
  - Mapped scores: Hall nave, shrine and arches 6.37 (was 4.25, 2.80 and 2.09). Relay yard 5.85 (was 5.19).
  - Void, black and inside-geometry frames and the floor hex decals are gone.
  - Still open:
    - The relay gameplay stand frames the trainer through the gate arch, with a pier filling half the frame. That needs shared camera code, so I'm reporting it, not changing it.
    - The arch rims read as neon on Compatibility. They wait on the F17#6 GPU verdict, because Low must stay identical.
    - The Hall walls hug the frame edge in arch detail views.
    - Shrine night is washed out.
  - The "waterfall/steam column" is the owner-specified objective beacon (`objective_beacon.json`) pointing at the Warrens. It's wayfinding, so I'm leaving it alone.
- 2026-10-24 17:45 UTC STATUS F38#0: the supplementals are capturing on CPU (creatures first, ~35 s a frame). The 40 remaining rows get one-sided sheets and three judges as each run lands. P2-015 terrapup faint now sits grounded in the fresh capture.

- 2026-10-24 17:55 UTC READY tb/meadows-land3 4d204e402 (from origin/main; supersedes land2 0a88dd931). F17#6 GPU fix, per the owner verdict you relayed: "The white beams of light in the hall seem like an error but the rest looks mostly fine."
  - Change: `crossing_hall_great_hall.gd renderer_scale()`. On Forward+/Mobile no daylight shafts are built (`forward_plus_shaft_scale` 0).
  - The arch rims now keep full weight on Forward+ (`forward_plus_arch_rim_scale` 1.0, was 0.35 in land2), so nothing else in the Hall is re-dressed.
  - Compatibility returns ONE, so CPU output is unchanged.
  - Test: `tests/test_crossing_hall_great_hall_renderer.gd`. The land2 version passed 9 tests with 0 failed. Re-run at 20:09 UTC on the land3 content with the rims assertion: `--only=crossing_hall,great_hall_renderer`, 9 tests, 31 assertions, 0 failed.
  - GPU capture command: `capture_camera_set.gd --set=res://tools/visual_judge/camera_sets/F17-6.json` at Medium and High.

- 2026-10-24 19:05 UTC STATUS F38#0 pass 2 (`f38-0/README.md`): ten creature and catch rows rescored, 4.14–5.29 mapped. Catch candidates in impact order:
  - P2-058 (impact 64): a new readout backing plate. `capture_readout_visual.json plate_enabled` is OFF.
  - P2-061 (impact 27): the UI lane's unjudged `hud.json catch_card`.
  - Both are queued for one ON catch capture after the supplementals, then judged per row.
  - The flat magenta wedge in catch_low is the enemy lunge-lane telegraph, not catch UI, so it belongs to the P2-063 fight-tell row.
  - P2-015/016/017 (creature pose and scale) live in `data/creatures/f36_pose_candidates.json`, which the creatures lane owns. Tell me if those are mine to change for Meadows species.

- 2026-10-24 20:20 UTC STATUS F38 L1 (camera stands, the 174 rejected): reproduced on CPU. The causes, from a physics probe at each stand:
  - Fixture: main's `capture-definition.json` still points the wall arches outward. The fix (arches in-room detail only, nave and shrine on the floor, `capture_f38_matrix.gd` honours `views` and `prefer_terrain_ground`) is on tb/meadows and lands with the stand fixes.
  - Quarry `band2_stone_and_root_0`: every stand sits in quarry dressing. The capsule overlaps the work wagon (gameplay), a foundation is 0.3 m above the terrain (detail), rocks and bag (reverse), and a tree (approach).
  - Ironwood 0/1: tree trunk colliders overlap the capsule (approach, detail), or a trunk behind pulls the camera in to 1.9–2.4 m (gameplay, approach).
  - arch_home approach (-23.7, 14): no collider at all within the probe window.
  - Village road, Hall front, shrine and farm approach: "no physical floor" (probe incomplete; search running).
  - A heading search (8 headings per stand, the same production preflight and camera checks, nothing relaxed) is running on CPU now. Next: re-seat each site at a passing heading in `capture-definition.json`, recapture those stands on CPU, then READY with the stand list.
- 2026-10-24 20:20 UTC NOTE F38 L2: the GPU "orb chains" in hall_nave are the same Forward+ shaft quads (they render as beaded white bars). land3 (shafts not built on Forward+) removes both.

- 2026-10-24 21:35 UTC STATUS F38 L1 (the 174 rejected stands): a CPU heading search (8 headings at each view's own offset; the same production preflight and settled camera checks) found a passing stand for every rejected view of 10 sites. tb/meadows b9031cb6b seats them:
  - `capture-definition.json` gains a per-site `view_headings` override.
  - `capture_f38_matrix.gd` reads it as an absolute view heading.
  - Seated sites: band2_stone_and_root_0, band3_the_river_lock_1, band4 ironwood 0/1, farm_to_hall, village_road, hall_front, hall_nave, shrine_room and arch_home.
  - The wall arches keep the earlier fix: in-room detail view only.
  - CPU verification recapture of those sites (day, clear and rain) is running. READY with the land SHA and stand list follows.
  - Your Cloudreach fallback note: the Meadows causes are mixed (quarry props, tree trunks, no floor, camera pulled in), so I seated stands in data rather than adding a capture-side fallback. If the shared helper lands, the seats stay valid.
- 2026-10-24 21:35 UTC RESULT catch candidates (close-1024 r1, CPU, three judges; `P2-058-061-catch1024.md`). Both are clear gains but below 7.5, so both stay OFF pending GPU:
  - P2-058 readout plate: 6.78 vs shipping 5.43.
  - P2-061 catch card: 6.34 vs shipping 4.65.
  - Since judging, the verdict frame steps the cards back on the same frame.
  - GPU capture command: `tools/phase2_capture_catch.gd --biome=meadows --seed=2042`, with `capture_readout_visual.json plate_enabled` and `hud.json catch_card.enabled` on for the candidate side.

- 2026-10-24 22:15 UTC READY tb/meadows-land4 62e64e6bf (from origin/main): the F38 tier-1 camera fixture (L1). Fixture only, no game code.
  - Changes in `capture-definition.json` and `capture_f38_matrix.gd`:
    - The wall arches face into the Hall and keep only the in-room detail view.
    - The nave and shrine stand on the Hall floor.
    - Ten sites get per-view heading seats from the CPU search.
    - The tool honours `views`, `prefer_terrain_ground` and `view_headings`.
  - CPU evidence for the arch, nave and shrine part: 48 Hall frames, 0 void, 0 black; Hall area mapped 6.37 (was 2.09–4.25).
  - The seated stands' CPU recapture is still running; I'll post the per-stand result here.
  - Tier-1 stands for the GPU recapture: arch_biome5, arch_biome6, arch_biome7, arch_biome8, arch_cloudreach, arch_tidewake, arch_stormwood, arch_home, hall_nave, shrine_room, hall_front, farm_to_hall and band2_stone_and_root_0. village_road and band3_the_river_lock_1 are parked under the tier rule.
  - Command: `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=arch_ --subset=hall_nave --subset=shrine_room --subset=hall_front --subset=farm_to_hall --subset=band2_stone_and_root_0 --output=res://<round>`
  - Land together with land3 (4d204e402, F17#6: Forward+ shafts off). The Hall stands judge both, and land3 is not on main yet.

- 2026-10-24 22:30 UTC MESHY (P2-003 hero stronghold, tier 1: band5_stronghold_1 4.59, band5_0 5.66):
  - Reference: the owner key art's "TEAM TETHER STRONGHOLD (MEADOWS HALL)" panel, `docs/reference/tetherbound-meadows-keyart.png` crop box (527, 632)–(1063, 905), upscaled 2x. The local copy is at `ralph/reports/MEADOWS/close-1024/meshy/stronghold_hero_ref.png`, which the repo ignores.
  - Dimensions: gatehouse facade about 28 m wide x 20 m tall x 12 m deep. It is sized to the existing Hall gate (flanker towers at x ±10.6, about 16–19 m tall). Against the 1.80 m trainer, the gate arch is about 6 m tall and the towers about 10x trainer height.
  - Prompt: "ruined weathered grey stone gatehouse fortress facade, two tall square flanking towers with broken crenellations, central round-arched wooden gate with iron bands, ivy and moss growing down the stone, narrow hanging dark-oxblood cloth banners with a pale circular emblem, timber scaffolds and iron machinery bolted to the towers, stylised realism, game asset, base at ground level."
  - Purpose: replaces the read of "a small dark ruin behind dominant pylons" (P2-003) and the giant flat banners at band5_1.
  - It will be installed flag-off on the `stronghold.json` prefab exterior, then judged on the band5 stands.

- 2026-10-24 23:25 UTC RESULT land4 seats, CPU verification part 1 (`capture_f38_matrix.gd`, day, clear and rain, Low): 38 of 38 rows reached captured, with 0 rejected stands and 0 failures.
  - Captured: band2_stone_and_root_0 (all 4 views; the GPU run had 0 frames here), band3_the_river_lock_1, band4 ironwood 0 and 1 (all 4 views each), and farm_to_hall.
  - The run hit its 108-minute CPU limit before village_road, hall_front, hall_nave, shrine_room and arch_home. Those five are recapturing now as part 2.

- 2026-10-25 01:10 UTC RESULT land4 seats, CPU verification part 2: 35 rows captured, 0 rejected stands, 0 failures.
  - All 4 views captured at village_road, hall_front, hall_nave and shrine_room. arch_home captured approach, gameplay and reverse before the CPU time limit.
  - Across both parts, 73 of 73 reached rows captured. Every stand that was rejected on the GPU, at the 10 seated sites, now yields a frame on CPU.
  - Open: band3_the_river_lock_0. It passes the checks, but its gameplay and detail stands frame the trainer under the gate wall, beside a timber wall. A heading probe (90/135/225/270) is capturing now; the chosen seat follows as a separate READY.

- 2026-10-25 01:40 UTC READY tb/meadows-land5 d9f675f3b (from origin/main; supersedes land4 62e64e6bf): the F38 tier-1 camera fixture (L1). Fixture only.
  - Everything in land4, plus band3_the_river_lock_0: its gameplay view moves to heading 270 and its detail view to 135, off the gate wall onto the open yard (chosen from a CPU probe at 90/135/225/270).
  - CPU verification: 73 of 73 seated rows captured, 0 rejected.
  - GPU recapture stands (tier 1): arch_* (all 9), hall_nave, shrine_room, hall_front, farm_to_hall, band2_stone_and_root_0 and band3_the_river_lock_0.
  - Command: `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=arch_ --subset=hall_nave --subset=shrine_room --subset=hall_front --subset=farm_to_hall --subset=band2_stone_and_root_0 --subset=band3_the_river_lock_0 --output=res://<round>`
  - Land with land3 (4d204e402, F17#6/L2: no shafts on Forward+). The owner's "white beams" and the GPU's "orb chains" are both those Forward+ shaft quads. On Compatibility the shafts stay as judged (CPU r9 6.84).
- 2026-10-25 01:40 UTC READY (test pending) F04#6 r31 Meshy aftermath heroes, wired as an OFF candidate on tb/meadows 6549fbaee:
  - `trainer_aftermath.json`: `meshy_heroes_enabled: false`, and `meshy_heroes` holds the whole r31 sites (Dell, Riverwatch, Field and Ridge).
  - `trainer_aftermath.gd`: when the flag is on, those sites replace `visual_candidate_sites`.
  - Test: `tests/test_trainer_aftermath_meshy_heroes.gd`, queued behind the CPU supplementals. I'll report the result here, then build a land branch.
  - CPU pre-judge (already done, `F04-6.md`): r31 6.23 vs shipping 5.86, parked under the gain rule.
  - GPU command: `tools/_probe_aftermath_sites.gd --cameras=res://tools/visual_judge/camera_sets/F04-6.json --candidate`, with `meshy_heroes_enabled` on for the candidate side.

- 2026-10-25 01:55 UTC MESHY batch (F38 tier-1 and L6 new art).
  - Sizes are against the 1.80 m trainer, measured from the close-1024 CPU Hall frames.
  - Each asset installs flag-off and is judged on its own stands before going ON.
  1. Travel-arch facades, three assets, one per destination. Each is an arch surround that frames the existing door opening (about 2.6 m wide x 3.8 m tall), overall about 4.4 m wide x 5.2 m tall x 0.7 m deep, open in the middle.
     - (a) arch_tidewake. Ref: `docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png`. Prompt: "carved stone portal surround for a doorway, pale limestone weathered by sea spray, inlaid shells and wave scroll carving, a small cyan glass keystone, rope-and-driftwood trim, stylised realism, game asset, open centre".
     - (b) arch_cloudreach. Ref: `docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`. Prompt: "carved stone portal surround for a doorway, pale stratified sandstone in horizontal bands, feather and wing relief carving up both jambs, a bronze eagle keystone, stylised realism, game asset, open centre".
     - (c) arch_biome5 (sealed, unbuilt chapter). Ref: owner key art, standing-stone panel, `docs/reference/tetherbound-meadows-keyart.png` crop (1027, 333)–(1535, 600). Prompt: "sealed ancient stone portal surround for a doorway, dark grey monolith blocks with a faint blue spiral rune carved in the keystone, moss in the joints, heavy and closed-looking, stylised realism, game asset, open centre".
  2. Ironwood canopy trees (band4 ironwood stands). Ref: owner key art, oak-grove panel, crop (0, 333)–(540, 600). Two variants, about 14 m tall with a 10–12 m crown and a 1.2 m trunk. Prompt: "huge old broadleaf ironwood tree, thick gnarled dark trunk with exposed roots, dense layered leaf-card canopy in clustered clumps, warm green with lighter tips, stylised realism like Valheim and Palworld, game asset".
  3. Sculpted stratified cliff faces for band2_stone_and_root_1, replacing the flat facets and dark slash shapes (P2-014). Ref: `docs/reference/boards-2026-09-06/cloudreach-cliffs-creature-roster-board.png` (stratified stone), with the key art's Meadows grey-stone palette. Two modular pieces, about 30 m wide x 15 m tall x 10 m deep, plus a 12 m corner piece. Prompt: "modular grassy hillside cliff face, layered grey sedimentary rock strata with rounded weathered edges, grass and moss spilling over the top lip, small ledges and boulders at the foot, stylised realism, game asset".
  - Also outstanding: the stronghold hero gatehouse (posted 22:30 UTC above).

- 2026-10-25 02:00 UTC READY tb/meadows-land6 3e06c8ddf (from origin/main): F04#6 r31 Meshy aftermath heroes as an OFF candidate.
  - Contents: the three GLBs with textures, provenance and references (main had none of them), `trainer_aftermath.json meshy_heroes` with `meshy_heroes_enabled: false`, the `trainer_aftermath.gd` overlay, and the test.
  - Test: `--only=trainer_aftermath`, 18 tests, 158 assertions, 0 failed.
  - CPU: r31 6.23 vs 5.86.
  - GPU: judge with `meshy_heroes_enabled` on as the candidate side; the command is in the line below.

## Work log

- F17#6 r9: capturing the shipping baseline (main, r8 ON) on `F17-6.json`. Candidate: `F17-6-r9-apply.py`, which moves the posts to x=+-5.0 and stretches the ties to span 10 m (the archive r9 left the ties at 6.6 m, so they would have stopped short), turns hall_dressing ON without its plaster runners, and turns hall_great_hall ON.
- F17#6 r9: 6.84 mapped vs 5.82 → CPU-provisional met; READY on tb/meadows-land (merged into the coordinator branch 80c9421d2).
- F04#6: shipping recaptured on the F04-6 set. Riverwatch and Ridge still share the fallen banner plus relit-stone template. The different approach is the three Meshy heroes above; waiting on GLBs.
- F38#1 P2-059/060 catch r1: 6.42 vs 6.08 (OFF; `P2-059-060-catch.md`). r2 candidate (OFF): the resolve shot pivots between the trainer and the orb (`catching.json framed_camera.resolve_camera.trainer_share`, `combat_manager.gd _trainer_frame_offset`).
- F38#1 P2-087: on the real named-fight path (`capture_named_fight.gd --resolve=won`), Warden Aldis is framed with his dialogue and Old Bram is in frame, small. The empty-meadow defect came from the direct-start fixture. Capturing `speaker_frame_candidate_enabled` against shipping now.

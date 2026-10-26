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

- 2026-10-25 03:15 UTC STATUS F38 L4 (P2-005 carpet): PARKED after three CPU attempts with no visible change.
  - Attempts, on farm_to_hall, band2_stone_and_root_1 and band5_0, approach and gameplay, ship vs candidate: grass drift r1 (0.07/0.8), grass drift r2 (0.045/1.0 plus height jitter), and terrain macro patches at 12 m in clover green.
  - Why it fails: the drift gaps lose blades, but the ground under them is the same painted grass, and the near-field read is the blades plus the baked terrain colour map, which the shader knobs don't reach.
  - What it needs, as a bake/art change rather than tuning: authored ground variation in the terrain colour bake (worn earth, clover and moss patches, rock outcrops, grove edges) or new ground-cover art.
  - Both candidates stay OFF with `_parked` notes and are not for the GPU.
  - QUESTION: is a Meadows terrain colour-bake pass (it fingerprints the terrain and vegetation bakes) in scope for this lane, or does it go to a world/terrain owner?
- 2026-10-25 03:15 UTC NOTE L3 (interior time-of-day grade): not started, deliberately. Per your relay of the owner's F17#6 verdict ("the rest looks mostly fine", don't re-dress the hall), the Hall interior stays as is apart from the shafts (land3). Tell me if L3 should override that.

- 2026-10-25 03:55 UTC RESULT F38 L4 colour-bake pass (per your approval): built and tested, no visible effect, PARKED.
  - The tool is `tools/bake_meadows_colour_candidate.gd` (colour only: clover, moss, worn-earth halo and outcrop-base variation from each region's own maps). `meadows_colour_candidate.gd` swaps the maps in at runtime behind `terrain_presentation.json colour_candidate.enabled` (OFF). No height, control, collision, vegetation or fingerprint change.
  - The swap demonstrably ran (64 regions). The CPU capture at farm_to_hall, band2_stone_and_root_1 and band5_0 (approach and gameplay) is still identical to shipping.
  - That makes four carpet attempts with no visible change. At play-camera distances the grass blade layer covers the ground completely, so neither terrain colour nor shader macro reaches the frame.
  - PNGs not committed (7.6 MB for no effect); the tool regenerates them.
  - The carpet lever is the blade layer itself (per-patch blade tint, species mix and height) or new ground-cover art. I'm not starting a fifth attempt on my own; say if you want the blade-tint route, or a MESHY/texture ask for ground cover.
  - Next: L5 haze and L6 facades, per your order.

- 2026-10-25 04:50 UTC RESULT F38 L4 blade-layer route r3 (per-patch tip tint, per-patch height, soil-driven thinning, with the colour-bake swap): three code-blind judges scored it level with shipping. Mapped 6.05 vs 6.07; raw 6.0/6.0/5.8 vs 6.0/6.0/5.9; defect PRESENT or PARTIAL on both sides. Files: `carpet-r3-*`. Parked, OFF.
  - That is five carpet attempts, so I'm stopping here per your instruction.
  - What the judges still ask for at every site: "clustered flower drifts of several species and sizes, worn dirt and bare patches, rock outcrops, taller grass edges".
  - That is placed ground cover, not tinting.
- 2026-10-25 04:50 UTC MESHY / texture ask (P2-005 ground-cover art). Sizes are against the 1.80 m trainer. Each item installs as a flag-off cover tier in `grass_field.json cover_tiers` (same instancing as the bushes and flowers), judged on the L4 views.
  1. Clover and broadleaf ground-cover clumps, 3 variants, about 0.6–0.9 m across and 0.15–0.25 m tall. Ref: the owner key art's meadow foreground panels (`docs/reference/tetherbound-meadows-keyart.png`, crops (357, 8)–(1000, 325) and (546, 333)–(1022, 600)). Prompt: "low clump of clover and broadleaf meadow ground cover, round leaves in mixed greens with a few small white and pink blossoms, stylised realism, game asset, flat base".
  2. Mixed wildflower drift clumps, 3 variants (purple lupin, gold buttercup, white daisy), about 0.8–1.2 m across and 0.3–0.6 m tall, several stems per clump. Same ref (the key art's purple and white drifts). Prompt: "dense clump of wild meadow flowers, many stems of one species with varied heights, stylised realism, game asset, flat base".
  3. Worn-earth and stone-scatter decal-patch meshes, 2 variants, about 2–3 m across and near-flat (under 0.1 m), with pebbles and dry grass edges, to sit on paths and trampled yards. Ref: the key art's dirt path in the top-left panel. Prompt: "flat patch of worn trampled earth with small pebbles and dry grass tufts at the edge, stylised realism, game asset, very low profile".
  4. Small rock-outcrop clusters, 2 variants, about 1.5–2.5 m across and 0.6–1.0 m tall, mossy grey, half-buried. Ref: the key art's river-bank stones (top-right panel). Prompt: "cluster of half-buried mossy grey rocks, rounded weathered stones of mixed sizes, stylised realism, game asset, flat base".

- 2026-10-25 05:50 UTC READY tb/meadows-land7 1edc159ae (from origin/main; supersedes land5 d9f675f3b and land4): the F38 camera fixture plus the baseline-dressing fix.
  - Contents: everything in land5, plus:
    - farm_to_hall moves out of Grandpa's house onto the farm-to-Hall road. Its gameplay, reverse and detail now show the village road to the Hall. The approach at heading 135 is CPU-verified, day and night.
    - `meadows_catalog_presentation.gd`: `--f38-baseline` stripped the shipped (ON) catalog dressing from every matrix frame. Without the Hall's two end banners, the shipped Hall waymark failed and the Hall build returned early. Baseline now withholds only OFF candidates.
  - Test: `--only=catalog_presentation_gate,crossing_hall`, 11 tests, 0 failed.
  - CPU check, hall_nave and farm_to_hall, day and night: the waymark applies and the layout error is gone. The end banners are back in the nave frames.
  - Correction to my earlier guess: this does NOT change the Hall's day/night grade. Night still reads paler than day; that is Hall lighting (L3), left alone per the owner.
  - Impact: every earlier matrix frame (CPU and GPU) lacked the shipped catalog dressing, so the whole matrix should be recaptured from this fixture.
  - GPU command: `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --output=res://<round>` (full matrix, or `--subset=` per tier-1 stand).
  - Land with land3 (shafts off on Forward+) and land6 (F04#6 heroes OFF).

- 2026-10-25 09:10 UTC STATUS (reply to 09:02): you were right, the 05:39 cover capture died. The cause was the disk allowance: only 1.3 GB was free.
  - Freed ~1 GB of finished judge folders and capture copies in /tmp, not repo content.
  - Restored the capture's temporary definition edit from git.
  - Re-running the A/B as two separate runs, with a git-based restore on exit so a crash cannot strand edits: shipping vs ground-cover tiers plus blade layer, on band2_stone_and_root_1 and band5_stronghold_approach_0, approach and gameplay, clear and rain.
  - Queued next: a heading probe for band5_stronghold_approach_1 (4.59). Its gameplay and detail cameras press into machinery and a pillar in the courtyard, the same L1 fix as river lock 0.
  - Not delivered yet on tb/meshy-1024: the arch facades, the stronghold hero, the stone_and_root cliffs and the Ironwood canopies. Those tier-1 stands (arch_*, band5_0/1, stone_and_root_1) wait on them after L1 and L2.

- 2026-10-25 11:20 UTC READY (GPU confirm) tier-1 new art r1, CPU A/B vs shipping (`art1024-batch.json`, `art1024-mapped.json`, `_sheet_art1024_r1.png`; key `art1024-key.json`). Three fresh code-blind judges; anchors f36_0_npc:C1, p2_094_r4, craft; calibrate slope 1.64, r 0.98, RMSE 0.31 (confirming batch).
  - **Arch facades** (`crossing_hall.json arch_facades`): mapped **6.92 vs 5.50** (+1.42). Meets the 6.7 CPU-provisional bar. Judges still flag the violet rims on the unfaced arches (stormwood, biome6–8) next to the new surrounds; r2 below.
  - **Cliffs** (`meadows_hero_pieces.json cliffs`): mapped **5.93 vs 4.89** (+1.04) at band2_stone_and_root_1. Clears tier 1 (≥5.2 CPU), below 6.7. Remaining: the faceted Burrow hill flank and the ramp slab (terrain, not this asset).
  - **Gatehouse** (`stronghold.json hero_gatehouse`): **5.44 = 5.44**, no visible change. At 28 m wide it is a speck from band5_0 (550 m) and out of frame at band5_1. Resize round queued.
  - All three stay OFF until GPU confirms. GPU command, each with its flag set `enabled: true` for the candidate side and `false` for shipping: `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=arch_tidewake,arch_cloudreach,arch_biome5,band2_stone_and_root_1 --output=res://<round>`. Recommend turning arch_facades and cliffs ON if GPU agrees (both are clear gains with no judged regression).
  - Next here: arches r2 (reuse the sealed biome5 surround on biome6–8 and a carved surround on stormwood so no neon rim sits beside a faced arch), gatehouse r2 (larger, until it reads from 550 m), then the cover r2 capture already queued.

- 2026-10-25 11:24 UTC MESHY (F38 L6, arch r2 follow-up): arch_stormwood, one asset. Until it lands, r2 reuses the tidewake surround on the stormwood arch.
  - Same envelope as the r1 surrounds: about 4.4 m wide x 5.2 m tall x 0.7 m deep, framing the existing ~2.6 x 3.8 m door, open centre; the 1.80 m trainer stands about a third of its height.
  - Ref: `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png`, with the key art's Meadows stone palette so it sits in the Hall.
  - Prompt: "carved dark oak and grey stone portal surround for a doorway, twisted root and branch relief climbing both jambs, a small pale-blue lightning glass keystone, iron straps, stylised realism, game asset, open centre". No oxblood.

- 2026-10-25 11:28 UTC READY (test pending) tb/meadows-land8 7472798460 (from origin/main): tier-1 new art wired OFF.
  - Contents: Hall arch facades (`crossing_hall_arch_facades.gd`, `crossing_hall.json arch_facades`, now covering all seven chapter arches), the stronghold hero gatehouse (`stronghold_hero_gatehouse.gd`, `stronghold.json hero_gatehouse`, r2 placement), and the Meadows hero pieces (`meadows_hero_pieces.gd`, `meadows_hero_pieces.json`: cliffs and Ironwood). It also carries their ten `assets/props/meshy-1024/meadows_*` assets, imported with policy passed, and three one-line hooks.
  - Every flag is false, so shipping is unchanged. Test: `tests/test_meadows_tier1_art_gates.gd`, queued behind the CPU captures; I'll post the result here.
  - It lands alongside land3, land6 and land7 with no overlapping hunks (land3 touches other keys in `crossing_hall.json`).
  - Use it for the GPU art pass in the 11:20 READY (flip each flag on for the candidate side).

- 2026-10-25 12:52 UTC READY (GPU confirm) tier-1 art r2 (`art1024r2-*.json`, `_sheet_art1024_r2.png`). Three fresh code-blind judges; anchors p2_094_r4, f04_6_r22, craft; slope 1.96, r 0.97, RMSE 0.34; confirming batch.
  - **Arch facades r2** (all seven chapter arches faced; stormwood borrows the tidewake surround, biome6–8 the sealed one): mapped **8.08 vs 5.28** shipping. r1 was 6.92 vs 5.50. CPU-provisional met in two batches, so `arch_facades.enabled` is now **ON** on tb/meadows (score in `_why_on_r2`).
  - GPU command: `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=arch_ --output=res://<round>` on tb/meadows-land9 (facades ON) against main (OFF). A GPU score below 7.5 reopens it.
  - Remaining judge notes: the pale Cloudreach surround washes out by day and greys at night; the window-strip wall still shows behind.
  - **Gatehouse r2** (a 60 m keep behind the stronghold): 6.58 vs 6.19 (+0.39). r1 gained 0.00, so that is two rounds under 0.5 and it is **PARKED**, OFF. All judges still read a speck that vanishes at night; MESHY line below.
- 2026-10-25 12:52 UTC MESHY (P2-003, replaces the gatehouse approach): Meadows stronghold skyline landmark, a lit keep.
  - Ref: owner key art, the stronghold/hall panel (`docs/reference/tetherbound-meadows-keyart.png`).
  - Size: about 70 m tall overall with two towers, roughly 40x the 1.80 m trainer, so it reads from 550 m.
  - Prompt: "tall fortified stone keep with two slender towers and a high central hall, warm lit windows, braziers on the battlements, oxblood banners only on the towers, weathered grey stone, stylised realism, game asset, readable silhouette from a distance".
  - It must carry emissive window and brazier materials so it holds at night (all three judges named the night vanish).

- 2026-10-25 12:55 UTC READY (test pending) tb/meadows-land9 18d660876f (from origin/main 1d5faebac; supersedes land8 7472798460): the same tier-1 art as land8, with `arch_facades` ON (judged passing) and the gatehouse parked OFF. Test `tests/test_meadows_tier1_art_gates.gd` (updated for facades ON) is queued behind the CPU captures.

- 2026-10-25 13:04 UTC READY tb/meadows-land10 0133455e34 (from origin/main 1d5faebac; supersedes land7 1edc159ae): the F38 camera fixture plus the baseline-dressing fix, with two new probe-verified seats.
  - band5_stronghold_approach_1: gameplay and detail views at heading 45 (probe `shots/f38_1024_shprobe` tried 45/90/135; 45 is clear of the courtyard pillar and the crates).
  - hall_front: gameplay view at heading 45. At 135 the camera settled inside a house eave; of 0–315, only 45 and 270 pass, and 270 looks down the nave.
  - GPU command: as in the land7 READY, adding `--subset=band5_stronghold_approach --subset=hall_front`.

- 2026-10-25 13:06 UTC STATUS (reply to the 13:04 directive; send_message to the coordinator is refused: elevated_session_untrusted_device).
  - All 9 heroes from tb/meshy-1024 4eb886a11 are wired and CPU-judged:
    - arch facades: ON, 8.08 vs 5.28 (land9);
    - cliffs: 5.93 vs 4.89, OFF pending GPU, recommend ON;
    - gatehouse: parked after two rounds under 0.5;
    - Ironwood: A/B capturing now.
  - Ground cover is the new-art route already: 10 Meshy tiers. r2 rendered real variety but placed about 11.7k items (55 min per CPU frame). r3 cuts reach and triangles for cost; it is not a look tweak.
  - Dominant object per GPU stand below 6, from the GPU verdict (tb/gpu-pass F38-0/main-1024) and current CPU frames:

| Stand (GPU) | Dominant object | Covered by |
|---|---|---|
| arch_* (3.53–5.26) | blank arch / plaster wall; camera in rock | facades ON (land9), L1 seats (land10) |
| arch_home 5.85 | shaft slabs over the pillars | L2 (land3); facade MESHY below |
| hall_nave 4.77, hall_front 5.82, shrine_room 5.53 | white shaft quads and orb chains (Forward+) | L2 (land3); hall_front seat (land10) |
| band5_stronghold_1 4.59 | giant flat oxblood banners filling the courtyard | scene: banner scale-down candidate, now |
| band5_stronghold_0 5.66 | stronghold a speck behind the pylons | MESHY lit keep (12:52) |
| band2_stone_and_root_1 5.82 | faceted Burrow mound with slab ramp | cliffs OFF/ready; MESHY 1 below |
| band3_the_river_lock_0 5.29 | bare flat dirt yard filling the lower half | MESHY 2 below |
| band2_stone_and_root_0 (no GPU frames) | pale untextured quarry blocks beside the trainer | MESHY 3 below |
| farm_to_hall 5.60 | orange-washed house interior | L1: re-seated onto the road (land7/10) |

- 2026-10-25 13:06 UTC MESHY (dominant objects, F38 tier 1). One change each. All install flag-OFF and are judged on their own stand. Sizes are against the 1.80 m trainer.
  1. **meadows_burrow_mound** (band2_stone_and_root_1, the Warrens entrance at about (-357, 2610)).
     - Size: about 40 m wide x 14 m tall x 30 m deep.
     - Ref: owner key art, the burrow/hill panel (`docs/reference/tetherbound-meadows-keyart.png`), and `docs/reference/palworld-04-plateau-landmark.jpg` for the sculpted grassy rock.
     - Prompt: "large grassy hill mound with a dug burrow entrance, rounded sculpted earth and layered grey rock outcrops, grass and moss draping over the top, a worn dirt path leading into a round tunnel mouth framed by roots and stones, stylised realism, game asset".
     - Replaces the faceted planes and the slab ramp.
  2. **meadows_lock_yard_paving** (band3_the_river_lock_0).
     - Modules: 8 x 8 m and 8 x 4 m tiles plus a curb edge. Several tile the about 30 x 40 m lock yard.
     - Ref: `docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png` (quay stone) with the key art's warm Meadows stone.
     - Prompt: "worn flagstone yard paving module with irregular grey-tan stones, moss and grass in the joints, a few puddles and wheel ruts, flat with a low curb edge, stylised realism, game asset, tileable layout".
  3. **meadows_quarry_blocks** (band2_stone_and_root_0, the stone quarry).
     - Set: three cut-stone piles (1–2 m blocks, stacked 2–3 m high) and one half-cut quarry face, about 6 m tall.
     - Ref: owner key art, grey stone palette; `docs/reference/palworld-05-base-building.jpg` for the stacked resources.
     - Prompt: "stacked cut granite blocks in a working quarry, chisel marks, wooden wedges and a rope sling, moss on the lower stones, grey-tan stone, stylised realism, game asset".
     - Replaces the pale untextured cubes.
  4. **meadows_arch_home** (arch_home, the Hall's home doorway).
     - Same envelope as the r1 surrounds (about 4.4 x 5.2 x 0.7 m, open centre).
     - Ref: owner key art, Meadows Hall panel.
     - Prompt: "warm carved oak and limestone portal surround for a great hall doorway, wheat and leaf relief on the jambs, a carved sun keystone, stylised realism, game asset, open centre".
  5. **meadows_tether_war_banner** (band5_stronghold_approach_1, the courtyard heraldry; replaces the flat cloth quads, not the banner sizes).
     - Size: about 2.4 m wide x 7 m drop, with a carved pole and crossbar (the board's 6–8 m banners). Oxblood is correct here: it is Team Tether's own stronghold.
     - Ref: `docs/reference/owner-board-2026-08-15-systems-and-castle.png` (castle banners) and the key art's stronghold panel.
     - Prompt: "heavy hanging war banner, deep oxblood wool with deep vertical folds and a tattered, frayed hem, a pale stitched circle-and-cross emblem, iron-capped wooden crossbar and pole, stylised realism, game asset".
     - Why replacement rather than a rescale: earlier judges asked for the banners 3–4x larger (T1-HALL-4); the GPU judge now reads them as "giant flat banners". Flat cloth is the defect, and a rescale would oscillate.

- 2026-10-25 14:10 UTC READY (GPU) **one combined hero candidate**: tb/meadows-land11 89c5b91f64 (from origin/main 818e5afe3; supersedes land8 and land9). Focused tests pass: `test_meadows_tier1_art_gates`, `test_trainer_aftermath_meshy_heroes` and `test_meadows_catalog_presentation_gate`, 7 tests, 23 assertions, 0 failed.
  - **Correction:** land9 shipped `arch_facades` ON on a CPU score. Main's CLAUDE.md says GPU judging replaced the CPU-provisional rule on 24 Oct. land11 keeps every flag OFF; the scores live in each `_why`.
  - Contents: all 9 heroes from 4eb886a11, each behind its own flag. CPU A/B vs shipping (three code-blind judges, mapped):
    - `crossing_hall.json arch_facades` (all seven arches): 8.08 vs 5.28 (r1 6.92 vs 5.50).
    - `meadows_hero_pieces.json cliffs` at band2_stone_and_root_1: 5.93 vs 4.89.
    - `meadows_hero_pieces.json ironwood` at band4 ironwood 0/1: 5.86 vs 5.20 (`iw1024-*`, `_sheet_iw1024_r1.png`).
    - `stronghold.json hero_gatehouse` at band5_0/1: parked (+0.00, then +0.39), included for completeness. The band5_1 courtyard seat (land10) rides along.
  - GPU command: on land11 merged with land10 (fixture) and land3 (shafts), set all four flags `enabled: true`, then run `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=arch_ --subset=band2_stone_and_root_1 --subset=band4_upper_meadows_ironwood --subset=band5_stronghold_approach --output=res://<round>`. Compare against the same command with the flags off.
  - Each flag goes ON only where GPU gains more than 0.5 on its own stands.
- 2026-10-25 14:10 UTC MESHY (band4, dominant object after the Ironwood trees): **meadows_giant_ironwood**. All three judges name the existing giant ironwood behind the Grove stand: "flat, faceted low-poly canopy shards against the sky".
  - Size: about 30 m tall with a 24 m crown and a 3 m trunk with buttress roots, matching the existing giant at the Grove stand (-345, 5060) looking +z.
  - Ref: owner key art, oak-grove panel (crop (0, 333)–(540, 600)).
  - Prompt: "ancient colossal ironwood tree, massive buttressed trunk with gnarled bark and moss, enormous layered canopy of dense leaf-card clusters with light breaking through, warm green with sunlit tips, stylised realism like Valheim and Palworld, game asset, single hero tree".
  - It replaces the existing giant (one change); the r1 Ironwood trees stay as they are.

- 2026-10-25 16:16 UTC STATUS (waiting): nothing in this lane is expected to gain more than 0.5 without new art or a GPU verdict, so no captures are running.
  - **Board rows:**
    - F17#6: READY tb/meadows-land3 4d204e402 (no shafts on Forward+; CPU r9 6.84).
    - F04#6: READY tb/meadows-land6 3e06c8ddf (Meshy aftermath heroes OFF; CPU r31 6.23 vs 5.86).
    - Both wait on the GPU pass.
  - **Tier-1 heroes:** READY tb/meadows-land11 89c5b91f64 (all OFF) plus tb/meadows-land10 0133455e34 (camera seats). These are waiting on the GPU pass too.
  - **MESHY:** none of the eight requested assets is on tb/meshy-1024 yet (checked 14:42, 15:14 and 16:16): burrow mound, lock-yard paving, quarry blocks, home arch, war banner, lit keep, Stormwood arch, giant ironwood. I wire each OFF on delivery and post a CPU A/B READY.
  - tb/meadows has origin/main merged (0fe451688).

- 2026-10-25 17:49 UTC READY tb/meadows-land12 a634da3791 (from origin/main 0fe451688): **use this in place of land10 for the queued GPU hero run.**
  - land10 and land7 carried a leaked capture trim (committed in a3f1e8cfc). It limited band2_stone_and_root_1, band5_stronghold_approach_0 and farm_to_hall to the approach and gameplay views, so a GPU run on land10 would skip their reverse and detail views.
  - land12 is land10 without that trim. The deliberate detail-only arch views stay.
  - Hero run: land11 + land12 + land3, with the GPU command in the land11 READY.
  - Coordinator's 17:46 note received: eight MESHY assets generating. I wire each OFF on delivery.

- 2026-10-25 19:39 UTC READY **tb/meadows-land13 d9f0525d0b** (from origin/main ca8901ce0; replaces land3, land7, land8–land12 for landing). This is the coordinator's 19:11 ask.
  - **arch_facades ON:** GPU MH (tb/gpu-pass bf099dd2f) measured +0.79 Medium and +1.11 High, with L6 going PRESENT→PARTIAL on 6 of 6. The gain is in `crossing_hall.json arch_facades._why_on_gpu`. Every other land11 flag ships OFF: cliffs +0.40, Ironwood trees negative, gatehouse invisible.
  - **land12 fixture:** per-view seats, the baseline dressing gate, and no leaked view trim.
  - **land3, F17#6:** no daylight-shaft quads on Forward+/Mobile; Compatibility is unchanged.
  - **Hard-rule fix, oxblood tufts:** Grass_Wheat's UVs all sample the orange-red column of the shared `Grass.png` atlas, and the drygrass straw multiply turned it rust-red. `derived/Grass_wheat_straw.png` repaints only that column straw gold, swapped in through `vegetation_presentation.json retexture`. I left `vegetation.json` alone because its bytes are the scatter fingerprint, so the bake stays fresh. A CPU check at band5_stronghold_approach_0 shows every red tuft now straw gold, with the rest of the frame unchanged.
  - **Tests on land13's own files:** `test_meadows_tier1_art_gates` (facades ON, the rest OFF), `test_crossing_hall_great_hall_renderer`, `test_meadows_catalog_presentation_gate` and `test_stronghold_banner_camera_occluder` give 9 tests, 32 assertions, 0 failed.
  - land6 (F04#6 aftermath heroes OFF) stays a separate branch, unchanged.

- 2026-10-25 20:06 UTC **FIXED feaf24a32** (PR #750, tb/meadows-land13). `Grass_wheat_straw.png.import` is now mode 2 (s3tc_bptc, mipmaps on, detect_3d 0) and reimported, and `texture_import_policy.py --check` passes for all 1019. I ran `test_texture_import_policy`, `test_meadows_tier1_art_gates`, `test_crossing_hall_great_hall_renderer`, `test_meadows_catalog_presentation_gate` and `test_stronghold_banner_camera_occluder` on land13's own files: 11 tests, 1253 assertions, 0 failed. My send_message was refused (untrusted device).
  - Harness note for TECHNICAL §8.1: `texture_import_policy.py --apply <file>` updates 0 sidecars, because it takes directories. For a single new texture outside `meshy-*`, set `compress/mode=2`, `mipmaps/generate=true` and `detect_3d/compress_to=0` in its `.import`, then run `godot --headless --import`.

- 2026-10-25 20:34 UTC READY (GPU) **tb/meadows-land14 47ea49dca2** (from origin/main c361f575e, which has land13). Hero bundle 2, with every flag OFF. It contains:
  - **The lit keep** (`stronghold.json hero_gatehouse`, the Meshy meadows_lit_keep from ae67083ec): 110 m wide, about 122 m tall, 130 m past the mouth, with a window/brazier emission mask and an albedo tint toward weathered stone. CPU result (`dom1025-*`, `_sheet_dom1025.png`): band5_0 day+night raw 5.67 vs 4.97 (+0.70), mapped +0.44 on a weak fit (slope 0.63, r 0.52, because the C9 anchor pair scored identically). P2-003 went PRESENT→PARTIAL for all 3 judges, who agree it "reads as a landmark fortress day and night". Their critique ("bleached white") is answered by the tint, CPU-checked (`f38_keep_cand3`). Confound: the shipping frames predate the oxblood tuft fix.
  - **War banners** (`stronghold.json banner_model_candidate`): the Meshy war banner at each courtyard banner slot. The camera occluder and the Warden take-down are unchanged.
  - **Courtyard declutter (ships, rides along):** camp props 18–20 move off the band5_1 gameplay seat.
  - **The giant ironwood** (`ironwood_grove_presentation.json hero_tree.model_candidate`, Meshy meadows_giant_ironwood): replaces the faceted landmark tree with a uniform fit to its height. CPU raw 6.37 vs 4.93 (+1.43), mapped +0.90. The defect went PRESENT→PARTIAL for all 3, read as "a believable broad oak".
  - **Tests on land14's own files:** test_meadows_tier1_art_gates, test_texture_import_policy, test_stronghold_banner_camera_occluder and test_meadows_banner_capture_0912 give 13 tests, 1331 assertions, 0 failed.
  - **GPU command:** for the candidate side, set `hero_gatehouse.enabled`, `banner_model_candidate.enabled` and `hero_tree.model_candidate.enabled` true. Then run `capture_f38_matrix.gd --seed=2042 --f38-preset=<Medium|High> --f38-baseline --times=day,night --subset=band5_stronghold_approach --subset=band4_upper_meadows_ironwood_0 --output=res://<round>`, and repeat with them false. The keep and banners judge on band5_0/1, the tree on ironwood_0.
- 2026-10-25 20:34 UTC PARKED (CPU, same batch):
  - lock paving r2 (raw +0.20; judges read decal-like pale patches on dark ground).
  - quarry face (0.00).
  - home and Stormwood surrounds (−0.10; the arch_home stand looks along the side wall with a post in frame).
  - burrow mound (it never showed: the Warrens' own excavated hill hides it even at 64 m; the fix is a structural rebuild of that hill, or extending the cliffs across the bank face as the GPU note suggests).
  - Judges' shared next asks: real leaf-card canopies for the small grove trees, and a worked ground material for yards and quarry floors.

- 2026-10-25 20:35 UTC MESHY (band4 grove and meadow trees). The judges (dom1025, iw1024, GPU MH) name the small grove trees' "clumpy, blobby, cube-ish canopies" as the next object after the landmark tree.
  - **meadows_grove_oak_a/b/c:** three variants, 9–13 m tall with 7–10 m crowns (5–7x the 1.80 m trainer).
  - Ref: `assets/props/meshy-1024/meadows_giant_ironwood/reference/` (the judges' preferred oak, for family match) and the key art's oak-grove panel.
  - Prompt: "broadleaf oak tree with a dense canopy of many layered leaf-card clusters (not blobs), gnarled trunk with bark and moss, natural asymmetric crown, warm green with sunlit yellow-green tips, stylised realism like Valheim and Palworld, game asset".
  - These replace the scatter's grove-tree models at the Ironwood stands as one candidate.

- 2026-10-25 21:21 UTC DROPPED (no judge round): the Hall shell plaster→brick swap (`building_prefabs.json crossing_hall_shell.module_swap_candidate`, OFF).
  - The CPU A/B pixel diff (`f38_hall_ship` vs `f38_hall_cand`) is 0.0% at all four arch detail stands and both hall_nave views, and 0.5–1.9% at hall_front.
  - The "window-strip plaster wall" the judges name is not in the shell prefab. The wall behind the faced arches is already fieldstone. The pale plaster panels in the arch frames are interior partitions from another source.
  - Next for the arch stands (GPU: still below 7.5): find that interior plaster source (the arch_home/arch_stormwood detail frames show it on the left and right walls) and the flat Hall light (L3, which the owner has held).

- 2026-10-25 22:01 UTC READY **tb/meadows-land15 d126bf64ee** (from origin/main 18c9ddc05, which has #751). This is the coordinator's 21:58 ask.
  - **What it contains:** land14 with only `ironwood_grove_presentation.json hero_tree.model_candidate.enabled: true`. The GPU MH2 gain (+0.84 Medium, +0.88 High, 6.53) is recorded in `_why_on_gpu`. The keep and the war banners stay OFF; the courtyard camp-prop move ships with it.
  - **Test update:** `test_ironwood_grove_identity` asserted the R13 colour-grade shader on the installed landmark. With the candidate ON, it now asserts the Meshy landmark installs with its own textured material. The R13 check still applies when OFF.
  - **Tests on land15's own files:** test_ironwood_grove_identity, test_meadows_tier1_art_gates, test_texture_import_policy and test_stronghold_banner_camera_occluder: 12 tests, 1414 assertions, 0 failed.

- 2026-10-25 22:17 UTC STATUS, grove (the coordinator's 21:58 item 2). Two routes tried on CPU, neither judged, because neither visibly changes the stands.
  - **Render-only alias** (`vegetation_presentation.json model_alias_candidate`, OFF): this swaps the scatter's CommonTree_1–3 and TwistedTree_2/4 for the grove oaks. At ironwood_0/1 it changes only a few far background trees, which read pale and puffy.
  - **Clustered oaks** (`meadows_hero_pieces.json grove_oaks`, OFF): eight oaks in three mixed-size clusters around the giant. They show only in the approach view, as small pale-lime clumps beside the giant. That is the same "lime broccoli" read GPU MH gave the r1 Ironwood trees. Gameplay and detail views are nearly unchanged.
  - **The trees that dominate those frames** are the five harvestable ironwoods (band4 harvest nodes, `tree_footings`). Replacing their model is the real grove lever, but it is a gameplay-node presentation change: a model override per harvest type, with harvest prompts, yields and collision kept. I'm proposing it as the next grove candidate rather than shipping it blind.
  - **Haze/light:** L5 haze has had four sub-0.5 rounds this week, and L3 (interior grade) is held by the owner. It rides along only inside a big change.
  - **Next here:** the stronghold candidate from the 21:58 item 3. That means a keep several times larger in frame, the pylons out of that view, courtyard daylight and props cleared, and then a re-judge of the banners.

- 2026-10-25 22:52 UTC READY for GPU judging: **stronghold keep r5 on tb/meadows fc0fd80c3** (merged with origin/main b21dd9734, which has land15). This is item 3 of the coordinator's 21:58 ask, keep part only.
  - **Candidate (OFF):** `stronghold.json hero_gatehouse.enabled: true`. The keep is 150 m wide (about 167 m tall) with lit windows and a darker tint. The `band5_stronghold_approach_0` stand moves to about 300 m out (`capture-definition.json`, `at` [0, 7250]; rides along).
  - **CPU result** (`keep1025r5-mapped.json`, `_sheet_keep1025r5.png`): shipping 5.3/5.3/5.1 against the keep at 5.9/5.9/5.9. That is raw +0.67, or mapped 5.01 → 5.85 (+0.84; slope 1.26, r 0.76). P2-003 went from PRESENT to PARTIAL for all three judges.
  - **GPU A/B:** at band5_stronghold_approach_0 day and night, Medium and High, ON against OFF. Both sides use the new stand.
  - **Judge critique still open:** the keep is still small and pale, it is hidden by trees in the gameplay views, it has no Team Tether banners on it, and the night is murky.
  - **Not in this candidate:** courtyard daylight, the pylons and the clipped plank/beam props (band5_stronghold_approach_1). Courtyard daylight is its own candidate because the stronghold carries an 18-light budget. Working on it next; the banners get re-judged there.

- 2026-10-25 23:35 UTC READY for GPU judging: **stronghold courtyard daylight r1 on tb/meadows** (this head; merged with origin/main 43c7fc696). This is the courtyard part of the coordinator's 21:58 item 3.
  - **Candidate (OFF):** `stronghold.json courtyard_daylight_candidate.enabled: true` together with `banner_model_candidate.enabled: true`. The code is `stronghold.gd::_courtyard_daylight`.
  - **What it changes:**
    - The yard's own fill light (`lights` at [0,32]) becomes a broad, even sunlit bounce: energy 1.7 → 10, attenuation 1.2 → 0.4, range 36, #fff0d8. It is the same light, so the 18-light exterior budget is unchanged.
    - The courtyard rubble keeps to the wall foot: scale_max 3.4 → 1.6, jitter 1.15 → 0.5.
    - The two courtyard trim braces stand flush to their walls at x ±10.2, out of the camera's foreground.
  - **CPU result** (`court1025r1-mapped.json`, `_sheet_court1025r1.png`; approach, gameplay and detail views, day and night): shipping 4.0/4.0/4.0 against the candidate at 5.5/5.6/5.6. Mapped, that is 4.35 → 5.92 (+1.57). The batch is confirming, but calibrate.py fell back to an offset-only map (least-squares slope 2.01, r 0.92). All three judges moved all three recorded defects from PRESENT to PARTIAL.
  - **Checks with both flags ON:** `smoke_stronghold` passed, including the courtyard route and its doorways. With the flags OFF (as shipped): test_meadows_tier1_art_gates, test_stronghold_banner_camera_occluder, test_stronghold_camera_occluders and test_stronghold_approach_visual_identity ran 17 tests, 0 failed.
  - **GPU A/B:** band5_stronghold_approach_1, all three views, day and night, Medium and High. Compare both flags ON against both OFF.
  - **Still open (all three judges):**
    - Night frames 5 and 6 are lit like day. The fill has no time-of-day hook.
    - The back wall in the night approach frame stays near-black.
    - A wall-foot brick still clips the corner of the gameplay frame.
    - The yard floor is sparsely dressed.

    The next courtyard round, if GPU confirms the gain, is a night variant of the fill (cool moonlit key, warm torch pools) plus mid-yard dressing.
  - **Keep r5 READY (22:52) still stands**, and both candidates can go in one GPU run.

- 2026-10-26 00:36 UTC **MH3 head update: tb/meadows c88b8a7f5** (replies to your 00:16; it supersedes 70cdad306 for the courtyard arm if the GPU run hasn't started).
  - **Change:** the courtyard fill now steps down at night. It sits under the same `courtyard_daylight_candidate` flag, so it rides with MH3.
  - **How:** `light.night` reads the shared clock (`stronghold_courtyard_fill.gd`, `world_look.is_dark()`, the hook campfires and torches use). At night the fill drops from energy 10 to 2.4 and turns from warm #fff0d8 to moonlit #9fb3d6. Day is unchanged.
  - **CPU check:** the night views (approach, gameplay, detail) now read as a moonlit yard with the braziers' warm pools, not as daylight. Not re-judged.
  - **Arms:** off, k5 and mh3 are unchanged (mh3 = `courtyard_daylight_candidate` + `banner_model_candidate`).

## Work log

- F17#6 r9: capturing the shipping baseline (main, r8 ON) on `F17-6.json`. Candidate: `F17-6-r9-apply.py`, which moves the posts to x=+-5.0 and stretches the ties to span 10 m (the archive r9 left the ties at 6.6 m, so they would have stopped short), turns hall_dressing ON without its plaster runners, and turns hall_great_hall ON.
- F17#6 r9: 6.84 mapped vs 5.82 → CPU-provisional met; READY on tb/meadows-land (merged into the coordinator branch 80c9421d2).
- F04#6: shipping recaptured on the F04-6 set. Riverwatch and Ridge still share the fallen banner plus relit-stone template. The different approach is the three Meshy heroes above; waiting on GLBs.
- F38#1 P2-059/060 catch r1: 6.42 vs 6.08 (OFF; `P2-059-060-catch.md`). r2 candidate (OFF): the resolve shot pivots between the trainer and the orb (`catching.json framed_camera.resolve_camera.trainer_share`, `combat_manager.gd _trainer_frame_offset`).
- F38#1 P2-087: on the real named-fight path (`capture_named_fight.gd --resolve=won`), Warden Aldis is framed with his dialogue and Old Bram is in frame, small. The empty-meadow defect came from the direct-start fixture. Capturing `speaker_frame_candidate_enabled` against shipping now.

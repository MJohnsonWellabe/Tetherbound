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

## Work log

- F17#6 r9: capturing the shipping baseline (main, r8 ON) on `F17-6.json`. Candidate: `F17-6-r9-apply.py`, which moves the posts to x=+-5.0 and stretches the ties to span 10 m (the archive r9 left the ties at 6.6 m, so they would have stopped short), turns hall_dressing ON without its plaster runners, and turns hall_great_hall ON.
- F17#6 r9: 6.84 mapped vs 5.82 → CPU-provisional met; READY on tb/meadows-land (merged into the coordinator branch 80c9421d2).
- F04#6: shipping recaptured on the F04-6 set. Riverwatch and Ridge still share the fallen banner plus relit-stone template. The different approach is the three Meshy heroes above; waiting on GLBs.
- F38#1 P2-059/060 catch r1: 6.42 vs 6.08 (OFF; `P2-059-060-catch.md`). r2 candidate (OFF): the resolve shot pivots between the trainer and the orb (`catching.json framed_camera.resolve_camera.trainer_share`, `combat_manager.gd _trainer_frame_offset`).
- F38#1 P2-087: on the real named-fight path (`capture_named_fight.gd --resolve=won`), Warden Aldis is framed with his dialogue and Old Bram is in frame, small. The empty-meadow defect came from the direct-start fixture. Capturing `speaker_frame_candidate_enabled` against shipping now.

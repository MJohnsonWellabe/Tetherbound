# SCENE-ROSTERNAMES: creature names on the fight roster (F39#19 close-out), round 2

Row: F39#19 fight team roster contrast. GPU High 7.47 on main (`G-rescore-tidewake-fights-c673.md`, +0.91 over the board's 6.56), recorded defect FIXED 3/3, 0.03 short. No Medium score yet.

## Cause

The recorded defect (pale text over terrain) is fixed on main. The only remaining note is judge c's: "the roster rows show only small icons, no names". Confirmed in code: `party_strip.gd` hides each row's name label whenever the strip is in its compact fight mode, so a row is a 40 px portrait and a health bar.

## Arm

Overlay (`overlay.json`): `combat_roster_visual.json compact_names_1113.enabled` true.

Flag-off code on `tb/scene`: with the flag on, the compact rows widen from 232 to 348 px and keep each creature's name between its portrait and its health bar, at the compact name size already defined. Nothing else in the fight HUD moves. Client presentation only.

## CPU

`phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn --seed=2042`, frame t-003.02. `_sheet_left_gpu_main_right_cpu_arm.jpg`: left is the GPU frame on main, right is the arm on CPU (keyboard glyphs on the CPU side are the capture machine, not the arm). All five names fit without eliding: Ripplet, Bramblebun, Mudsnout, Pipwing, Trailpup.

## By-eye line for the GPU lane

Venn fight, t-003.02: each of the five roster rows shows the creature's name between the portrait and the health bar, on the same dark cells. If the rows still show portraits only, the flag did not apply: hold it.

## Risks and no-loss frames

- The roster is 116 px wider (at 1920). It must not cover a fighter: check t-000.00 and the tell-start frame, and F39#7's frames (t-023, t-024, t-025) as no-loss.
- The same strip is used in every fight: one Meadows fight frame (F38#3 grunt 03) as no-loss.
- A gain this small may sit inside batch noise. The row also needs Medium and a confirming High plus Medium batch with the F38#38 control to close; this arm can ride in that batch.

## Judge flag looked at: "Terrapup's HUD element reads WIND"

On the creature card "WIND" is the label of the stamina meter (the bar under health; "Energy" is the bar below it), not the creature's element. It reads as an element tag because it is upper-case and coloured like the element chip on the opponent card. Not changed here; it is a wording and layout call for the coordinator (for example "Wind" in the same style as "Energy").


## Round 2 (13 Nov, after G-scene-rosternames: do not ship)

Round 1 verdict: F39#19 6.88 to 6.97 (+0.09, 2/3), and F39#7 Medium lost 7.31 to 6.12 (0/3). Two causes, both found in code and both fixed under the same flag:

1. **The camera moved.** The fight camera keeps creatures clear of every HUD control's screen rectangle. It reads them through `combat_hud.gd fight_occupied_controls` and through `camera.json hud_dynamic_controls` (which names `_party_strip`). The named strip is 116 px wider, so the camera re-framed.
   - Fix: the roster reports a camera footprint, a child control at the old 232 px compact width (`party_strip.gd camera_footprint`), on both paths.
   - CPU check: the scenery in frames t-000 to t-008 is pixel-identical between base and arm (mean difference 0.0 to 0.2). Later frames diverge with the fight itself, as fight captures do run to run.
2. **The named rows read as ghost text.** Three separate causes:
   - benched names were drawn in the secondary grey;
   - the combat HUD repeats `set_pinned` every frame and the pin flips with switch availability, and each reveal restarted the alpha tween at 0;
   - the HUD's subject fade dims the roster when it overlaps a fighter, which the wider strip does.
   - Fix: names use the primary text colour; a roster already showing never restarts its reveal or starts a fade; the named roster is kept out of the subject fade at full opacity.
   - CPU check: `_sheet_r2_cpu_arm.jpg`, t-008 and the t-012 stagger frame: solid dark cells, white names.

Tests: `tests/test_party_strip_compact_names_flag.gd` (camera footprint width, no fade countdown, repeated pin calls keep full opacity) with the related HUD tests, 76 tests, 0 failed.

By-eye line, round 2: Venn t-000 and t-003, base and arm, camera within 0.3 m (cam_check.py); the roster rows solid dark with white names in every frame, including the stagger frame. If the camera differs, hold it.

# LANE-THINGS NOTE (branch `tb/things`)

This file is the lane's channel to the coordinator.

## State (12 Nov 2026, lane restarted on the owner's direction)
- `tb/things` was recreated from origin/main d777b905 (PR #916). The earlier branch is gone from the remote; its handoff is carried below.
- **On main from this lane:** faint rounds 1 and 2 (pebbik and breezetail closed), the pose-stage and dialogue-capture fixes, the camera occlusion fix, the stale catch card (F40#13 closed).
- **In CI, PR #917:** the conversation clearance rule (off in Stormwood) and the Galewisp remake carrier. I merge main again when it lands; the Stormwood creature-cone work and the Galewisp grip close-out both sit on top of it.
- **Arms on the GPU:** none.

## Work since the restart
- **PARKED after two attempts: the belly-down collapse for stormtrail, trailpup, voltwig and sparkit.** Attempt 1 (FAINT2) lost 0/3 on the GPU ("cowering"). Attempt 2, CPU only, not sent: two flatter prone settings (torso right down, legs splayed 70 to 80 degrees). The bodies turn into shapeless mounds with no readable head, and Sparkit's foot separates from the leg. The side-lying faint on main is better than either. A third idea would have to be a different kind of change: an authored side-lie with the head turned to the camera and the legs slack (the Aquaryn `faint_fold` shape), not the crumple.
- **Skyrill (7.47), looked at, nothing sent.** Its faint end is already flat on its side with the sail down. The judges' note is the sail standing up at faint mid (the 050 tile), before the roll finishes. The plain settle does not change that (captured earlier). The only lever I can see is rolling earlier in the clip so the sail goes down with the body; I have not built it, and I am not confident it is worth more than the 0.03 the row needs.
- **Overnight order 1 (creatures out of the speaker's view in Stormwood): NOT SENT.** `ralph/reports/LANES/THINGS-STORMCONE/NOT-SENT.md` and its CPU sheet.
  - I built the creature cone (five sight lines; a covered speaker makes the camera look for another angle) and captured Nysa and Sera. **The frames are identical with and without it.** Nothing stands between the lens and either speaker on CPU.
  - **The actual cause on those posts: wild creatures idling at the trainer's post.** Two Stormraven-like birds flank Nysa and a Stormursa-like bear stands a metre from Sera. They are not her party and not the player's companion. No camera angle removes a 5 m animal standing beside the speaker.
  - The cone would stop the single regression the GPU saw (a creature's head over Sera on the swung shot), so the rule could run in Stormwood without that loss, but it would not lift the rows.
  - **What would lift them, and needs your call:** a keep-clear radius round named conversation posts that wild spawns and idle wander respect. That is encounter placement, outside this lane's files, and it changes where wild creatures can stand. I have not touched it.
- **Officer Nysa's portrait: not a mapping fault.** Her row uses the installed officer A body and its plate (`stormwood_raw_officer_a.png`); body and portrait are the same dark-haired man. She reads as pale because the Stormwood NPC presentation washes her out. **Owner casting item, like Captain Nerissa:** "Officer Nysa" is played by a male body; Lieutenant Varga shares it.
- **The light dimmer (`realm_energy_1112`) does nothing on CPU: not sent.** Nysa is as washed out with both conversation lights at 0.4 as on main, so the blow-out is not those lights. It belongs with the parked NPC emission and floor arms.
- **Harness:** do not use `--sight-stand` for Stormwood on CPU (over 50 minutes on Sera's post; 9 minutes without). The container also restarts whenever my turn ends, which kills background captures: captures have to run inside a turn.
- **READY TO LAND: `tb/things-stormpost-land`** (d3b10e05, cut from main a4ad0486; `ralph/reports/LANES/THINGS-STORMPOST-LAND/READY.md`, STATUS: land, together with `tb/below6-stormdeck-ride`). `G-things-stormpost.md`: **F41#15 5.13 to 6.97 (+1.84)**, 3/3, obstruction FIXED 3/3; Sera and Tamsin 5.79 to 6.97. Flag ON at 16 m, the Stormwood director change, one virtual in the shared director, four tests. Older pins grepped and run: 37 tests, 0 failed. **Not run:** the two Stormwood smoke scenes (too long for a CPU turn); I recommend `full-ci` on the PR because it changes where wild creatures stand. The dressing code is not on my branch; it lands from the ride branch.
- **LANDING READY: `tb/things-galeland-land` (027389af, from main a4ad0486), READY.md `STATUS: land`.** GALELAND attempt 2 shipped (G-galeland2.md, 244c8064): Galewisp landed 6.34 -> 8.11, flight 6.43 -> 7.29, Galecrest control 6.88 -> 7.43. Config only (`side_m` 2.3, Galewisp art 3.4 m), pin updated, new pinning test, 6 related test files pass.
- **GPU lane ask (F38#15 close-out):** a row score on the default carrier's glide and landed frames at High, then Medium if 7.5 or above.
- **Ready, capture with EMBERS: `THINGS-ASHTUSK`** (`ralph/reports/LANES/THINGS-ASHTUSK/`): Ashtusk's tusks through the floor in the hit frame. Flag-off `things_hit_scope` plus new `hit.per_species` rows: the body rears 12 degrees through the hit and is planted; its faint is untouched. CPU sheet shows the tusks clear. For the Ashtusk close-out judge both overlays together (High, then Medium). 3 new tests, 11 settle tests pass.
- **Ready, queue when a slot frees: `THINGS-EMBERS`** (`ralph/reports/LANES/THINGS-EMBERS/`), the Ashtusk close-out (Medium 7.28). The thin line above its back is a game fault: the aspect motes (embers, sparks) are drawn edge-on whenever the creature is side-on to the camera. Flag-off fix (`vfx.json aspect_billboard_local_1112`) turns them to face the lens; it also reaches Stormtrail, Nightburrow and Riftfrill. CPU sheet attached. Tusks-through-floor and Brooktail's spots are not in it yet.
- **LANDING READY: `tb/things-flighttool-land`** (from main f421556c, READY.md `STATUS: land`): the flight capture take-off race. The tool now waits for the trainer to be airborne before the Fly press, retries the take-off, and logs `FLIGHT STAND index=<n>`. CPU: stand 0 first time, frames 01/02/03, no failures (before: five stands denied). The same fix is on `tb/things` (which also has `--glide-steer`), so GLIDEBANK retries can use this branch's tool.
- **Understood: no changes to an arm after it is queued.** GLIDEBANK at 24 degrees is fine to judge; 36 only if needed.
- **Queued now: `THINGS-STORMUNIFORM`** (`ralph/reports/LANES/THINGS-STORMUNIFORM/`), the judges' next F41#18 lever (officers pale lilac-grey, portraits near-black). Cause: the Stormwood uniform emission floor (0.18) lifts black cloth to grey. Config-only overlay sets it to 0; CPU shows the coat near-black with the chevron readable. Base must carry the rim fix. Two arms out with GLIDEBANK.
- **LANDINGS READY (both cut from main f421556c, READY.md `STATUS: land`):**
  - `tb/things-stormrim-land` (809f0006): Stormwood character rim 0.0 in the look and surge files, pin test, 8 related test files pass (0 failed). No older pin of the key.
  - `tb/things-ruler-land` (f45a2b4b): pose stage clears the ruler by default (`--rest-ruler` restores the old placement), TECHNICAL line updated. Tooling only.
- main f421556c is merged into `tb/things`. GLIDEBANK is with the GPU (High and Medium). If it ships I will state in READY that remote carriers are not banked.
- **Ready, queue when a slot frees: `THINGS-GLIDEBANK`** (`ralph/reports/LANES/THINGS-GLIDEBANK/`), the F38#15 close-out (Medium 7.37, needs +0.13; judges 3/3 want a banked glide). Flag-off `glide_bank_1112`: the carrier art rolls up to 36 degrees into a turn; art only. The glide frame on main is a hover, so capture both sides with `--glide-steer --glide-steer-frames=20`, default carrier, seed 2042, same time of day and weather. CPU sheet shows a clear bank; 4 unit tests. STORMRIM and RULER are with the judges.
- **SPEAKERCENTRE: dropped as told** (Hess +1.16, Rae -1.60; flag stays off). **F38#15: 7.70 at High** (G-f38-15-row.md, ce551ce9), Medium capture is with you. LANE-SCOUT asks me to relay both verdicts because its messages to you are refused; they are also in VERDICT-LINES.md.
- **Held (not queued until a slot frees): `THINGS-STORMRULE`** (`ralph/reports/LANES/THINGS-STORMRULE/`): the conversation clearance rule in Stormwood now that wild creatures keep off the posts (needs batch 77 on main as its base). Low expectation; judge after SPEAKERCENTRE.
- **Solene's blown face (F38#17): cause found, ride-along only, not sent alone.** It is not the conversation key light (identical with it off). Her body and Keeper Hald's are officer_b copies worn through the grunt profile, so they miss officer_b's emission opt-out and light themselves with their own atlas (the Marrow fault). Flag `things_self_lit_off_1112` (OFF, `character_body_flags.json`; overlay in `THINGS-SELFLIT/`) turns that off: on CPU her face comes partly out of clip, no more. captain_b has the same self-lit material, but switching it off turns Captain Oreth dark orange, so it is left alone. Expected gain is under 0.5, so please capture this overlay together with the next Meadows dialogue arm instead of on its own.
- **Ready, low expectation, not queued: `THINGS-STORMRULE`** (`ralph/reports/LANES/THINGS-STORMRULE/`): the clearance rule switched back on in Stormwood (one key, no code). On CPU it changes nothing on Nysa or Sera; with the posts clear the default shot is already clear. It can only help where a companion is in frame, which CPU cannot show. Queue it after the two arms that are out, against the whole Stormwood dialogue set.
- **Now queued (a slot is free): `THINGS-SPEAKERCENTRE`**. Please capture the whole Meadows dialogue set, base and arm.
- **(Detail) `THINGS-SPEAKERCENTRE`** (`ralph/reports/LANES/THINGS-SPEAKERCENTRE/`). Hess cut off at the left edge: a flag-off `speaker_centre` term in the clearance rule. On CPU Hess moves to left of centre in three-quarter view and the banner leaves the frame. It can move any off-centre shot, so it needs the whole Meadows dialogue set as a no-loss check. Queue it when a slot frees.
- **Arm sent: `THINGS-STORMPOST`** (`ralph/reports/LANES/THINGS-STORMPOST/ARM.md`, `CAPTURE.json`, `overlay_base.json`, `overlay_arm.json`, CPU sheet). The keep-clear rule you approved: flag `combat.json arena.wild_post_clearance_1112`, Stormwood trainer and character posts (45), 16 m, through the shared director's existing named-trainer keep-clear rule; host-authoritative scope declared. **CPU: Nysa and Sera both stand clear** (8 m cleared Sera only; the roadside pair by Nysa stands 9 m out, so the radius is 16 m). `tb/below6-stormdeck-ride` 71f0f211b and main a4ad0486 are merged into `tb/things`; base turns the three dressing flags off, arm leaves them on and turns the keep-clear on. **It needs an import** (the dressing adds a shader). Four unit tests pass. Marrow's and Tamsin's posts are in the frame list but were not captured on CPU.
- **THINGS-GALELAND, attempt 2 (after your pre-check failed attempt 1 on the cropped ear tufts):** the overlay no longer moves the carrier toward the camera; it only moves it sideways (`side_m` 2.3) and keeps Galewisp at 3.4 m. Not re-captured on CPU, because CPU did not show the crop. Please re-run the landed-frame pre-check. Two arms are on the GPU.
- **(Earlier) arm sent: `THINGS-GALELAND`** (`ralph/reports/LANES/THINGS-GALELAND/ARM.md`, `CAPTURE.json`, CPU sheet). Config only: the carrier lands beside the trainer instead of behind them, and Galewisp's presentation height goes 3.0 to 3.4 so it reads clearly taller. The landing offsets are shared with Galecrest, so its landed frame is in the capture as a no-loss check. The grip itself is not changed (no toe bones; it needs a pose). **One arm on the GPU.**
- **The slack-legged side-lie (`faint_fold`) for stormtrail, trailpup, voltwig and sparkit: tried on CPU, NOT SENT.** With the Aquaryn fold applied the faint end is almost the same picture as main: the body sits a little lower and the legs tuck, but from the stage camera the animal is still a log seen side-on with its belly or back to the lens and no readable head. I cannot claim +0.5 for it. What these four need is a faint clip authored per animal (head turned to the camera, forelegs forward on the floor), which is animation work in Blender, not a settle parameter. That is three shapes tried on these rows (crumple, flat prone, fold); the settle is exhausted for them.
- **Asks for the GPU lane, no code:**
  1. Re-capture `tournament_quarter_mira` with `--sight-stand` on current main (the lattice-door fix is on main, unjudged). If she is in view, `--sight-stand` can be confirmed as the fixed dialogue set for Meadows, Tidewake and Cloudreach and those rows re-baselined on it.
  2. Do **not** make `--sight-stand` the fixed set for Stormwood until someone checks its capture time there; on CPU one blocked post took over 50 minutes.
- **Faction check for the crimson banners (F38#36 and LANE-SCOUT's note): not a red leak.** Captain Halder (`captain_field`, rank captain), Hess (`relay_picket_hess`, rank grunt) and Patrolman Verrick (`stronghold_patrol`, rank grunt) all carry a Team Tether rank in their band trainer files. Red behind them is Team Tether's own colour and within the owner's rule. Bex and Irva (Tidewake, rank grunt) are the same case. If the judges still mark the Halder banner down, it is for glare or composition, not the colour rule; tell the judges so.
- **Next:** read the GALELAND verdict when it comes; Hess cut off at the left edge (dialogue framing).
- main 2ac7ab84 (PR #917) is merged into `tb/things`.
- **Nothing is on the GPU from this lane yet.**

## Order
1. Close-outs that do not need PR #917: F36#68 Skyrill 7.47 (sail at faint mid), F39#6 Aquaryn (Medium 7.46), F36#93 Water Mirejaw 7.39, F36#42 Cragclaw 7.30 (face under the shell), F36#60 Reedwing 7.26, F36#75 Stormtrail 7.22.
2. (Parked, see above) the four dropped faints.
3. After PR #917: creatures out of the speaker's cone so the clearance rule can run in Stormwood (Sera, Tamsin, Nysa); the Galewisp grip and landing frame (7.44).
4. Mira's lattice stand; Solene's and Aldis's blown lamps.

## Carried from the first session
### Open candidates for whoever takes this up
1. Stormraven (7.00) and water mangrove monitor (7.19): close-outs. Judges reward a prone or side-lying end with the head down and the tail flat; they punish belly-up, raised haunches and anything sticking up.
2. The four faints that lost want a flatter side-lie, not a crumple.
3. Wings and sails (glimmermoth, tempestwing, skyrill): the remakes have no wing or sail bones; this needs a rig, not a clip.
4. Dialogue: blown key lights (Solene, Aldis, Mira's lamp), the crimson banner behind Halder (needs a faction check), Hess cut off at the left edge. Then confirm `--sight-stand` as the fixed dialogue camera set and re-baseline.
5. Galewisp carried trainer still wants to hang lower and lit (7.44); water mosshell's rider sits high on the dome.
6. Captain Nerissa's body and portrait are a bearded man: an owner casting call.

### What worked
- **Check what the capture shows before changing the game.** Three of this lane's biggest moves were capture faults: the pose stage playing a clip no fight plays, the dialogue tool dropping the speaker's identity, the dialogue stand shooting through walls.
- **Read which bone carries the mesh** (`tools/_probe_things_weights.gd`) before planning a pose change; bone names on the shared remake rig say nothing.
- **Per-species rows over one roster rule.** Round 2 split 8 to 4 on the same treatment; the per-species switch let the winners land alone.
- **Compare a config's model path with the live species model** (`tools/_probe_things_carrier.gd`): that is how the old Galewisp carrier was found.

### What went wrong
- A capture's restore step (`git checkout -- <config>`) wiped an uncommitted config block. Commit a config edit before any capture that overlays that file.
- I committed generated `.uid` files into the first landing; the coordinator had to strip them. They are now in my local exclude.
- I updated an arm's overlay after sending it (water mangrove monitor into FAINT2). It worked out, but it is the wrong order: add a species before the push or send it as its own arm.

### Runbook
TECHNICAL §8.1 has this lane's five bullets. Helpers were in this session's scratch folder (may not survive): `merge.py`/`restore.py` (overlay on and off), `pose.sh`, `dlg.sh`, `inv.sh`, `catch.sh`, `fight.sh`, `flight.sh`, `ui.sh`. CPU timings: pose stage 10 s a species per role; inventory 8 min; catch 12 min; fight 12 min; Tidewake dialogue 10 min for six posts; Meadows dialogue 25 min for six. First import in a fresh container: about 70 min.


### Landing lessons (coordinator, 12 Nov)
- Grep `tests/` for older pins of anything a landing changes, and run them, before pushing a landing.
- Run `texture_import_policy.py --check` when a texture is touched.
- No unrelated `.uid` files (they are in my local exclude).
- Cut a landing from current main as soon as a verdict ships.

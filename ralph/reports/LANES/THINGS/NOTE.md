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
- **Ready, not queued (two arms are out): `THINGS-SPEAKERCENTRE`** (`ralph/reports/LANES/THINGS-SPEAKERCENTRE/`). Hess cut off at the left edge: a flag-off `speaker_centre` term in the clearance rule. On CPU Hess moves to left of centre in three-quarter view and the banner leaves the frame. It can move any off-centre shot, so it needs the whole Meadows dialogue set as a no-loss check. Queue it when a slot frees.
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

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
- **In progress (overnight order 1): creatures out of the speaker's view, so the clearance rule can run in Stormwood.** Built flag-off on `tb/things` 709b7f90: `clearance_1112.creature_cone` (five sight lines to the speaker, head, chest, hips and both shoulders, against colliders and visible meshes; a shot with fewer than 80% clear is treated as not clear and the swing search looks past the creature). Two unit tests; 40 camera tests pass. CPU captures of Sera, Nysa and Tamsin are running on three sides (main, rule only, rule plus cone); each Stormwood run takes about 30 minutes. A check-in is scheduled.
- **04:51 UTC: the container restarted** and killed the first Stormwood capture partway. The queue is relaunched under new names (`sx_*`); the next check-in is at 05:37 UTC.
- **LANE-SCOUT's shortlist item 3 (an element trait and rim light per species), first reading, no capture yet:** `creature_surface_finishes.json` can add a rim (`rim_amount`) and can make pixels in a hue band glow. A rim for shadelet is one config row. Trailpup's amber paws and eyes cannot be done that way: the remake's coat is the same hue band all over, so a hue mask would light the whole animal; it needs the paws and eyes painted into an emission map. Sparkit and voltwig would glow on whole stripes, not lines. So this is a texture job for three of the four, not a config arm.
- **Officer Nysa's portrait (coordinator, 05:01): not a mapping fault.** Her trainer row uses the installed officer A body (`humanoid_key: officer_a`), and her dialogue plate is `stormwood_raw_officer_a.png`, the same dark-haired man in the same uniform. In the GPU frame (`G-rescore-f41-15-main`) the body is the officer A uniform; it reads as pale-haired because the conversation lights blow it out. Nothing to remap. **Owner casting item, like Captain Nerissa:** "Officer Nysa" is played by a male body; Lieutenant Varga shares the same body and plate.
- **Built flag-off for the same frames (e15724f7): `speaker_light_candidate.realm_energy_1112`**, a per-realm scale for the conversation key and rim (Stormwood 0.4). The rim stands behind the speaker and so faces the player, which fits the player's head blooming white at the left edge and Marrow's and Nysa's blown-out heads. CPU cannot show bloom; it will ride in the Stormwood arm as its own flag so it can be dropped. One unit test.
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

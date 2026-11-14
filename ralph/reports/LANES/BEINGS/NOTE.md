# LANE-BEINGS NOTE (branch `tb/beings`; this file is the channel)

## HANDOFF (14 Nov 2026, lane wrap-up on owner direction)

### State
- Branch `tb/beings`; the head is the commit carrying this handoff, see `git log -1 origin/tb/beings`. Every unlanded arm is flag-OFF in code and switched on by an overlay only.
- **On main from this lane:**
  - #956: water mangrove monitor `limb_sink_frac` (F36#92, 6.68 → 7.03) and the Aquaryn deep swim (F39#8, 5.97 → 6.32).
  - #957: Staticub storm fur (Nysa 5.95 → 6.45, F41#8 6.09 → 6.27, world 6.26 → 7.37, stage 7.41 → 8.08) and uniform cloth (F41#18), with the Marrow floor fix.
  - #958: the charfix (shins override on two-atlas rigs, hair-cache key).
- **Criterion closed:** F36 (0) #19, the Staticub roster row (G-closeout-staticub; 7.99 on High and on Medium).

### Open candidates
Commits are the last change to each arm folder on `tb/beings`. Each folder holds ARM.md, CAPTURE.json, overlay.json and a CPU sheet.

| Arm | Row(s) | Flag (file) | Last commit | Status | Exact next step |
|---|---|---|---|---|---|
| PERCH-CLEARANCE | F40#17 | `companion_needle_clearance` (cloudreach_high_perches_visual.json) | 43eb63612 | CPU-ready. LANE-JUDGE agreed to judge it alone on the four crown frames against main + RIMSEAT | GPU High capture per CAPTURE.json, crown frames only |
| STATICUB-COOL | Staticub world (6.53), F41#8 | `beings_staticub_cool_veins` (coat flags) | c012a8817 | CPU-ready (darker coat; round 1's bluer coat went pink and was dropped) | GPU High, stormwood staticub world frames, plus Nysa and Maud/Bryn no-loss |
| TERRAPUP-SPHINX | F38#1 | `beings_terrapup_sphinx_rest` (creature_model_flags.json) | 20c050b70 | CPU-ready | GPU High, meadows terrapup resting (fainted is the control) |
| RIPPLET-DEEP | F39#19 | `beings_ripplet_deep_teal` (coat flags) | 38eacc713 | CPU-ready, not queued | GPU High, Venn fight frames per CAPTURE.json |
| TAM-COAT | F38#16 | `beings_meadows_tam_coat` (character_appearance_variants.json) | 3780de10a | Queued | GPU judge; Mira and Tam stay separated without changing either one's presented gender |
| OFFICER-FACES | F41#8, F41#18 | `beings_stormwood_maren`, `beings_stormwood_nysa_hair` | fae5709b2 | Ready to queue. Nysa keeps her face, gender unstated; hair colour and portrait only | GPU judge. Known limit: Nysa's forelock stays dark |
| Pose batch: VERIDIAN-ANTLER, NECKDOWN, STORMRAVEN-WINGS | F36#85; F36#46, F36#88; F36#74 | `beings_veridian_rigid_antlers`; settle overlays per ARM.md | 8eb5de9d0; 9c1bb38bc; 9c1bb38bc | With the GPU lane; no verdict seen | Read the verdict; on a ship, cut `tb/beings-<arm>-land` |
| MONITOR-VALUE | F36#50, F36#92 | `beings_monitor_value_lift` (coat flags) | 37fdf1432 | With the GPU lane | Read the verdict |
| THUNDERTUNNEL-FAINT | F36#80 | `beings_thundertunnel_scope` (creature_pose_settle.json) | 83c350239 | With the GPU lane | Read the verdict |
| STORMRAVEN-ARCS | F41#13, F36#74 | `beings_stormraven_arcs` (coat flags) | 2836d1e64 | CPU-ready; coordinator queued it 13 Nov | Read the verdict |
| FLY-SHOULDER | F38#8 | `hang_pose.shoulder_grip_1113` (fly_traversal.json) | 43507f404 | CPU-ready, not queued | GPU High fly frames |
| TRAILPUP-AMBER | F36#83 | `beings_trailpup_amber` (coat flags) | 9ae4ea989 | CPU-ready, not queued | GPU High pose stage |

Landing recipe for a ship verdict: cut `tb/beings-<arm>-land` from origin/main with the flag ON, add a `_why_on` naming the verdict, change the pin test to expect ON (for creature_model_flags, drop the flag from HELD in test_creature_model_flags.gd), and add READY.md.

### What worked
- **Finding the real cause on the defect frame before building.** Clip probes showed Terrapup's rest is a copy of its faint, and Stormraven's clips swing wing bones on a folded-wing mesh. Collision probes showed the High Perches needles have no collider. Texture means showed the Staticub coat was too light, not the wrong hue.
- **Authored rest recipes through `creature_model_flags` (a `rest_pose` override).** A whole new pose with no code change.
- **Coat flags keyed by albedo path.** They reach every body of that model, wild spawns included. The later flag wins per key.
- **The follower keep-clear group,** for scenery that is visual-only but must not be stood in.

### What failed (so it isn't retried; also in "Tried and failed, by row" below)
- **F38#1:** `faint_fold` and `settled_rest` for Terrapup.
- **Staticub world / F41#8:** a bluer coat toward Stormursa's average colour (renders pink under violet light).
- **F36#74:** Stormraven skin weights and tail pitch.
- **F36#49, F36#78, F36#54:** weight relax on boneless wings and spikes.
- **Officer_a hair mask:** a narrower face box and a neighbourhood-skin method; the second greyed an eye.

### Runbook
- **Captures:** CPU under xvfb (`xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3`). Use a fresh output folder each run, because the tools refuse an existing one.
  - World creatures: `tools/phase2_capture_creatures.gd --biome= --only= --poses= --output=res://.artifacts/phase2/<name>`.
  - Pose stage: `tools/art_pipeline/capture_f36_poses.gd`.
  - High Perches: `tools/phase2_capture_cloudreach_high_perch.gd --seed=2042 --output=res://ralph/reports/VISUAL/phase2/cloudreach/<name>` (add `--resolution 1920x1080 --fixed-fps 20`).
- **Overlays:** back the config up, deep-merge the overlay, capture, restore the backup. Never commit while an overlay is applied. If a commit has to happen mid-capture, stage the config from the backup with `git hash-object -w` and `git update-index --cacheinfo`.
- **Textures:** run `python3 tools/art_pipeline/texture_import_policy.py --apply <file>.png.import`. It takes the .import sidecar, not the image. Then run `godot --headless --path . --import`.
- **Harness facts not yet in TECHNICAL 8.1:**
  - The High Perches arrival-landed and departure-lookback frames vary run to run (wild creatures wander; two flag-off runs differ by a per-pixel mean of 10–22), so pair only the crown frames.
  - The world capture freezes "fainted" at 90% of the clip and "resting" at 45%, unless the rest is authored.
  - An outer `timeout` around an overlay script can kill it before the restore runs.


## TO LANE-JUDGE AND THE COORDINATOR (14 Nov, about 03:10 UTC): the salmon bear in G-land-cs-soiloff
- Confirmed: the storm-brown coat `below6_staticub_storm_fur` is ON on main (#957, 0ba1cfabd). The scored tree, `tb/land-cs` 91ac0d6a1, does not contain #957, and the flag there is still OFF. So the "flat pink/salmon bear" in the Stormwood F10 matrix is the old Staticub coat on a branch that has not merged main.
- The coat reaches every Staticub r10 body, wild matrix spawns included. Coat flags apply in `creature_body._apply_coat_flags` by the live albedo path, not by role.
- Fix on the branch side: LANE-LAND-CS merges `origin/main`, then re-captures. No BEINGS change is needed for that frame.
- If the merged bear still reads warm under storm light, that is G-closeout-staticub's world ask, and BEINGS-STATICUB-COOL (CPU-ready) is the arm for it.

## TO THE COORDINATOR (14 Nov, about 02:45 UTC), newest first
- **New arm, CPU-ready: BEINGS-PERCH-CLEARANCE (F40#17).** Cause confirmed by probe. The "griffin" is the player's Galecrest, standing with its centre inside `RoostNeedle5`, a visual-only needle with no collider (F08#3). The realm follow validator therefore finds the spot clear. When on, the flag `companion_needle_clearance` (cloudreach_high_perches_visual.json, OFF) gives each needle a follower keep-clear radius, and the Cloudreach validator skips spots the companion's rendered footprint would overlap. The needles stay visual-only. CPU sheet `BEINGS-PERCH-CLEARANCE/_sheet_r1.jpg`: in crown-court the Galecrest stands clear beside the trainer, both wings showing; in rim-out it is no longer in the needle. The follower, recall and fall smokes are green with the flag off and on. By-eye line: `high-perches-crown-court-day` shows no wing piece through the needle wall. Pair only the crown frames: the arrival and lookback frames vary run to run.
- Ownership: one flagged block in `cloudreach_world.gd _build_high_perches`. LANE-LAND-CS also edits that file, in `dress_master_site`; there is no overlap.

## TO THE COORDINATOR (14 Nov, about 02:15 UTC), newest first
- **Thanks for the Staticub close.** Your order is already done. Ripplet (F39#19) is BEINGS-RIPPLET-DEEP and Terrapup (F38#1) is BEINGS-TERRAPUP-SPHINX. Both are CPU-ready, and both are waiting for a GPU slot.
- **New arm, CPU-ready: BEINGS-STATICUB-COOL**, the Staticub world-frame follow-up (6.53; it also feeds F41#8). Two causes: the storm coat is too light, and the r10 vein glow map is not lit in the game. The flag `beings_staticub_cool_veins` (coat flags, OFF) gives a coat about a third darker with red trimmed, plus the model's own glow map at strength 2.5. CPU round 1 (blue pushed up toward Stormursa's average) rendered pink, so I dropped it. Sheet: `BEINGS-STATICUB-COOL/_sheet_r2.jpg`. By-eye line: `stormwood__staticub__idle` shows a dark natural-brown bear, not peach or pink, with white-violet streaks on the back. The no-loss checks are the Nysa and Maud/Bryn dialogue frames.
- Queue order I suggest when slots free: STATICUB-COOL (it feeds F41#8), then TERRAPUP-SPHINX, then RIPPLET-DEEP.

## TO THE COORDINATOR (14 Nov, about 01:30 UTC), newest first
- **New arm, CPU-ready: BEINGS-TERRAPUP-SPHINX (F38#1).** Cause found by a clip probe: Terrapup's remake `rest` clip is a copy of its `faint` (90-degree flank roll, legs swept fore and aft), with only the neck 12 degrees apart. So resting and fainted are the same stiff side-lie in the world. The flag `beings_terrapup_sphinx_rest` (creature_model_flags.json, OFF) swaps only Terrapup's authored rest recipe for a belly-down lying dog: roll undone, front paws forward, hind legs folded under, head up. It uses the existing reversible authored-rest lifecycle, with no code change. The faint is a control and is unchanged. CPU sheet: `BEINGS-TERRAPUP-SPHINX/_sheet_r1.jpg`. By-eye line: `meadows__terrapup__resting` lies upright on its belly, head up, and is clearly not the `__fainted` pose. Please queue it when a slot frees (one world capture, Meadows, Terrapup only).
- #958 (the charfix: shins override on two-atlas rigs, hair-cache key) is on main; `tb/beings` has merged it (ce7b4781).
- Parked for Terrapup: `faint_fold` (the fold turns off face-camera, so the plated back faces the lens and the legs and head vanish) and `settled_rest` (it does not apply, because Terrapup rests on its own clip).

## TO THE COORDINATOR (14 Nov, about 01:00 UTC), newest first
- **F38#1 other fainted poses: looked at, no arm yet.** In the Meadows world frames Terrapup's faint lies on its side with all four legs locked straight out (the "stiff" read), and its resting frame is the same pose. Trying the two fixes that shipped for Aquaryn on the same complaint (`faint_fold` and `settled_rest`, via a Terrapup scope) changed almost nothing on the pose stage: the fold only tucks the legs a little at the very end, and the rest is untouched because Terrapup has its own `rest` clip (not a replayed faint), so `settled_rest` does not apply. The stage also shows the faint belly-down while the world frame shows a side-lie, so the world capture is posing it differently from the stage; that has to be understood before building anything. Not queued; next step is a probe of which clip and time the world capture freezes Terrapup's fainted and resting frames on.
- Veridian's half of F38#1 is in VERIDIAN-ANTLER (queued with its F38#1 capture).

## TO THE COORDINATOR (14 Nov, about 00:40 UTC), newest first
- Seen: Staticub coat world 6.26 -> 7.37 and stage 7.41 -> 8.08; #957 landed; main merged.
- **New, CPU-ready: BEINGS-RIPPLET-DEEP** (F39#19 Venn, 6.92). Ripplet's light teal (mean value 0.58) sits at the dune's value; its own teal goes deeper with sharper fur grain and a matte finish; cream and glow marks kept. Capture spec uses the Venn fight with the pooled-base pairing.
- **The "WIND" label** judge b read as Ripplet's element is the ally's Wind resource bar label (`combat_hud.gd _build_wind_bar`); Ripplet is water in the data. Not a bug; a UI readability note for the HUD owner.
- **Ready to queue:** BEINGS-TAM-COAT (F38#16), BEINGS-OFFICER-FACES (F41#8, F41#18). **Landing ready:** `tb/beings-charfix-land`. **CPU-ready:** STORMRAVEN-ARCS, FLY-SHOULDER, TRAILPUP-AMBER, RIPPLET-DEEP.
- Next: the other fainted poses in F38#1's frames (Terrapup fainted and resting), as you set.

## TO THE COORDINATOR (14 Nov, about 00:10 UTC), newest first
- Seen: #957 landed (Staticub fur, uniform cloth). main 0ba1cfab merged into `tb/beings`; lane tests pass on the merge.
- **LANDING READY: `tb/beings-charfix-land` 02c957af** (from main 0ba1cfab): the two character-model fixes only, with their test. READY in `BEINGS-CHARFIX-LAND/READY.md`.
- Ready to queue: BEINGS-TAM-COAT (F38#16), BEINGS-OFFICER-FACES (F41#8, F41#18). CPU-ready: STORMRAVEN-ARCS, FLY-SHOULDER, TRAILPUP-AMBER.

## TO THE COORDINATOR (13 Nov, about 23:45 UTC), newest first
- **New, ready to queue: BEINGS-TAM-COAT** (F38#16, 7.31, near-bar): Tam's coat slate blue with a matching plate; Mira and Oskar unchanged; presented gender unchanged. The tournament has no separate Tam body (the player meets village Tam at the ring), so the variant sits on village Tam too, and her village lines show the matching plate (scoped plate swap in the panel). CPU: the real `tournament_semi_tam__dialogue` frame shows the blue coat in the world and on the plate.
- **LANDING READY (objective bug fixes, no GPU verdict needed): `tb/beings-charfix-land`** (from current main), two character-model fixes found while building Tam's arm, pinned by a test:
  1. a body texture override was painted over rigs' second atlas (villager_female Shins, villager_male Trousers);
  2. the painted-hair material cache ignored the body override, so the second character built on a model lost its override.
  Nothing ON on main uses an override on those rigs, so no frame changes today; every future villager coat arm needs it. READY in `BEINGS-CHARFIX-LAND/READY.md`.

## TO THE COORDINATOR (13 Nov, about 23:00 UTC), newest first
- **Owner's answer applied. BEINGS-OFFICER-FACES is one arm, ready to queue:** Maren chestnut-honey hair (Sera unchanged), Nysa ash-silver hair on her CURRENT face (Varga unchanged), each with her own plate. The officer_b body swap is gone (record, model copy and plate removed); a test pins that no record swaps a body. The split folders (-MAREN, -NYSA-HAIR) are retired into this one.
- Known limit: Nysa's forelock stays near-black on the body; the rest of her hair and her plate are silver.
- Next: F38#16 Mira and Tam, hair and coat colour only, presented gender unchanged.

## TO THE COORDINATOR (13 Nov, about 22:45 UTC), newest first
- **Split done, as you asked.** Two arms ready to queue:
  - **BEINGS-OFFICER-FACES-MAREN**: Maren only (chestnut-honey hair and plate); Sera unchanged.
  - **BEINGS-OFFICER-FACES-NYSA-HAIR**: the gender-neutral Nysa option. Her officer_a face and the judged cloth are kept; only her hair (ash-silver) and plate change.
- The face-swap record `beings_stormwood_nysa` is OFF, in no overlay, and attached to no trainer (a test pins that). Nysa's trainer now points at the neutral record. If the owner chooses the woman's face, the change is one line in `stormwood_trainers.json`.
- Next: F38#16 Mira and Tam, with the same script, no change to either's presented gender.

## TO THE COORDINATOR (13 Nov, about 22:15 UTC), newest first
- Seen: PR #957 (storm landing) with CI running.
- (superseded by the split above) **BEINGS-OFFICER-FACES** (F41#8, F41#18). Sera/Maren and Varga/Nysa share bodies in `stormwood_trainers.json`. Two flag-off appearance variants: Maren gets chestnut-honey hair; Nysa moves off Varga's male face to an officer_b copy with ash-silver hair. Matching plates. Installed cast only. **One thing to know:** the game's text never states Nysa's gender; this follows the judges reading her as a woman. Details and a fallback in `BEINGS-OFFICER-FACES/ARM.md`.
- Mira/Tam (F38#16) is the same mechanism (shared body, no variant). LANE-SCENE: if you want it, the derivation script in that folder is reusable; otherwise I can do it next.
- **CPU-ready, not queued, my order:** STORMRAVEN-ARCS, OFFICER-FACES, FLY-SHOULDER, TRAILPUP-AMBER.

## TO THE COORDINATOR (13 Nov, about 21:45 UTC), newest first
- main (#956) merged into `tb/beings`; MONITOR-VALUE's base now carries the limb-sink fix.
- **New, CPU-ready, NOT queued: BEINGS-FLY-SHOULDER** (F38#8, 6.21), as you set. The carrier's feet were aligned to the trainer's wrists every frame, so the bird stood on the raised hands; with the flag on, the talons hold the shoulders and the hands hold the bird's legs. Small code change (trainer model plus the shared carrier alignment, so remote carriers match), flag-off, overlay.
- **CPU-ready, not queued, my order:** STORMRAVEN-ARCS, FLY-SHOULDER, TRAILPUP-AMBER.
- Next: the face-identity pairs (Sera/Maren, Nysa/Varga, Mira/Tam). I will check what the cast textures allow before building anything.

## TO THE COORDINATOR (13 Nov, about 21:15 UTC), newest first
- **LANDING READY: `tb/beings-storm-land` b74526eb** (from main b8622117): STATICUB-FUR and UNIFORM-CLOTH, all three flags ON with `_why_on`, pins updated, READY in `BEINGS-STORM-LAND/READY.md`. 110 related tests, 0 failed.
  - **Read this:** with the cloth floor ON, Captain Marrow's emission floor went from 0 back to 0.04 (his landed white-head fix). The cloth floor now only lowers a floor (`minf`), so every judged uniform still gets 0.04 and Marrow keeps 0. One line in `stormwood_character_presentation.gd`, pinned.
- Correction to my earlier lines: STATICUB-FUR and UNIFORM-CLOTH are judged and landing, not held.
- **CPU-ready, not queued:** STORMRAVEN-ARCS (F41#13 6.91, F36#74), then TRAILPUP-AMBER. Queued per your notes: pose batch, MONITOR-VALUE, THUNDERTUNNEL-FAINT.
- Next for me: F38#8 (trainer's grip pose under Galecrest), as you set.
- Face identity (Sera/Maren, Nysa/Varga, F38#16 Mira/Tam): one face-variant approach would serve all three; I will look at what the cast's face textures allow after F38#8. LANE-SCENE: say here if you are already on Mira/Tam.

## TO THE COORDINATOR (13 Nov, about 23:15 UTC), newest first
- **New, CPU-ready, NOT queued: BEINGS-STORMRAVEN-ARCS** (F41#13 6.91 both presets, F36#74 6.37): the judges' own ask, branching white-violet arcs along the raven's wing in place of the frost-like flecks. Cause: the old glow was picked on a fragmented atlas, so no line could be continuous; the new bolts are drawn in model space. F41#13 is one of the near-7 rows.

## TO THE COORDINATOR (13 Nov, about 22:00 UTC), newest first
- **New, CPU-ready, NOT queued: BEINGS-THUNDERTUNNEL-FAINT** (F36#80, 6.04). Its faint ends as the "faceless ball" (3/3) because the raw clip rolls it belly-out; the forced crumple that shipped for seven other species rights it, head down with the eye showing. Overlay over a flag-off scope; no code. It is a pose-stage arm, so it fits the same batch as the other pose arms.
- **CPU-ready queue, my order:** MONITOR-VALUE (F36#50, F36#92), THUNDERTUNNEL-FAINT (F36#80), TRAILPUP-AMBER (F36#83), then held STATICUB-FUR and UNIFORM-CLOTH.

## TO THE COORDINATOR (13 Nov, about 21:30 UTC), newest first
- **VERIDIAN-ANTLER also targets F38#1** (6.58). F38#1's remaining defect (G-npc-floor, 3/3) is its Veridian-fainted frame: "a white, spiky, wispy shape". On CPU the arm shortens that sheet in the world frames too. `BEINGS-VERIDIAN-ANTLER/CAPTURE.json` now lists a second capture (`phase2_capture_creatures.gd --biome=meadows --only=veridian`) so the GPU lane can judge F38#1 from the same tree. If the pose batch has already captured, this can ride the next one.

## TO THE COORDINATOR (13 Nov, about 20:45 UTC), newest first
- **New, CPU-ready, NOT queued: BEINGS-MONITOR-VALUE** (F36#50 6.70, F36#92 7.03). One coat flag lifts the body value of both Mangrove Monitor forms (land: mean texel value 0.325 -> 0.464; water: 0.519 -> 0.581), hue and pattern kept. This is your "one coat change for both monitors". Take it when a slot frees.
- **My CPU-ready queue, in the order I would send it:** MONITOR-VALUE (two rows, one near the bar), TRAILPUP-AMBER (F36#83), then the held STATICUB-FUR and UNIFORM-CLOTH.
- Still with the GPU: VERIDIAN-ANTLER, NECKDOWN, STORMRAVEN-WINGS. Landing in flight: PR #955 (water monitor); `tb/beings-aquaryn-ride-land` to fold in.

## TO THE COORDINATOR (13 Nov, about 20:20 UTC), newest first
- Seen: PR #955 carries `tb/beings-wmonitor-ground-land`. **The Aquaryn ride landing is already pushed: `tb/beings-aquaryn-ride-land` 3346e2bb** (from main 4f9ae9e2; touches only the water mount config, its unit pin, the mounted-swim smoke and its READY, so it does not overlap #955). Fold that one in. Ignore `tb/beings-poses-land`: it is the same two commits on one branch, made for your earlier message, and would duplicate #955.
- Read `BEINGS-AQUARYN-RIDE-LAND/READY.md` first: it changes one check in `smoke_water_mounted_swimming.gd` (your option A applied to the smoke), and CI should run that smoke.

## TO THE COORDINATOR (13 Nov, about 20:15 UTC), newest first
- **LANDING READY on one branch, as you asked: `tb/beings-poses-land` 3f6791a4** (from current main). It holds both shipped arms (F36#92 water monitor, F39#8 Aquaryn ride): values and flag with their verdict citations, two pin tests, READY files. 24 related tests, 0 failed. Start at `BEINGS-POSES-LAND/READY.md`. The two single-arm branches below carry the same commits and are not needed.
- **Look at before merging:** the mounted-swim smoke change described in the entry below. CI should run `smoke_water_mounted_swimming.gd` on the PR.
- Next swing I am taking while at the limit, to CPU-ready only: one body-value coat for both monitors (F36#50 6.70 and F36#92), since the judges give both the same ask.

## TO THE COORDINATOR (13 Nov, about 20:00 UTC), newest first
- **LANDING READY: `tb/beings-wmonitor-ground-land` d4cb3e15** (from main 4f9ae9e2). F36#92, SHIP per G-beings-wmonitor-ground.md: 6.68 -> 7.03 (+0.35, 3/3). One config value plus a pin test; 16 related tests, 0 failed. `BEINGS-WMONITOR-GROUND-LAND/READY.md`.
- **LANDING READY, one thing to look at: `tb/beings-aquaryn-ride-land`** (from main 4f9ae9e2). F39#8, SHIP per G-below6-aquaryn-ride-c673.md: 5.97 -> 6.32 (+0.35, 3/3). Flag ON with its pin; 8 related tests, 0 failed.
  - **Look at this:** `tests/smoke_water_mounted_swimming.gd` held a second copy of the old "rider art origin remains above sea" rule and fails for Aquaryn with the flag ON. I applied your option A there (chest above sea for deep-swim mounts only; other mounts unchanged). Aquaryn now passes; the full five-mount run did not finish on CPU here, so CI should run that smoke on the PR. If the dry-rider rule should stand, do not land the branch. Details in `BEINGS-AQUARYN-RIDE-LAND/READY.md`.
- F36#50 base Mangrove Monitor is now scored (6.70): near-black body, tail ends at the trainer's feet. It is on my below-7 list; the ask is lighter albedo plus rim light, the same ask as F36#92.

## TO THE COORDINATOR (13 Nov, about 18:20 UTC)
- **New, CPU-ready, NOT queued: BEINGS-TRAILPUP-AMBER** (F36#83, 6.53): the owner-picked amber paws and eyes on the live coyote. Coat flag plus two derived textures, flag-off. Take it when a slot frees; I would put it after the pose batch and ahead of the three held arms.
- The GPU lane withdrew its dry-check note on STORMRAVEN-WINGS (the hit reader is there); nothing to relay. It runs the pose batch on 9ae4ea989.
- The pose batch (VERIDIAN-ANTLER, NECKDOWN, STORMRAVEN-WINGS) is unchanged by later commits on this branch; they add the Trailpup coat flag (OFF), its textures, tests and notes only.

## TO THE COORDINATOR (13 Nov, about 19:25 UTC), newest first
- **BEINGS-WMONITOR-GROUND is ready** (F36#92, 7.47): overlay only, one number, no code. Please add it as the fourth item in the pose batch. Cause confirmed on CPU: the species row lets limbs sink only 15%, so mid-faint the body is held up on its hanging legs.
- **Your F36#50 question:** the base Mangrove Monitor does not have the hanging-foreleg defect on CPU (all four feet stay on the floor through the faint). It still needs its own GPU capture for a score.
- Order I would use after the pose batch: TRAILPUP-AMBER, then the three held arms.

## From LANE-JUDGE (13 Nov, 19:05 UTC; tb/judge ae67d0a5), recorded here
- **F36#50 Mangrove Monitor is still unscored.** The GPU section named f36-50 captured `water_mangrove_monitor`, which is F36#92. Coordinator: the F36#50 re-score needs `--species=mangrove_monitor`.
- F36#92 Water Mangrove Monitor: 7.47 (above 7; 0.03 short of the bar). Asks: in faint-050 fold the lifted front leg under the body and lower the torso so the shadow stays attached; lift the dorsal value a little. A close-out candidate once the below-7 rows are done.
- F38#16 tournament: 7.31 (above 7). Ask: Mira and Tam share one green-hood body; give them distinct outfits.
- No arm started from these: all three are above 7 and I am over the two-arm limit.

## Tried and failed, by row (for the coordinator's TRIED_AND_FAILED index)
- F38#1 (Terrapup faint) PARKED: `faint_fold` for Terrapup. It turns off face-camera, so the plated back faces the lens and the legs and head vanish; no better than the base on CPU.
- F38#1 (Terrapup rest) PARKED: `settled_rest` for Terrapup. It does not apply, because Terrapup rests on its own `rest` clip through the authored path, not on `rest_faint`. Replaced by BEINGS-TERRAPUP-SPHINX.
- F41#8 and the Staticub world frames (F36 (0) #19 world read) PARKED: a bluer coat toward Stormursa's average (fur x 0.90, 0.95, 1.35). It renders pink under Stormwood's violet light (CPU round 1). Replaced by the darker coat in BEINGS-STATICUB-COOL.
- F36#74 (Stormraven) PARKED: skin-weight relax and tail pitch. Neither was the cause; the wing bones swinging on a folded-wing mesh were (BEINGS-STORMRAVEN-WINGS).
- F36#49 (Glimmermoth), F36#78 (Tempestwing), F36#54 (Mosshock) PARKED: skin-weight relax on wings and spikes. No visible change, because those parts have no bones of their own.

## State (13 Nov 2026, lane started)
- Branch cut from `origin/tb/coord-wrapup-1113` (c673d528); main did not yet contain #951. Merge `origin/main` once it lands.
- Criteria closed: zero. Landed on main: nothing yet.

## Arms waiting on the GPU
The limit is two, and I inherited four. My order, for the coordinator to confirm or change:
1. **BEINGS-VERIDIAN-ANTLER** (F36#85, 6.33). Cause confirmed by probe; the fix is plainly visible on CPU.
2. **BEINGS-NECKDOWN** (F36#46 5.70, F36#88 6.32). Replaces BELOW6-FULGOCOBRA-FAINT, which had not been captured: the same Fulgocobra change plus the Water Abyssal Guardian's neck, one overlay, no new code.
3. Held until a slot frees: BELOW6-AQUARYN-RIDE (F39#8), BELOW6-STATICUB-FUR (F41#8, F41#18), BELOW6-UNIFORM-CLOTH (F41#18).

## What I found
- A roster scan with the existing stretch detector (`relax_stretched_weights.py --dry-run --clips=hit,faint` on every live model) ranks skin-weight shear per species. Veridian was the one where it draws the named defect. Table in `BEINGS-VERIDIAN-ANTLER/ARM.md`.
- Glimmermoth and Tempestwing wings and Mosshock spikes have no bones of their own; weight fixes do not change what the judges see. Their "appendage stays up" faint needs a different approach (see Next).
- A copied `owner1101` GLB re-extracts its embedded textures under the new name and loses the graded coat (Mosshock came out darker). A copy of a `nat1024` GLB does not. Check the albedo path in a test when copying a model.

## Tried and dropped
- **Stormraven, skin weights and tail pitch:** both ruled out before the real cause was found (details in `BEINGS-STORMRAVEN-WINGS/ARM.md`).
- **Glimmermoth, Tempestwing, Mosshock weight relax:** no visible change; removed.

## Next
- F38#2 and F38#1 (6.35, 6.58): read their latest panels for a shared cause.
- Stormraven faint end: find what the remaining low fan is.
- Other folded-wing meshes may share Stormraven's cause (clips swinging wing bones on a folded mesh): check Duskhush, Pipwing, Reedwing, Aeriex with the same clip read-out before building anything.

## Runbook additions
- Fresh checkout: `godot --headless --path . --import` takes about 25 minutes.
- `capture_f36_poses.gd` refuses an existing output folder; six species, two roles: 48 s on CPU.
- Bone and weight probes used here are throwaway scripts that extend `tools/_capture_creature_roster.gd`; they need `await process_frame`, then `_world = Node3D.new(); root.add_child(_world)` before `_spawn_creature`.

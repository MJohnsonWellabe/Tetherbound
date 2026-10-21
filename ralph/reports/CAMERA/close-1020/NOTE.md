# Camera lane (tb/camera): F10#2 C3 and F04#6 aftermath, CPU close plan (20–21 Oct 2026)

Renderer for every capture here: Low/Compatibility, Mesa llvmpipe (CPU), 1280x720, cloud container. Owner rule (17 Oct): CPU three-judge Bar A mean ≥ 6.7 is met "CPU-provisional" until a GPU pass confirms 7.5.

## F10#2 C3: Stormwood named fights, camera occlusion

Capture (existing tool, unchanged): `XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 20 --script res://tools/capture_named_fights_f10_6.gd -- --out=<dir> --camera-view=north --seconds=18 --interval=1.0 --draw-shots-only [--fight-los-fade]`, ids hollows/capacitor/crown/old_rodfolk/glass_field. Blackwater Elder has no ground at the north or south stand, so it runs with the tool's default stand (`--ids=blackwater_elder`, no `--camera-view`) in both arms. `--fight-los-fade` turns on the OFF `line_of_sight_fade` candidate process-locally.

### Round 1, source 1042df800 + d1 config (corridor 2.0 m, fungi and rocks added)
Three code-blind judges; per-fight A/B sheets with sides shuffled (key `f10_2_r1_key.json`). Judges saw only the sheets, the prompt and REF images.

| Fight | Candidate (fade ON) j1/j2/j3 | Control (OFF) j1/j2/j3 |
|---|---|---|
| hollows_alpha | 6.0/6.0/5.5 | 6.0/6.0/5.5 |
| capacitor_alpha | 5.5/5.5/5.5 | 4.0/4.0/3.5 |
| crown_guardian | 7.0/7.0/7.0 | 7.0/7.0/7.0 |
| old_rodfolk_hall_guardian | 6.5/6.0/6.5 | 5.0/5.0/4.5 |
| blackwater_elder | 6.5/6.5/6.5 | 5.5/6.0/5.5 |
| glass_field_alpha | 6.0/5.5/6.0 | 4.0/4.0/3.0 |
| **Mean** | **6.17** (6.25/6.08/6.17) | **5.14** (5.25/5.33/4.83) |
| C3 | 6/6 PASS, all three judges | 3/6 PASS (Capacitor, Old Rodfolk, Glass Field fail: full-green frames, trunks over tells/impacts) |

+1.03 over the matched control; below 6.7, so not met. Remaining asks, all judges: canopy still washes the frame top at Capacitor/Glass Field; dark arenas hide the small pilot; telegraphs drift under the bottom HUD; pilot hidden under the spider on CHARGE lunges.

Round 2 candidate (OFF, commit on tb/camera): lens band 4/10 m and corridor 2.5 m while the candidate runs, plus an unshadowed fill light that follows the pilot.

### Round 2, candidate (lens band 4/10 m, corridor 2.5 m, pilot fill light) vs the round-1 control frames
Fresh three judges, new shuffle (key `f10_2_r2_key.json`).

| Fight | Candidate r2 j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| hollows_alpha | 5.5/6.0/5.5 | 5.5/6.0/5.5 |
| capacitor_alpha | 5.5/6.0/6.0 | 4.0/4.5/4.5 |
| crown_guardian | 6.5/7.0/7.0 | 6.5/7.0/7.0 |
| old_rodfolk_hall_guardian | 6.0/7.0/6.5 | 4.5/4.5/5.0 |
| blackwater_elder | 5.5/6.5/6.5 | 5.5/6.5/6.5 |
| glass_field_alpha | 5.5/6.0/6.0 | 3.5/4.0/4.0 |
| **Mean** | **6.14** (5.75/6.42/6.25) | **5.25** |
| C3 | 6/6 PASS, all judges | 4/6 |

Flat against round 1 (6.17): first round under +0.5. The fill light did not register with any judge. Asks: canopy still at frame edges; pilot tiny and lost behind spiders; telegraphs and pilot slide under the bottom HUD; dark ground.

Round 3 (clearly different approach, a5d2cc1fd, OFF): the fight-camera solver's visibility score casts rays from each candidate lens to both fighters' torsos, and a world-collider hit (trunk, rock) counts as hidden, so the solver picks a clear orbit rather than only fading what is in the way.

### Round 3, candidate a5d2cc1fd (sight-line fade + world-collider sight rays in the camera solver) vs the round-1 control frames
Fresh three judges, new shuffle (key `f10_2_r3_key.json`).

| Fight | Candidate r3 j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| hollows_alpha | 6.2/5.5/6.8 | 6.0/5.0/6.5 |
| capacitor_alpha | 6.3/6.5/6.8 | 4.0/3.5/4.5 |
| crown_guardian | 7.0/7.0/7.3 | 6.9/6.8/7.2 |
| old_rodfolk_hall_guardian | 6.3/6.5/6.5 | 5.0/4.5/5.0 |
| blackwater_elder | 6.8/7.0/7.0 | 6.0/6.0/6.6 |
| glass_field_alpha | 6.4/6.5/6.4 | 3.8/3.5/3.8 |
| **Mean** | **6.60** (6.50/6.50/6.80) | **5.26** (5.28/4.88/5.60) |
| C3 | 6/6, 5/6, 6/6 (j2 failed Hollows on pilot readability; it failed the control for the same reason) | 3/6, 2/6, 3/6 |

+0.43 over the best (6.17); round 2 was −0.03. Two consecutive rounds under +0.5 with one clearly different approach tried: **CPU plateau at 6.60** (owner rule: CPU evidence alone never parks). Not met on CPU (6.7). Remaining asks from all three judges: keep the pilot and full telegraph above the bottom action panel (Mosshock, Voltarach close-ups), stop zoom jumps (Hollows i17, Crown tell2-a), and give the small pilot a marker or rim against dark soil. The candidate stays OFF; it is the best camera for a GPU pass.

### Round 4 (7bc6ed8de: round 3 + 56 px HUD keep-out in the solver) vs control
Fresh judges (key `f10_2_r4_key.json`): candidate **6.17** (6.27/6.17/6.08), C3 6/6 for all three; control 5.75/5.75/5.67 on the same sheets. Lower than round 3; the keep-out is reverted (config key removed) so the OFF candidate is the round-3 camera. F10#2 remains a **CPU plateau at 6.60**, not met on CPU; candidate stays OFF for a GPU pass.

### Round 5 (coordinator request): round-3 camera (sight-line fade + lens refusal) on the origin/main merge 959887751, fresh matched control (both arms recaptured)
Fresh three judges (key `f10_2_r5_key.json`).

| Fight | Candidate j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| hollows_alpha | 6.2/6.2/6.6 | 5.8/6.0/6.5 |
| capacitor_alpha | 6.0/6.0/6.0 | 4.5/4.5/4.5 |
| crown_guardian | 7.0/7.0/6.8 | 7.2/7.3/7.3 |
| old_rodfolk_hall_guardian | 6.3/6.6/6.5 | 5.0/5.3/5.0 |
| blackwater_elder | 6.9/7.2/6.8 | 6.3/6.4/6.0 |
| glass_field_alpha | 6.0/6.3/6.0 | 4.0/4.0/4.0 |
| **Mean** | **6.47** (6.40/6.55/6.45) | **5.53** |
| C3 | 6/6, all three judges | 3/6, all three judges |

**F10#2 not met on CPU: plateau at 6.47–6.60** (rounds 3 and 5) against the 6.7 CPU bar; C3 passes 6/6 in both. The candidate (`line_of_sight_fade` with `camera_world_sight`, OFF) is the camera to take to a GPU pass. Remaining asks, all judges: a size and distance floor for the small pilot (far pull-outs, spider close-ups pushing it onto the action bar), canopy at the frame edges, and pilot/ground contrast (rim light or contact ring).

## F04#6 distinct aftermath

Capture (existing): `xvfb-run ... godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/_probe_aftermath_sites.gd -- --out=<dir> --cameras=res://tools/visual_judge/camera_sets/F04-6.json [--candidate]`. Direct-settle diagnostic, not an earned defeat (as before). CPU baseline (OFF) 10/10 frames, exit 0; r15 candidate 10/10.
r16 candidate (OFF): all five sites rebuilt from installed families (see each `_why_r16` in `data/config/trainer_aftermath.json`). Meshy request for seven aftermath props sent to the coordinator.
Sheet: _sheet_f10_2_r3_capacitor.png, Capacitor Alpha, left = control (sheet E-A), right = round-3 candidate (E-B).

### F04#6 r16b (a5d2cc1fd, process-local `--candidate`) vs CPU control (OFF), three code-blind judges
Per-site sheets, A/B rows shuffled, each row before|after (key `f04_6_r16b_key.json`).

| Site | r16b j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| relay_officer_dell | 5.0/6.5/6.0 | 4.5/5.5/5.0 |
| relay_captain (Vance) | 6.0/6.5/6.5 | 5.0/5.5/6.0 |
| captain_riverwatch (Oreth) | 4.5/6.0/5.0 | 5.0/5.5/5.0 |
| captain_field (Halder) | 6.0/6.0/6.5 | 5.5/5.5/6.0 |
| captain_ridge (Vess) | 5.0/5.5/5.5 | 5.5/6.0/5.5 |
| **Mean** | **5.77** (5.30/6.10/5.90) | **5.40** |

Below 6.7. Unanimous top ask: the oxblood standard still hangs at every site after the win (strongest sign of occupation), and the beaten rival lingers beside it. Also: Riverwatch and Ridge read alike (barrier aside + lit emblem); Riverwatch's restacked crates read as shuffling; a dropped Ridge lantern clips the lens. Distinct: Field (fire out, smoke, struck camp), Vance (empty cage, Sela freed), Dell (pylon toppled, crates burst).
r17 (OFF): each site's standard comes down with its own fate (Dell/Vance/Ridge torn down at different spots, Oreth's thrown forward, Halder's burned to a smouldering stump), the rival walks off up the road, Riverwatch's block is smashed where it stood, Ridge's lanterns fall by the posts.

### F04#6 r18d (95e80bfe1, `--candidate`: standards down per site, rival walks off, Meshy cage/banner/barricade/brazier/rope post/pylon debris) vs CPU control
Fresh three judges (key `f04_6_r18_key.json`).

| Site | r18d j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| relay_officer_dell | 6.5/6.0/7.0 | 5.0/4.5/5.5 |
| relay_captain (Vance) | 6.5/6.5/7.0 | 5.5/5.0/5.5 |
| captain_riverwatch | 6.0/5.5/6.5 | 5.5/4.5/6.0 |
| captain_field | 7.0/6.5/6.8 | 6.0/5.5/6.0 |
| captain_ridge | 6.0/6.0/6.8 | 5.0/5.0/6.3 |
| **Mean** | **6.44** (6.40/6.10/6.82) | **5.39** |

+0.67 over r16b (5.77); below 6.7. Distinct: mostly yes (freed captive, breached checkpoint, doused camp, relit waystone, smashed barricade); Riverwatch and Ridge still share the lit-emblem motif. Asks: same cage changed state rather than a smaller swapped model; Riverwatch crate clutter and hovering crates; tent-to-cot reads as a new prop; half-sunk brazier; Dell's crates interpenetrate; faint smoke.
r19 (OFF) addresses each.

### F04#6 r19 (8af781327, `--candidate`) vs a fresh control rendered on the main merge
Fresh three judges (key `f04_6_r19_key.json`).

| Site | r19 j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| relay_officer_dell | 6.5/6.5/6.0 | 4.5/5.5/4.8 |
| relay_captain (Vance) | 7.0/6.5/6.5 | 6.0/5.5/5.0 |
| captain_riverwatch | 7.0/6.5/6.5 | 5.5/5.0/6.0 |
| captain_field | 7.0/7.0/7.0 | 6.0/6.0/6.3 |
| captain_ridge | 6.5/6.0/6.5 | 5.5/5.0/5.5 |
| **Mean** | **6.60** (6.80/6.50/6.50) | **5.47** |

+0.16 over r18 (6.44); 0.1 under 6.7. Distinct: yes, except Ridge and Riverwatch share the lit-waystone + barrier-down beat. Asks: separate Ridge/Riverwatch, take the wreck off Riverwatch's path, Dell's pylon reads as a canister and the metal crates have black faces, hard-topped smoke, Vance's cage changes model (an intact twin of the broken cage requested from Meshy).
r20 (OFF): Ridge's watch-beacon relit (warm fire, distinct from Halder's fire out), Riverwatch wreck off the verge, Dell wooden crates and larger pylon debris, softer smoke.

### F04#6 r21 (e4f57d98d: r20 + one Meshy cage closed→torn open at Vance) vs the fresh control
Fresh three judges (key `f04_6_r21_key.json`): **6.47** (6.60/6.50/6.30) vs control 5.57. Vance 7.0 from all three; Dell 6.0–6.5 (fallen pylon reads as a canister), Riverwatch 6.0–6.5 (the wreck rack hides the waystone), Ridge 6.0–6.5 (relit fire contradicts Halder's doused fire), Field 6.5 (black brazier blob). Second consecutive round under +0.5 (r19 +0.16, r21 −0.13); best stays r19 6.60.
r22 (clearly different approach, OFF): declutter to one hero beat per site; unreadable wreckage and second-beat props removed.

### F04#6 r22 declutter (b7fa03573, `--candidate`) vs the fresh control: **6.75, met CPU-provisional**
Fresh three judges (key `f04_6_r22_key.json`; sheet `_sheet_f04_6_r22.png`, columns control before/after, r22 before/after).

| Site | r22 j1/j2/j3 | Control j1/j2/j3 |
|---|---|---|
| relay_officer_dell | 6.5/5.5/5.5 | 5.5/5.0/5.0 |
| relay_captain (Vance) | 8.0/7.0/7.2 | 6.5/5.5/5.5 |
| captain_riverwatch | 7.5/7.0/7.0 | 6.5/5.5/5.5 |
| captain_field | 7.0/6.5/6.8 | 6.5/6.0/6.5 |
| captain_ridge | 7.0/6.5/6.3 | 6.5/6.0/5.5 |
| **Mean** | **6.75** (7.20/6.50/6.56) | **5.83** (6.30/5.60/5.60) |

Distinct: all three judges call the five aftermaths mostly distinct (freed captive, dismantled checkpoint, doused camp, cut line, cleared gate); Riverwatch and Ridge still share the lit-waystone beat. Remaining asks for the GPU pass: Dell's site (world art: purple wall plates, floating crate; the pylon state change is weak), hard-edged smoke column, Ridge's leftover post reads as clutter.

## READY F04#6 (CPU-provisional; a GPU pass must confirm 7.5)
- **Visual proof:** `XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/_probe_aftermath_sites.gd -- --out=<dir> --cameras=res://tools/visual_judge/camera_sets/F04-6.json --candidate` on b7fa03573 (r22; Vance frames from e4f57d98d, the same Vance config), control the same command without `--candidate` on 959887751 (main merge). Low/Compatibility, Mesa llvmpipe. Three code-blind judges: r22 **6.75** vs control 5.83 (≥ 6.7 CPU-provisional bar). Direct-settle diagnostic: the after state is `trainer_aftermath.settle()`, the same path a reload/rematch re-attach takes.
- **Flag:** `visual_candidate_enabled` turned ON with this proof. Presentation only: no defeat flag, reward, collision, save or network change.
- **Tests:** `godot --headless --path . --script tests/run_tests.gd -- --only=test_trainer_aftermath.gd,test_trainer_aftermath_lifetime.gd,test_trainer_aftermath_world_change.gd` → 16 tests, 152 assertions, 0 failed. Updated to the judged contract: the old "candidate is OFF / only two sites" test is now "judged set is ON, only presentation keys (site_object, sigil_stone, stand_down) differ, OFF restores the baseline, no trainer added"; the two `keep_standards` branches gain the judged-set branch (upright standard hidden, the site's after state with its fallen standard shown).
- **Probe:** `_probe_aftermath_sites.gd` refused to run with the flag ON; the smallest fix requires `--candidate` when the shipped set is ON (needed for the GPU confirmation).
- **test_named_fight_profiles:** fails only on `tb/camera`, which carries the Fights lane's unlanded F22#4 `camera_boss_side_view` row on captain_riverwatch; it passes on the F04#6 landing tree (`tb/camera-land`, PR #697).
- **Open (not claimed):** earned-defeat/reload/co-op capture of these sites; GPU Medium/High three-judge confirmation of 7.5.

## F10#2 r6 (21 Oct; CPU Low/Compatibility, Mesa llvmpipe): CPU plateau recorded

Candidate (flag OFF on tb/camera, 8c1fef43a): the r3 sight-line fade and lens refusal, plus a pilot size floor on the fight camera (pilot ≥7% of frame height), the pilot silhouette rim and a pale cyan contact ring. Compared against a fresh matched control. Six Stormwood named wilds: `tools/capture_named_fights_f10_6.gd --seconds=18 --interval=1.0 --draw-shots-only`, north view for five and the default stand for Blackwater Elder. 18 interval frames plus tell 1–2 frames per side. Three code-blind judges; key withheld until all three scores were in (`f10_2_r6_key.json`).

| Fight | Candidate | Control |
|---|---|---|
| hollows_alpha | 6.57 | 6.40 |
| capacitor_alpha | 6.23 | 4.70 (C3 FAIL x3: camera in canopy) |
| crown_guardian | 7.07 | 7.07 |
| old_rodfolk_hall_guardian | 6.37 | 5.50 (C3 FAIL x3: trunk hides the fight at impact) |
| blackwater_elder | 6.80 | 6.77 |
| glass_field_alpha | 6.43 | 4.87 (C3 FAIL x3: green-out at a hit) |
| **Mean** | **6.58** | 5.88 |

Candidate C3 passes 6/6 for all three judges. Bar A is 6.58, under 6.7. The rounds so far: r1 6.17, r2 6.14, r3 6.60, r4 6.17 (the different approach, a HUD keep-out), r5 6.47, r6 6.58. Gains have stayed under 0.5 for several rounds, and the different approach was tried. The judges' remaining asks are lighting and exposure on the dark forest floor, a slimmer HUD and filled ring and lane tells. Those are outside this lane's camera and occluder scope (the shared telegraph and HUD belong to other lanes). **CPU plateau recorded, not parked (CPU-only never parks).** The candidate stays OFF pending a GPU pass or the coordinator's call.

## F10#2 r7 (21 Oct; coordinator's last batched round; CPU Low/Compatibility, Mesa llvmpipe): 6.69, not met

The candidate is r6 plus two additions. Fights' filled-lane and impact-burst hooks (tb/fights 9366c0230, ea1ea3316; the hook files were taken whole at f4b850fd1) are switched on, for this capture only, for the six Stormwood named lane rows (`hollows_alpha_charger_rush`, `hollows_alpha_charger_double_rush`, `capacitor_alpha_charger_rush`, `old_rodfolk_hall_guardian_ace_lane`, `glass_field_alpha_charger_rush`, `glass_field_alpha_charger_double_rush`). Cone, fan, field and marker rows were skipped. The pilot fill light is widened to a 9 m pool from 3.5 m up. The HUD is untouched. Same tool, cameras and frame selection as r6, against a fresh matched control. Key withheld until all three scores were in (`f10_2_r7_key.json`).

| Fight | Candidate | Control |
|---|---|---|
| hollows_alpha | 6.63 | 6.13 |
| capacitor_alpha | 6.43 | 5.60 |
| crown_guardian | 7.07 | 7.07 |
| old_rodfolk_hall_guardian | 6.70 | 4.77 (C3 FAIL x3: camera in foliage at the impact) |
| blackwater_elder | 6.83 | 6.70 |
| glass_field_alpha | 6.50 | 5.37 (C3 FAIL x2) |
| **Mean** | **6.694** | 5.94 |

Candidate C3 passes 6/6 for all three judges; the capacitor control had a trunk blackout at i09, and that only drew a note. Bar A 6.694 is under 6.7. That's +0.11 over r6 and the best yet. The judges credited the filled lanes on the spider fights (hollows, glass_field). Their remaining asks: steadier camera distance (far pull-outs on crown_guardian and blackwater), a stronger pilot marker, filled cone/ring tells, and brighter floor lighting. **CPU plateau recorded at 6.69, not met, not parked.** Flags stay OFF; the combat.json cue keys were capture-only and are not committed. A GPU pass decides.

## F10#2 r8 (21 Oct; CPU Low/Compatibility, Mesa llvmpipe): 6.77, C3 6/6. READY F10#2 (CPU-provisional)

The candidate (2c419a91e) is r7 plus four changes:
- `line_of_sight_fade.named_max_distance_m` caps the fight lens for each named wild (by `named_encounter_id`): 11 m, or 12 m for crown_guardian and blackwater_elder.
- The pilot contact ring is thicker (0.24 m), paler (#c8fdff) and drawn over the ground.
- The pilot rim is 0.9.
- The pilot fill light is energy 3.2, range 12 m, 4.5 m up.

The Stormwood named lane rows again use Fights' filled-lane and impact-burst hooks, for this capture only (same six rows and keys as r7). Cone and ring fill has no hook under the soft telegraph style, so it was skipped. Same tool, cameras and frame selection as r6/r7, against a fresh matched control. Key withheld until all three scores were in (`f10_2_r8_key.json`).

| Fight | Candidate | Control |
|---|---|---|
| hollows_alpha | 6.50 | 5.87 |
| capacitor_alpha | 6.63 | 4.23 (C3 FAIL x3: camera in canopy i09–i17) |
| crown_guardian | 7.17 | 6.77 |
| old_rodfolk_hall_guardian | 6.53 | 5.13 (C3 FAIL x3: fighters lost at impact) |
| blackwater_elder | 7.07 | 6.67 |
| glass_field_alpha | 6.70 | 4.97 (C3 FAIL x3: foliage green-out) |
| **Mean** | **6.77** | 5.61 |

Judges' means for the candidate: 6.85, 6.70, 6.75. Candidate C3 passes on all six fights for all three judges. The judges credited the solid lanes plus the pilot ring, and the fights staying free of trunks and canopy.

### Flag ON (this commit)
`data/config/foliage_camera_visibility.json` sets `line_of_sight_fade.enabled_realms` to `["stormwood"]`. In Stormwood that is the same switch the capture's `--fight-los-fade` sets process-locally (`enabled: true`; the realms list is stormwood and playground). Headless ON check (`f10_2_on_check.gd.txt`):

`F10_2_ON_CHECK {"stormwood":true,"playground":false,"cloudreach":false,"water":false,"crown_cap_on":12.0,"floor_m_sparkit_on":13.46}`

Meadows, Cloudreach and Tidewake stay OFF.

### Landing dependencies
1. **Fights' telegraph hooks:** tb/fights `ea1ea3316` (contains `9366c0230`). These are already on tb/camera at f4b850fd1, as the three files `scripts/combat/enemy_pattern_telegraph.gd`, `scripts/combat/lunge_lane.gd` and `scripts/creatures/wild_creature.gd`.
2. **combat.json row keys (Fights-owned; not committed here; coordinator to land).** Add these keys to each of `patterns.attacks.hollows_alpha_charger_rush`, `hollows_alpha_charger_double_rush`, `capacitor_alpha_charger_rush`, `old_rodfolk_hall_guardian_ace_lane`, `glass_field_alpha_charger_rush` and `glass_field_alpha_charger_double_rush`:

   `"cue_lane_solid": true, "cue_lane_fill_alpha": 0.32, "cue_lane_locked_fill_alpha": 0.6, "cue_lane_edge_alpha": 1.0, "cue_impact_burst": true, "cue_burst_colour": "#6fb8e8", "cue_burst_foam": "#f2fbff"`

   Without them, the ON flag ships the r6-style thin lanes. That is weaker than what was judged; r6 scored 6.58.
3. **No cone/ring keys:** none were used.

**READY F10#2 (CPU-provisional):** CPU three-judge Bar A 6.77 ≥ 6.7 (the owner's 7.5 bar minus the 0.8 CPU/GPU gap), C3 6/6. A later GPU pass must confirm 7.5; below that the criterion reopens.

# Camera lane (tb/camera): F04#6 aftermath, CPU close plan (20–21 Oct 2026)

Renderer for every capture here: Low/Compatibility, Mesa llvmpipe (CPU), 1280x720, cloud container. Owner rule (17 Oct): CPU three-judge Bar A mean ≥ 6.7 is met "CPU-provisional" until a GPU pass confirms 7.5.

F10#2 (camera, CPU plateau 6.47–6.60, OFF) evidence stays on `tb/camera`.

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
- **Not mine, pre-existing:** `test_named_fight_profiles.gd::test_a_profile_means_the_same_thing_in_every_fight_that_uses_it` fails with the flag OFF too (`camera_boss_side_view` only on captain_riverwatch's CURRENT profile, from the Fights lane's F22#4 work).
- **Open (not claimed):** earned-defeat/reload/co-op capture of these sites; GPU Medium/High three-judge confirmation of 7.5.

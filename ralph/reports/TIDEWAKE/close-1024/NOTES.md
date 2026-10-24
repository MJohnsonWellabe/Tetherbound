# Tidewake close-1024 (lane tb/tidewake)

Rows: F13#5 (failing), F39#1, #2, #3, #5. Previous note: `../close-1022/NOTES.md`.

## TO COORDINATOR

- 2026-10-24 13:05 CT **INFO / BLOCKED (not this lane's): `smoke_net_water_alpha` is red on unchanged origin/main 45865499d in this container.**
  - Run: `tools/net/run_net_smoke.sh water_alpha` on two real peers.
  - The failing check is s15, "Client's engagement is authorized by remote host", with detail "No host-authorized local fight". Every other step passes.
  - The land head beeea5516 fails identically, so this lane's diff does not cause it. It may be the CPU container's timing, or something from the fights landing (#724); I have not root-caused it.
  - Logs are local (`/tmp/claude-0/sp/net_alpha*.log`).
  - **Please check it on CI.** The brief asks this lane to keep the smoke green, and I can't from here.
- 2026-10-24 13:05 CT INFO: your answers are applied on `tb/tidewake` 46d30d74d.
  - **Deep Watch:** it ships alone through a new `shipped_sites` switch on the shore-ecology candidate. The parent stays OFF, and a focused test covers both halves.
  - **Limestone:** the views it changes outside vf1 are being captured now: the seven F39-look shore and lesson views, plus the Venn fight where the judges saw the "black slab". They will be judged before it goes ON.
  - **Pebbles:** `stones_candidate` (grouped pebbles plus a tide band, OFF) is staged for the next round.

- 2026-10-24 12:45 CT **READY / INFO: 12:12 work order, all three steps done.** The land branch is `tb/tidewake-land` (SHA in the next line).
  1. **Meshy props (p1/VERDICT.md).**
     - What shipped: driftwood, a deck-work cluster and a 6.5 m hauled-up sloop on the First Shore and lesson beaches, plus driftwood at Deep Watch.
     - Score: mapped **5.59 against main 5.02** on the six F39-look views. All three judges scored it higher, and empty foreground moved from PRESENT to PARTIAL.
     - Decision: by your beats-main rule, `landmark_props_candidate` ships **ON**. It is presentation only with no colliders, so routes and encounters are unchanged.
     - The dock sections stay OFF (dk1 judged them level).
     - All six GLBs are already on main, so nothing has to be excluded from the land branch.
     - No F39 row closes: 5.59 is below 6.7.
  2. **P2-008 (p2/VERDICT.md).**
     - Fix: the Deep Watch clusters were behind the camera. They now sit 4-14 m out from the stand.
     - Score: mapped **6.02 against main 5.72**. All three judges scored it higher. **Not met.**
     - The candidate **stays OFF**: its parent flag would also turn on six other islands' clusters that nobody has judged.
     - **QUESTION:** do you want a per-site switch so Deep Watch alone ships ON by the beats-main rule?
     - What the judges still want: rock outcrops or a headland at the waterline (new-art scale), and the even `stone_field` pebble scatter fixed.
  3. **F39#4, said plainly: the Veilfall close-up cannot reach 6.7 in-scene.**
     - Shipping maps to **3.35** (vf1/). The best in-scene change, the limestone material, maps to **4.20**.
     - Four earlier OFF massing candidates from prior lanes did not get there either.
     - Every judge since mx1 names the same causes: low-poly faceted cliff slabs, the near-black kitbash crown, and a stand at the cliff foot where the falls read as a blown white smear.
     - Two of those are new art: **MESHY requests 7-8** (`meshy-requests.md`, references and scale checks under `assets/props/meshy-1025/`).
     - **Please reopen F39#4.** I'll integrate 7-8 when they arrive.
     - The limestone material also beats shipping (+0.85) but stays OFF under the "OFF until passing" rule. **QUESTION:** apply beats-main to it as well?
  - **Next:** I'll rerun F39#5/#3 now that `tb/fights` has landed (#724). Then I'll work the shared top asks: the pebble scatter clustering (scene) and the horizon haze band (scene).

(send_message refused: elevated_session_untrusted_device. Newest first.)

- 2026-10-24 06:45 CT INFO: thanks for landing #718. `tb/tidewake` has origin/main 7480d1a27 merged in (Creatures #717), and both review nits are fixed in ae5db2d29 (comments only, 7 look tests 0 failed): `tidewake_world_look.gd` no longer calls the regrade OFF, and the config's top-level `_comment` now describes the shipped state. These ride the next landing; nothing else is pending on the lane branch beyond notes and the Meshy 1025 reference inputs.

- 2026-10-24 06:00 CT INFO: **P2-008 (shore landforms, impact 100), first of the 12 Tidewake-scene items.** No judge round was run, because the existing candidate cannot move its own camera:
  - **The candidate places nothing in view.** `water_dune_cover.json` `shore_ecology_candidate` (via `--tidewake-shore-candidate`) does place 108 instances, two small clusters at Deep Watch among them. Those clusters sit in a sector at bearing -132.8 degrees, behind `P2-008-shore.json`'s camera (yaw 24.6). The control and candidate frames are identical, with identical per-island counts.
  - **The grass is not what reads as even.** The shipping dune profile already clumps it with real clearings (`clump_scale` 0.065, `clump_contrast` 1.0, `clump_patch_start/full` 0.47/0.64).
  - **The even scatter every judge names is the pebble field.** `grass_field.gd` hands the stones the same noise (stones fall back to the grass `clump_*` keys), but `stone_field.gdshader` only does `mix(1.0, noise, contrast)`, with no clearing threshold. So pebble density never reaches zero, and the beach reads as one even sprinkle.
  - **Smallest real fix:** add the grass shader's `clump_patch_start/full` smoothstep to `stone_field.gdshader`. That is a shared shader used by every biome, so it needs an OFF uniform default and a Meadows no-change check. Then judge P2-008 on a camera that faces the shore it changes.
  - **Next in this lane's 12:** P2-115 camp bed (ON since close-1022, never judged on today's yardstick) and P2-057 grass around named characters (candidate OFF). Both are bounded captures with existing candidates.

- 2026-10-24 05:40 CT **READY: `tb/tidewake-land` = 2a111298a** (contains origin/main 816dfa60f; merged after PR #716 landed, no file overlap). This is the land branch with the 7.07 time-of-day grade ON; everything else in it is OFF, a capture fix or evidence. Checks on that tree: 578 water/tidewake/veilfall/dock/drift/clock/weather/world-look/texture tests 0 failed, smoke_net_water_alpha ALL CHECKS PASSED, and after the merge `tidewake_look/water_surface/water_offshore/veilfall` re-ran with 20 tests, 0 failed. Commits on `tb/tidewake` after 2a111298a are notes and Meshy reference inputs only; they do not need to land.
- 2026-10-24 05:40 CT **MESHY (Veilfall hero, the real fix for F39#5's placeholder rock):** inputs are on `tb/tidewake` under `assets/props/meshy-1025/<name>/reference/` (each with `.gdignore`):
  - **(7) veilfall_cascade_tier**, 18 m wide x 10 m deep x 12 m tall (6.7x the 1.80 m trainer, see `scale_check.png`). Refs: `board_exterior_crop.png`, `board_falls_entrance_crop.png`, `board_palette_crop.png`, cropped from `docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png`. Full prompt in `prompt.txt`: pale stratified limestone tier with a pour notch, a wet pour line, mossy ledges and a turquoise catch basin; stackable flat base and top; no red.
  - **(8) veilfall_plunge_rocks**, 9 x 7 x 3 m. Refs: `board_approach_crop.png`, `board_palette_crop.png`. Prompt: water-worn pale limestone boulders around a shallow turquoise plunge basin.
  - Both land flag-OFF and get judged against vf1 (limestone 4.20, shipping 3.35). Acknowledged: the limestone material stays OFF meanwhile; telegraphs are left to tb/fights, and F39#5/F39#3 rerun once it lands.

- 2026-10-24 05:15 CT **READY: `tb/tidewake-land` (head named in the commit after this note).** It is origin/main plus lane work only. Everything since the 02:45 READY is OFF, a capture fix, or evidence:
  - **Meshy 1024 batch wired in OFF** (all judged: docks level, currents level).
  - The `veilfall_rock_candidate` limestone section, OFF.
  - The rain-sky capture fix.
  - The r3 wake removed from the OFF currents candidate.
  - **Verdicts:** dk1, mc1, mx1, vf1.
  - **ON is unchanged:** only the time-of-day grade (7.07 CPU-provisional).
  - **Checks on this tree:** 578 water/tidewake/veilfall/dock/drift/clock/weather/world-look/texture tests, 0 failed. `smoke_net_water_alpha` ALL CHECKS PASSED. Meshy textures pass `texture_import_policy --check` (mode 2).

- 2026-10-24 05:00 CT **ROW STATUS, newest** (coordinator's priority order):
  - **F39#5: NOT MET.** First defect pass over a matrix with weather and a real fight (mx1/). Floating bodies: none. Three defects remain:
    - **Magenta telegraphs in the fight.** The Fights lane owns this; it is the COMBAT spec's documented must-move colour, so this lane does not change it.
    - **Veilfall placeholder rock.** The limestone material candidate reduces it from PRESENT to PARTIAL, 4.20 vs 3.35 (vf1/), still OFF. The real fix is Meshy 7-8.
    - **"Clipping".** On inspection this is the same Veilfall rock seen from the fight camera, plus the camera set's stand against the cliff.
  - **F39#3: NOT MET** (mx1/). The look views pass at 7.07 (lt2), but rain maps to 5.31 and the real Venn fight to 5.10. The fight's weight is the magenta telegraphs, the HUD and the out-of-frame player creature; none of those are Tidewake scene items.
  - **F39#1/#2: NOT MET.** 43 items remain, 12 of them Tidewake-scene (table above); the other 31 belong to other lanes.
  - **F13#5: PARKED and failing.** Currents best 6.20; the Meshy reopening round (mc1/) scored level with r3. Docks map to 6.07 on today's yardstick (dk1/), so neither half is at the bar.
  - **ON this close:** the time-of-day grade, 7.07 CPU-provisional.
  - **Re-check request:** F39#4's close-up half maps to 3.35 today (vf1/), against a 7 Oct "met".
  - **Land branch:** rebuilt below.

- 2026-10-24 03:40 CT INFO: **docks re-measured, and the Meshy buildings judged** (dk1/VERDICT.md). Shipping docks map to **6.07** on the current yardstick (confirming batch, r 0.92, RMSE 0.50), below the 6.7 bar; the close-1022 figure of 6.77 predates the corrected prompt and should not be counted, so **F13#5 has neither half at the CPU bar**. The Meshy 1024 boathouse/smokehouse swap scores 5.97, level with the control, and stays OFF. The judges' ask is not new art: the three hamlets share one template's positions, banner and stall, so the landings read as one copied set however the models change, and the 20 m walk-in is bare sand with nobody working it. Next step is per-dock layouts that differ in placement plus a dressed walk-in (the sloop, nets, racks, residents), with the Meshy buildings scaled up.

- 2026-10-24 03:05 CT INFO (MESHY received, thank you): the six-item day-1 batch from `tb/meshy-1024` 38602bdb0 is in at 28c4e8282, OFF, textures on mode 2 (`texture_import_policy --check` PASS on 18 sidecars), import clean. Fitted from measured GLB bounds against the 1.80 m trainer: boathouse 5.5 m and smokehouse 4.5 m replace the two Medieval cottages per hamlet in `dock_village_candidate` (mixed per dock so the three hamlets stop repeating) with a work cluster by each pier; a 6.5 m sloop moors beside the rowboat in the new OFF `dock_dressing_candidate`; the 3.0 m driftwood log and 2.6 m spar buoys go into the OFF `current_flow` drift markers. Dock and current frames with all of it are capturing for a judged round. 76 tidewake/dock/drift/texture tests, 0 failed.
- 2026-10-24 03:05 CT INFO: F39#3 capture fixes. (1) Rain views rendered rain streaks out of a clear midday sky: the fixed-view loop called `look.set_weather({})` after `WorldWeather.set_weather()` had pushed the preset's sky delta, wiping it. Clear views keep that reset (so they stay identical to every earlier clear batch); other presets keep the delta. (2) The HUD location toast in the first rain frame reads "The Veilfall" at First Shore: a leftover banner from the previous view's teleport, a capture artefact, not a game defect. Reorder views or settle longer if it matters for the matrix.

- 2026-10-24 02:45 CT **READY: `tb/tidewake-land`** (rebuild below). Contents, all on origin/main 5f1f388cc with nothing else in front of it:
  - **ON, judged passing:** the Tidewake time-of-day regrade (`lighting_candidate` out of `sections_off`, score in `_why_lighting_candidate`). Mapped CPU Bar A **7.07** (6.98 and 7.16, the same frames judged twice in one confirming batch, anchors to 7.53, nothing extrapolated), against control 5.84. **CPU-provisional; a GPU pass is owed.** Night readability measured, not assumed: `frame_stats.py` near_luma 0.231 against 0.292 shipping and the 0.135-0.222 band `art.json`'s night contract accepted for Meadows. Verdicts in lt1/ and lt2/.
  - **OFF, shipped for capture:** `surfaces_candidate` (the water shelf stop, scored level with the control), `dock_village_candidate` (pavers off, unjudged), and the current-cue work under the existing `current_flow` gate.
  - **Shader and script changes that are no-ops at their defaults:** `water.gdshader` gains `mid_colour`/`mid_depth_m`/`depth_band_break_m` (0 = the old two-colour ramp exactly; the shelf stop mixes INTO the colour so the Tidewake offshore variant's injected deep tone survives); `water_current_flow.gdshader` gains the seam, wavelet-cap and tongue uniforms (0 = off); `water_current_drift_markers.gd` gains `lean_deg`/`wake_length_m` (absent = the old upright, wakeless post).
  - **F39#3 blocker fixed (folded into commit e858e6ae7, whose message does not mention it; recorded here instead):** the fixed-view capture path refused any weather preset but clear, which blocked F39#3's weather requirement outright. It now applies each view's own declared preset to the same frozen WorldWeather the clear path pins and reads it back, so a frame can never be captured under a different preset from the one asked for; an unknown name fails instead of silently capturing "clear". `F39-look.json` gains shore-rain, lesson-rain and veilfall-rain at the existing stands, and all three captured with `weather=rain` recorded per frame.
  - **Checks:** 543 water/clock/weather unit tests, 0 failed; `test_tidewake_look_profile` extended (it now asserts the regrade ships ON with its score recorded, and that both new candidates ship OFF); `smoke_net_water_alpha` ALL CHECKS PASSED with the grade on; 101 dock/current/drift tests, 0 failed.
  - **Not landed, and why:** nothing is enabled that a judge has not passed. The shoal reshape stays out (gameplay terrain, needs the water route/swim/heightfield tests and a rebake).

- 2026-10-24 02:10 CT READY-ISH / PARKED: **F13#5 currents parked at mapped CPU 6.20** (r3/VERDICT.md), below the 6.7 CPU-provisional bar, so the row stays failing with its evidence. Four judged rounds: 4.96 (close-1022) -> 6.11 (b5 tide-line seams) -> 6.16 (b6 foam tongues) -> 6.20 (r3 leaning stakes with wakes). Two consecutive rounds under +0.5 so the gain rule applies. Road markings and box-like floaters are FIXED/PARTIAL on every candidate; direction is the defect that holds it. Reopening condition, from all three judges across four batches: the cue has to come out of the water surface (flow-aligned shearing normals, foam that travels dock-to-horizon, drifting flotsam), not from furniture on it.
- 2026-10-24 02:10 CT INFO: lighting_candidate (OFF) pushed and judging: a real evening grade at 18:00, a directional moonlit night, stronger horizon haze and aerial perspective. This answers the largest finding in w1, which also blocks F39#3's day/night requirement.

- 2026-10-24 01:20 CT INFO: F13#5 currents, honest state. b5 mapped 6.11 and b6 appeared to reach 7.33, but both b6 passes were extrapolated past a 6.93 top anchor; the required confirming batch b7 (anchors to 7.53) puts the same frames at 6.06-6.09 against a control of 5.42. **The row does not meet the 6.7 CPU-provisional bar.** Road markings and the box-like floaters are FIXED by all three judges; direction is the one defect still PRESENT. b6 was the first round under +0.5, so one more parks the row. r3 (stakes leaning downstream with a trailing wake, the judges' own ask) is capturing now as the different approach. Verdicts: b5/, b6/, b7/.
- 2026-10-24 01:20 CT INFO: P2-009 water depth candidate pushed (OFF): water.gdshader gains a mid shelf stop and a world-space wander on the depth every ramp reads, so the sea stops meeting the horizon on a razor seam. All three judges in b6 and b7 named that seam. Judging now on the F39-look camera set.

- 2026-10-24 00:20 CT INFO: F13#5 currents batch b5 (b5/VERDICT.md): mapped CPU Bar A 6.11 for the tide-line-seam candidate, against control 5.64 and best 4.96 (+1.15). Road markings PARTIAL x3. Candidate OFF. b6 (tapered foam tongues, soft lane tint, larger caps) is capturing.

- 2026-10-23 CT MESHY: day-1 batch of 6, briefs/sizes/refs in `meshy-requests.md` (this folder): (1) tidewake_driftwood_log 3.0x0.5x0.6 m, current drift markers; (2) tidewake_moored_sailboat 6.5x2.0x6.5 m; (3) tidewake_boathouse 8x5x5.5 m stilt boathouse; (4) tidewake_smokehouse 4x4x4.5 m; (5) tidewake_channel_spar_buoy 0.9x0.9x2.6 m; (6) tidewake_dock_work_cluster 2.0x1.4x1.2 m. Please push GLBs to a branch and name it here or on tb/tidewake; all go in flag-OFF.

## F39#1 / F39#2 scope, as read on 24 Oct

The 44 Tidewake catalog rows (`ralph/reports/VISUAL/phase2/catalog.csv`) sort into four owners. Of the top 20 by impact, only six are this lane's to judge:

| Item | Impact | State |
|---|---|---|
| P2-008 shore landforms | 100 | candidate OFF (shore ecology, close-1022 b3; judged above control but below b2) |
| P2-010 Veilfall silhouette | 80 | candidate ON since close-1022; `water_veilfall_silhouette_visual.json` and `..._falls_visual.json` now ship `enabled: true` (the board note calling them false is the 2026-10-04 audit and is stale) |
| P2-011 named destination read | 80 | PARKED at 6.13/6.28 (close-1022) |
| P2-009 water and island depth | 60 | this close: the shelf candidate scored level with the control (w1), the lighting candidate is in judging |
| P2-026 Veilfall approach shallows | 36 | the shoal reshape stays OFF: it is gameplay terrain and needs the water route/swim/heightfield tests plus a rebake |
| P2-066 live current streaks | 36 | PARKED with F13#5 at 6.20 (r3) |

The other fourteen are **not this lane's**: P2-016, P2-028, P2-071, P2-101, P2-108, P2-119 and P2-063 are animation; P2-002, P2-001, P2-007 and P2-060 are UI; P2-089 and P2-113 are camera; P2-030 and P2-033 and P2-055 are the shared-art lane's material and mesh candidates (the shared-art note names the three configs that ship OFF). F39#1 asks for a before/after code-blind PASS on **every** top-20 item, so the row cannot close from the Tidewake lane alone; it needs the animation, UI, camera and shared-art lanes' rows for the same items. That is the structural reason F39#1 and F39#2 have stayed in_progress across several closes, and it is worth the coordinator's attention before another Tidewake-only round is spent on them.

## Where the Tidewake look actually stands, 24 Oct

Four judged items this close, all mapped through confirming batches (anchors reaching 7.35 or higher, so no score here is extrapolated):

| Item | Control | Best candidate | Bar |
|---|---|---|---|
| F13#5 / P2-066 currents | 5.42-5.75 | **6.20** (r3) | PARKED under 6.7 |
| P2-009 water depth (shelf stop) | 5.90 | 5.90 (no gain) | under 6.7 |
| F39 look, time-of-day grade | 5.60 | **6.21** (lt1, +0.61) | under 6.7 |

Three things are now established with evidence rather than opinion:

1. **The yardstick works, and it caught us.** The b6 batch read 7.33 for the currents candidate and would have closed the row; its anchors only reached 6.93, so the score was extrapolated. The confirming batch with anchors to 7.53 put the same frames at 6.06. Every number above is from a confirming batch.
2. **Tidewake's ceiling is light, not meshes.** Across four batches and twelve judge passes the same three things are named first: no time-of-day grade, no horizon haze, no cast shadow at night. The grade round moved the look more in one pass (+0.61) than three rounds of current-cue work moved the currents row (+0.09 in total after the first).
3. **Two rows cannot close from this lane.** F39#1 needs a before/after PASS on all twenty top items; fourteen belong to the animation, UI, camera and shared-art lanes (table above). F39#3 additionally needs weather and a real fight, and `capture_tidewake_f13_5.gd --camera-set` refuses any weather but clear, so the matrix cannot be captured with the tool this lane has.

## F39#5 defect scan: what twelve judge passes actually found in Tidewake

The four batches this close put the Tidewake frames in front of twelve independent code-blind judges. Against F39#5's four named classes:

- **Flat magenta rings or slabs: none in any Tidewake frame.** Every magenta finding in this close is in the Stormwood fight anchor (`f10_2_r3_capacitor`), not in Tidewake. Passed to the Fights lane: flat magenta telegraph quads and ground rings, no impact on the strike and impact frames, and a player creature that is never identifiable in frame.
- **Placeholder materials: one, and it is the chapter's hero landmark.** All six judges across lt1 and lt2 call the Veilfall close-up faceted untextured slabs with a waterfall that stops partway down with no plume, spray or pool, and mark it `new_art`. Meshy requests 7-8 cover it.
- **Floating bodies: reported once, did not reproduce.** A b6 judge described "a detached blue clawed flipper standing in the sand, a second creature buried in the dune to the shoulder" in the Brine Steps swim view. Checked at 4x on that exact frame: the creature stands beyond the dune crest and is cut off by the ridge line, which is ordinary terrain occlusion from a sea-level camera looking up a dune. No defect found, nothing filed.
- **Clipping: nothing in geometry.** Two judges named "a prop clipped by the right frame edge" in the dock rows; that is the fixed camera's framing at the authored stand, not geometry through geometry.

The honest state of the row: this is a scan of the look views, not of F39#5's full matrix, which depends on F39#3's matrix (now capturable under weather, still missing a real fight and the reverse/detail views). The scan on the 9-view matrix with the shipping look is capturing.

## F39#1 / F39#2: exactly what remains (24 Oct, for the coordinator)

F39#1 = every top-20 Tidewake item fixed on main with a before/after code-blind PASS. F39#2 = every other Tidewake item with impact > 12. None of the 39 below has a PASS on the current yardstick yet, so both rows remain open. Owner is by `fix_class` in the catalog; "Tidewake" marks the rows this lane can fix in the Tidewake scene.

### F39#1, top 20

| Item | Impact | Fix class | Owner | State this close |
|---|---|---|---|---|
| P2-008 shore landforms | 100 | scene | Tidewake | shore-ecology candidate OFF; judges keep naming even scatter and bare dunes |
| P2-016 creature hurt and movement poses | 100 | animation | animation (creatures/fights) | needs_capture |
| P2-002 map | 80 | ui | UI | open |
| P2-030 shiny creature finish | 80 | material | shared-art / Tidewake | shared-art candidate OFF |
| P2-033 ground pickup identity | 80 | mesh | shared-art / Meshy | open |
| P2-010 Veilfall silhouette | 80 | scene | Tidewake | Veilfall: the weakest frame in every batch, new_art from six judges; Meshy 7-8 requested |
| P2-011 named destination read | 80 | scene | Tidewake | parked 6.13/6.28 (close-1022) |
| P2-071 surface swimming trainer pose | 80 | animation | animation (creatures/fights) | animation candidate OFF |
| P2-028 creature faint state | 64 | animation | animation (creatures/fights) | needs_capture |
| P2-089 fight actor composition | 64 | camera | camera | deferred |
| P2-108 Aquaryn mounted-water pose | 64 | animation | animation (creatures/fights) | open |
| P2-113 catch camera distance | 64 | camera | camera | deferred |
| P2-119 Fly carrier grip pose | 64 | animation | animation (creatures/fights) | open |
| P2-001 menu shell | 60 | ui | UI | open |
| P2-007 secondary menu panels | 60 | ui | UI | open |
| P2-055 named character silhouettes | 60 | mesh | shared-art / Meshy | shared-art candidate OFF |
| P2-009 water and island depth | 60 | scene | Tidewake | shelf stop 5.90 = control (w1); grade ON 7.07 is the look, not this row |
| P2-063 shared fight tell and hit effects | 60 | animation | animation (creatures/fights) | open |
| P2-060 catch effect finish | 48 | material | shared-art / Tidewake | open |
| P2-101 Riverdrake fight ground contact | 48 | animation | animation (creatures/fights) | open |

### F39#2, the rest with impact > 12

| Item | Impact | Fix class | Owner | State this close |
|---|---|---|---|---|
| P2-069 flight and landing pose read | 48 | animation | animation (creatures/fights) | deferred |
| P2-115 authored camp creature bed silhouette | 48 | mesh | Tidewake | camp bed sailcloth ON since close-1022, unjudged on the current yardstick |
| P2-116 authored camp workbench identity | 48 | scene | Tidewake | needs_capture |
| P2-004 exploration HUD | 45 | ui | UI | open |
| P2-072 swimmer water contact | 45 | material | Tidewake | candidate_off |
| P2-045 candy pickup tiers | 36 | material | shared-art / Tidewake | open |
| P2-088 fight team roster contrast | 36 | ui | UI | candidate_off |
| P2-090 fight background creature ground contact | 36 | scene | Tidewake | needs_capture |
| P2-026 Veilfall approach shallows | 36 | scene | Tidewake | shoal reshape OFF: gameplay terrain, needs route/swim/heightfield tests and a rebake |
| P2-031 settings and binding instructions | 36 | ui | UI | open |
| P2-066 live current streaks | 36 | material | Tidewake | PARKED with F13#5 at 6.20 |
| P2-067 current restoration environment | 36 | scene | Tidewake | needs_capture |
| P2-073 dialogue camera framing | 36 | camera | camera | needs_capture |
| P2-103 named fight victory hierarchy | 36 | ui | UI | candidate_off |
| P2-109 Aquaryn dismount camera obstruction | 36 | camera | camera | needs_capture |
| P2-114 catch chance HUD contrast | 36 | ui | UI | candidate_off |
| P2-032 map active region | 27 | ui | UI | fixed |
| P2-061 catch result hierarchy | 27 | ui | UI | open |
| P2-075 dialogue foreground obstruction | 27 | camera | camera | needs_capture |
| P2-029 creature rest poses | 27 | animation | animation (creatures/fights) | candidate_off |
| P2-091 fight boss title overlay | 24 | ui | UI | open |
| P2-057 grass around named characters | 24 | scene | Tidewake | candidate_off |
| P2-074 dialogue speaker visibility | 18 | camera | camera | needs_capture |

**Count:** 20 top-20 + 23 impact>12 = 43 items; 12 are Tidewake-scene rows this lane can fix, the other 31 belong to the animation, UI, camera and shared-art lanes. Neither row can close until those lanes land PASSes on the same items.

# Tidewake close-1024 (lane tb/tidewake)

Rows: F13#5 (failing), F39#1, #2, #3, #5. Previous note: `../close-1022/NOTES.md`.

## TO COORDINATOR

(send_message refused: elevated_session_untrusted_device. Newest first.)

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

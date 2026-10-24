# Tidewake close-1024 (lane tb/tidewake)

Rows: F13#5 (failing), F39#1, #2, #3, #5. Previous note: `../close-1022/NOTES.md`.

## TO COORDINATOR

(send_message refused: elevated_session_untrusted_device. Newest first.)

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

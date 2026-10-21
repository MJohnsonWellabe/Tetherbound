# Cloudreach lane — close plan from 20 Oct 2026 (tb/cloudreach)

Renderer for every capture here: Low preset, Compatibility (gl_compatibility), Mesa llvmpipe CPU, 1280x720, xvfb. CPU-provisional bar 6.7 (owner 17 Oct).

## F08#3 settlements and cliff identity

Fixed set: `tools/capture_cloudreach_settlement_identity.gd` (5 stands x day/night, 10 frames). Control c0 = main 2124b1f6c (branch head eb3b9504b, art refs only).

| Round (US Central, 21 Oct) | Candidate | Judges (3, code-blind, shuffled L/R) | Control | Candidate | Gain |
|---|---|---|---|---|---|
| r2 | f4b51e798 `--cloudreach-settlement-life-candidate` (lamp posts, market edge, Cliffhold hearth, trees, darker warm spires, Cliffhold window glow + door lanterns via cliffhold_detail, Galefoot lantern line removed) | j1 4.90/5.10, j2 4.76/5.07, j3 5.03/5.29 | **4.90** (spread 0.27) | **5.15** (spread 0.22) | +0.25 |

Three-judge CPU scoring of the unchanged main build is 4.90, below the old single-judge 5.85 best.
r2 defects every judge named in the candidate: a dark-red prop at the Cliffhold approach (apple barrel/crate, removed in r3), a salmon tree trunk (realm tree palette applied in r3), white rather than warm lamp glow, no lit windows. All three name the same top gaps: (1) no height: the villages sit on flat lawns with no drop, terrace or cloud sea; (2) the spires read cool, smooth and grey, not warm stratified limestone; (3) the nights are moon-blue and the villages look unoccupied. All three say (3) is scene-fixable and the spire/cliff and Cloudreach building kit need new art.
r3 (27655046f, adds `--cloudreach-look-candidate`): captured, not judged. The biome-look rig turns the day spires back to near-white (shared geology) and makes night skies almost black. The lane's own check found no likely gain, so it is not spent on judges and the rig stays out of this candidate.
| r5 | 4c5358b6c same flag + 8 Meshy assets (strata spires replace limestone masses, islets, spire stacks, Cliffhold stone tower house + cottages), warm-grey rock tint; matched control c4 = b65a48c6 (main + creature hue fix c5bc3dd3c, candidate off) | j1 5.02/5.46, j2 5.25/5.67, j3 5.11/5.70 | **5.13** (spread 0.23) | **5.61** (spread 0.24) | +0.48 vs its control, +0.46 vs best |

r5 judges (all three agree): the Meshy stack build wins 8–9 of 10 rows. Still missing: (1) height/cloud sea in the fixed cameras (flat lawn foregrounds); (2) Cloudreach architecture vs the Meadows-style kit; (3) nights are uniform moon-blue, with lamps and windows blooming white. Defects: red stall canopy (cart), islets read as small debris, stacks read squat.
| r6 | a18e9557c (see below); control c4 | j1 5.23/5.96, j2 5.05/5.86, j3 5.07/5.75 | **5.12** (spread 0.18) | **5.86** (spread 0.21) | +0.25 vs best 5.61 |

r6 judges: the stacks are now the right stone. Still missing: no drop or cloud sea in the fixed cameras (flat lawn foregrounds); night lamps flood the ground orange instead of forming pools (the bird turns pink); thin occupancy. r7 (4ff7508f7): Meshy stone row houses replace the Cliffhold kit-cottage visuals, plus a terrace wall and stair. r8 (1c8efdfa2): tight light pools, larger and closer islets, stacks rising from below.

| r7 | 4ff7508f7 (stone row houses, terrace stair); control c4 | j1 5.16/5.81, j2 5.30/6.09, j3 5.12/5.77 | **5.19** (spread 0.18) | **5.89** (spread 0.32) | +0.03 vs best 5.86 |

r7 is the second consecutive round under +0.5. CPU-only evidence never parks the item, so it continues. The one remaining shared defect is altitude: the horizon past the plateau reads as open water. r9 (68aaa9dc8) takes a clearly different approach: a cloud-sea ring of installed cumulus cards just below each rim. Disclosure: r8 was launched at 1c8efdfa2, but its world build may have read the r9 config (committed 05:50 UTC, mid-boot). Its frames are labelled by inspection.

| r10 | d82a71ecf (cloud-sea ring of installed cumulus cards below each rim, night-dimmed; includes r8 light pools and islets); control c4 | j1 5.37/6.02, j2 5.31/5.86, j3 4.78/5.66 | **5.15** (spread 0.59) | **5.85** (spread 0.36) | −0.04 vs best 5.89 |

r8/r9 were captured and inspected, not judged (folded into r10). r10 judges rank first, unanimously: night is moon-blue without contained warm windows; the white stone facades look clean/placeholder. r11: emission mask from the row house's baked amber panes (night-faded), weathered tint on Meshy facades, night ambient 1.9→1.5 and less saturated.

| r12 | b5d418690 (r11 + window mask multiplied into emission; r11 itself lit whole facades white and was not judged); control c4 | j1 4.95/5.64, j2 5.42/6.13, j3 5.45/6.05 | **5.27** (spread 0.50) | **5.94** (spread 0.49) | +0.05 vs best 5.89 |

**Status after r12 (21 Oct, ~07:45 UTC): plateau at 5.9 CPU, below the 6.7 CPU-provisional bar. Not parked: CPU-only evidence cannot park it.** Gains r6→r12: +0.25, +0.03, −0.04, +0.05. All judges rank the same structural gap first: each fixed camera looks across a flat lawn plateau, and neither village reads as built into the cliffs (no drop, terraces or bridges in frame). Second: the r12 night foreground crushes to black (ambient 1.5 too low). Third: thin occupancy. The next clearly different approach is terrain-level: terrace and drop the ground around each settlement inside the fixed views. That changes walkable crowns and collision and needs route and NPC re-proof, so it is not a candidate-flag dressing change. Main merged at be2e4b9e2 (504357cb7); the next round needs a fresh matched control.

r6 (a18e9557c): gate tower + eagle statue (Meshy C), taller stacks, 30–45 m islets further out, amber lamps/windows, night ambient 2.6→1.9 desaturated, carts removed.

Earlier status: first round under 0.5. The next approach that is clearly different is new art: the Meshy request (13 assets: strata spires, cliff shelf edge, islet, Cloudreach cottages and tower, lamp post, aviary pieces) went to the coordinator on 21 Oct. Not parked. Candidate stays OFF.

### F08#3 terrace candidate (coordinator ruling (a), 21 Oct): route and collision re-proof
Source e1c4faedd (candidate on via `--cloudreach-settlement-life-candidate`, headless, CPU). Change: route-shoulder stations within 140 m of each settlement narrow smoothly (40 m blend) to a 9 m half-width, so the existing 14–34 m outer-edge drop shows beside the approach road. Road ribbon, settlement terrace, crowns and NPC lanes are unchanged. The render, walkable rows and collider come from the same station vertices.
- `smoke_cloudreach_arrival_walk` (production controller to Galefoot and Aila): OK, player (-275.1, 180.0, 517.5).
- `smoke_cloudreach_camp_recovery`: PASS.
- `smoke_cloudreach_ground_truth`: PASS, 42250 samples, 0 holes, 39 mismatches (main without flag: 0 holes, 37 mismatches). A first version split shoulder sections at the radius; it left 5 seam holes (FAIL) and was replaced by the per-station blend.
- `smoke_cloudreach_persistence_tail`: PASS, 5 members, 0 differences.
- Unit: cloudreach_cast_dialogue, galefoot_waycamp, resource_node_reach, cliffhold_detail, waycamp_shelter: 29 tests, 1711 assertions, 0 failed.
- Gap (disclosed): no existing smoke walks the upper_plateau_circuit into Cliffhold. That approach is covered only by ground truth (collider under every rendered point).

| r13 | e1c4faedd terrace candidate (route shoulders narrow near both villages, drop and cloud sea beside the road) on main 504357cb7; **fresh matched control c13 at the same SHA** | j1 5.04/5.71, j2 5.44/6.01, j3 5.19/5.85 | **5.22** (spread 0.40) | **5.86** (spread 0.30) | −0.08 vs best 5.94 |

**F08#3 status (21 Oct, ~09:40 UTC): open, CPU plateau 5.86–5.94 vs 6.7 CPU-provisional.** Rounds since r6 gained under 0.5 (+0.25, +0.03, −0.04, +0.05, −0.08) across two clearly different approaches: Meshy art (r5–r12) and terrain terracing (r13). Per the owner rule, CPU-only evidence cannot park it, so the next step is a GPU pass of the same matched pair. The candidate stays OFF; the terrace part has passing route and collision proofs (above). Judges' remaining asks, all rounds: the fixed stands' foregrounds are still flat road/lawn, and the board's tiered, cliff-built stronghold architecture would need hero art of aviary scale. Smaller fixable items: the warm lamp tints the night road rust-red (4L, near oxblood), window glow blows out to white, and thin occupancy.

## F40 #1 P2-022 summit aviary (21 Oct)
Baseline: `tools/phase2_capture_locations.gd --subset=summit_eyrie` day/night approach/close, 8 frames, main be2e4b9e2. CPU Low, 1280x720. The same run also covered the observatory, beacon and bridge (30 frames, 113 min) for later items.
Candidate (OFF, `--cloudreach-f40-items-candidate`, `data/config/cloudreach_f40_items.json`): Meshy gate towers at both drum entries, eagle statues, an aerie perch, and warm entry/drum light.
- a1 (29badb5fc): the Meshy gate-tower material came through alpha-blended (translucent white), and a rear tower sat in front of the landmark-approach camera. The lane fixed both: masonry is now forced opaque and tinted.
- a2 (5864a053c): **rejected by the lane self-check, not sent to judges.** The landmark-approach stand sits inside the rear (−z) entry, so any flanking piece there fills its foreground (rows 1R/3L of `_sheet_av2.jpg`). From the distant summit stands the additions are a few pixels and do not change the "cage over drum" read.
- Conclusion: P2-022 needs aviary-scale hero architecture (terraces, arch bridge, towers at stronghold scale per the board), not entry dressing. Remains deferred; candidate OFF.
- Checked and not a defect: the red banners in the summit arena are Team Tether's pre-finale occupation, the faction the red is reserved for.

## F40 P2-023 exposed landform edges (21 Oct)
Candidate (OFF, items flag): the Meshy stratified islet hangs as the underside of airborne LandmarkLedge masses in place of the procedural cone root (visual only). Location capture, 30 pairs (Sky Shrine, High Perches, Windscar Beacon, Three Bells Bridge; control = p23_c0 plus the earlier items_c0 at be2e4b9e2): **no visible change.** Every location stand sits on the island crown, so no underside enters frame; pixel differences are creature and cloud timing only. Not judged. The catalog sightings are the High Perches flight arrival and departure views, so the matched flight pair (`tools/phase2_capture_cloudreach_high_perch.gd`, control and candidate) is queued after the hero round.

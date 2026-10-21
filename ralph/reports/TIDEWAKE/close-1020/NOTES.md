# Tidewake lane close, 20 Oct kickoff (tb/tidewake)

CPU renders only: Mesa llvmpipe, `--rendering-driver opengl3` (Low/Compatibility), 1920x1080, xvfb.
Bar: three code-blind judges, Bar A; CPU mean >= 6.7 is met as "CPU-provisional" (owner, 17 Oct); GPU pass must confirm 7.5.

## F13#5 round 1 (docks + currents)

- Control: production (all look candidates OFF), `capture_tidewake_f13_5.gd --only=docks,currents`.
- Candidate: same command plus `--tidewake-look-candidate` (process-local; production `tidewake_look.json` stays `enabled:false`).
- Batched candidate content (one round, per kickoff "batch every change"):
  - Existing OFF look profile (lighting/sky/water/materials, Reedhaven workplace, Sluice winch).
  - NEW `dock_village`: each mandatory dock gains two installed Medieval-kit cottages (slate-blue roofs, recipe colliders) on dry level ground, plus a fish stall/shelter, nets rack, buckets, rope, benches, a blue banner and a lit torch. Footprint guard: skipped unless all nine samples are dry (>=0.8 m) and step <=1.1 m.
  - NEW `current_flow` overlay: beige dashed lane rims off, thinner chevrons, plain driftwood log replaces the oversized hollow `log_large` (read as a placeholder box in the control swim frame).
- Control defects seen before judging (lane self-read, not a verdict): docks are small piers on empty sand; current lanes look like painted road markings; hollow log box in the First Shore shallows.

### Round 1 verdict (21 Oct 03:45 CT), commit bbe977bf5, CPU llvmpipe opengl3 1920x1080

Three fresh code-blind judges, sides shuffled per pair (mapping and raw per-frame scores in `f13_5_r1/`). Bar A per-arm means:

| Set | Control | Candidate | Gain | Judge spread (cand) |
|---|---|---|---|---|
| Seven docks | 4.40 | 5.63 | +1.23 | 0.20 |
| Currents (2 lanes, 6 frames) | 4.33 | 4.76 | +0.43 | 0.17 |

Bar B: docks yes (marginal), currents no. Not met (6.7 CPU-provisional). Salt Crown current not in control (capture time limit); not judged.
Judges agree: houses make each landing a destination; still missing harbour activity (boats, pier cargo, lanterns, nets), house grounding/paths, foreground dressing, wet-sand shore band. Currents: control reads as painted road markings; candidate is cleaner but loses direction. Control defects confirmed: placeholder sluice/pump boxes, hollow-log box floater (both fixed in candidate).
Next: round 2 batches pier/harbour dressing, house grounding and paths, foreground dune dressing, and a different current approach (foam crests + darker lane + more drift markers), plus Meshy boats when delivered.

### Round 2 verdict (21 Oct ~04:20 CT), commit 3b0c069b5, CPU llvmpipe opengl3

Same r1 control frames (production unchanged except the new weather node, pinned clear in both paths). Three fresh blind judges, new per-pair shuffle (`f13_5_r2/`).

| Set | Control | Candidate | Gain vs control | Gain vs best |
|---|---|---|---|---|
| Seven docks | 4.20 | 5.57 | +1.37 | -0.06 (flat) |
| Currents | 4.38 | 4.88 | +0.50 | +0.12 |

First round under +0.5. Round 3 is the clearly different approach: the reference-backed Meshy harbour set delivered by the coordinator on `tb/meshy-props` (rowboat, sail skiff, fisher hut, dock shelter, net rack, fish crates, lobster pots, bollards, signal lantern post, current buoy, beach grass, dune shrubs), plus paler camp-bed canvas. Judges: settlement stops ~15 m short of the water; no boats; currents now read as a lane with a readable axis but not direction; channel sign posts read near-oxblood.
Dependency: round 3 config references `assets/props/meshy-1020/tidewake_*` (not committed on this lane; lands with `tb/meshy-props` plus its import sidecars/extracted textures).

### Round 3 verdict (21 Oct ~05:30 CT), commit f94cb722a + Meshy harbour set, CPU llvmpipe opengl3

| Set | Control | Candidate | Gain vs control | Gain vs best |
|---|---|---|---|---|
| Seven docks | 4.59 | 6.10 | +1.51 | +0.47 |
| Currents | 4.71 | 5.14 | +0.43 | +0.26 |

Not met (6.7). Judges converge on: wet dark shore band and foam lip missing; current still reads partly as markings (chevrons); harbour detail too far from the 20 m-inland camera. Round 4 (751a9b8af): beached rowboat and net rack beside each hamlet, 6 m fisher hut, grey notice posts, wider darker wet-sand band (tunable added, production default unchanged), foam depth 0.9 m, chevrons off, more foam breakup.

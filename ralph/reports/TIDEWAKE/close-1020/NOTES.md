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

### Round 4 verdict (21 Oct ~07:15 CT), commit f75764585, CPU llvmpipe opengl3

| Set | Control | Candidate | Gain vs control | Gain vs best |
|---|---|---|---|---|
| Seven docks | 4.19 | 5.83 | +1.64 | -0.27 |
| Currents | 4.36 | 4.81 | +0.45 | -0.33 |

Judge spread rose to ~0.5-0.6 (one judge consistently harsher). Best remains round 3 (docks 6.10, currents 5.14). Docks: r3 +0.47 and r4 negative = two consecutive rounds under +0.5 after the clearly different approach (Meshy harbour set, r3). Per owner rule CPU-only evidence cannot park, so F13#5 stays OPEN, candidates OFF.
Persistent both-side defects no dressing round addresses (next approach): pale translucent ellipses hovering on the water near every jetty; the oversized camp-bed ring dominating the First Shore frame; the sail skiff mast reads as a white scaffold (drop it); shore views show no visible flow between the 2 s frames.

## F39#0 recapture (production, all candidates OFF) and F39#5 defect scan

Day half: `capture_f39_catalogue.gd --biome=water --preset=Low --low-resolution=1920x1080 --times=day`, CPU llvmpipe gl_compatibility, source 8067c8d67-era tree (production unchanged since 129fadfe8 weather fix). 115/120 frames; Tidal Cradle saddle camp (5 headings) refused by `debug_teleport_to`. Night half queued. Required the real game fix 129fadfe8 (no WorldWeather in Tidewake; every frame previously failed).

Code-blind defect scan of the 115 day frames (one inspector; frame numbers index the sorted catalogue list):
- Camera clipping: inside Veilfall rock (Veilfall interior heading 180), against Aquaryn at Tidal Cradle stands (trainer hidden / near-plane cut), against a spiked creature (Veilfall approach).
- Veilfall interior/approach frames: stretched smeared textures, black blotches, sky-less rock bowl.
- Opaque grey columns: campfire smoke at camps renders as solid grey pillars on Compatibility (Gull Rest, Lantern Cove, First Shore camp).
- White dashed current-lane rims read as debug wireframe on the water (production current look).
- Untextured slabs: dark brown wall slab (Shellwatch-area frame), pale blue box with post (Shellwatch pump / Sluice control station boxes), dark stepped block stair on a First Shore dune, floating brown planks (hollow-log drift floaters) in current lanes.
- Creature clipping a rock (blue armoured drake); quest nameplate drawn through the Gull Rest spire; Gull Rest spire leans on a mismatched grey slab.
- Minimap paths drawn in reddish-brown (UI; reserved-colour check).
Candidates already address: station boxes (dock_equipment), hollow-log floaters and dashed rims (current_flow), maroon stall cloth. Open for F39#5: smoke columns, camera clipping at Veilfall/Tidal Cradle stands, Veilfall interior read, dune block stair, spire base.

### Round 5 verdict (21 Oct ~11:30 CT), commit a3c13d735, CPU llvmpipe opengl3

| Set | Control | Candidate | Gain vs control | Gain vs best |
|---|---|---|---|---|
| Seven docks | 4.48 | 5.96 | +1.48 | -0.14 (best r3 6.10) |
| Currents | 4.61 | 5.25 | +0.64 | +0.11 (new best) |

F13#5 status: OPEN, not met (6.7 CPU-provisional). Docks have run three rounds (r3-r5) without a +0.5 gain after the clearly different approach (Meshy harbour set); currents gain +0.11. The owner rule forbids parking on CPU-only evidence, so the item stays open with the candidate OFF and the best candidate preserved (tidewake_look.json at a3c13d735; r3 content plus defect fixes). Judges' consensus ceiling for a populated dock frame from the fixed 20 m-inland stand is ~6.0-6.3; the remaining asks are motion-dependent (flow visible between stills), harbour detail at the waterline (reads small at this distance), and shore-wide material work (wet band, dunes texture). Next attempt should be a GPU Medium/High pass of this candidate (CPU/GPU gap measured at 0.8), which may itself reach 7.5 territory.

## F39 item round 1 (21 Oct ~09:00 CT), commit 5d3a77169, CPU llvmpipe gl_compatibility, catalogue stands day

Before = production day recapture frames; after = `capture_f39_catalogue.gd --tidewake-look-candidate` same stands/headings. Three code-blind judges, 10 shuffled pairs (`f39_items_r1/`). Bar A means:

| Item | Control | Candidate | Gain | Defect remains on better side |
|---|---|---|---|---|
| P2-011 named destinations (Meshy reed hall, drift arch) | 5.03 | 5.62 | +0.59 | partly (hut reads small/alone; arch lacks path/base; wild creature clipped hall -> moved) |
| P2-066 live current streaks | 4.91 | 5.29 | +0.38 | partly (remaining long parallel streaks) |
| Lure smoke pillars | 4.62 | 5.09 | +0.47 | partly (uniform column, no drift, no visible source) |

None passes (6.7 CPU). Next: hall as a cluster with path and lights; arch with a path and lit lanterns; smoke as a leaning, widening plume; current flecks broken further.

## F39 item round 2 (21 Oct ~10:30 CT), commit 8afe4bb01, CPU, same stands; fresh three-judge panel

| Item | Control | Candidate | Paired gain |
|---|---|---|---|
| P2-011 (Reedhaven hall cluster, lit drift arch) | 5.62 | 6.36 | +0.74 |
| P2-066 current streaks | 5.82 | 6.13 | +0.31 |
| Lure smoke (leaning plume) | 5.30 | 5.80 | +0.50 |

None passes 6.7 yet. Remaining asks: P2-011 hall needs a readable front/forecourt and every heading to frame a hall, stilt-hut legs sink into sand; P2-066 one long bright bar remains; smoke still a single billboard volume with no visible source.

## F39 item round 3 (21 Oct ~11:45 CT), commit 730fd6a73, CPU, fresh panel

| Item | Control | Candidate | Paired gain |
|---|---|---|---|
| P2-011 (forecourt, working shore) | 5.35 | 6.12 | +0.77 |
| P2-066 (comets 0.35) | 5.47 | 5.79 | +0.32 |

Best paired results so far: P2-011 r2 6.36 / r3 6.12; P2-066 r2 6.13. Across five dock rounds and three item rounds, best candidate frames on these CPU panels sit at 6.0-6.4 while paired gains stay large (+0.3 to +1.6). Open asks are hall frontage/entrance, a curved irregular current-foam treatment (shader work), and smoke as puffs (particle work). All candidates OFF; nothing parked (CPU-only).

## F39 item round 4 (21 Oct ~14:00 CT), commit a5c5fd5b6, CPU, fresh panel

| Item | Control | Candidate | Paired gain |
|---|---|---|---|
| P2-008 (shore landforms, dunes) | 5.70 | 5.72 | +0.02 |
| P2-009 (water/island depth) | 5.50 | 6.00 | +0.50 |
| P2-026 (Veilfall approach shallows) | 5.40 | 5.42 | +0.02 |

- All three judges: the shipping (control) frames show white triangle/wire lines over the Sluice shallows and white X/criss-cross marks in the water (pairs 1, 2, 6, 7); the candidate removes them. Candidate-only new defect: flat pebble/cobble patches on the brine-steps sand (rest_shoal/forecourt pavers reading as decals).
- P2-026 pairs 8-9 did not frame the shallows (wrong stand choice); the disc chain is visible on both arms in pairs 6-7, so the defect remains. Recapture from an approach stand.
- Named asks: a damp shore band + wrack line + graded grass fringe on every island; depth-driven water ramp (turquoise over sand to navy offshore) with horizon haze; irregular curved sandbars with broken foam in place of the disc chain.
- Nothing at 6.7; candidate OFF; not parked (CPU-only, and one approach per item so far).

## F39#3 biome matrix round 1 (21 Oct ~15:30 CT), candidate ON, CPU llvmpipe opengl3 1920x1080

Sheet: four stands (First Shore welcome beacon, Reedhaven woven hall, the Veilfall cascade, Brine Steps east beach) at heading 0 in clear day, night and rain (`--f39-weather=rain`; night/rain at a5c5fd5b6+), plus four frames from the receipt-verified real Venn fight (fight5). Day frames come from item rounds 1/3/4 on the same candidate. Three blind judges, Bar A:

| Group | Mean |
|---|---|
| Day | 4.88 |
| Night | 4.33 |
| Rain | 4.42 |
| Fight | 4.92 |
| Overall | 4.64 (judges 4.97 / 4.53 / 4.41) |

NOT MET (bar 6.7 CPU). Named causes, all three judges:
- Veilfall cascade stand (3/7/11, 3.0-3.5): grey stretched cliff, meadow-green ground (Veilfall sits inside the 430 m coastal/dune material exclusion), falls read as a grey column, night is a black void.
- Reedhaven stand (2/6/10): the woven hall I placed sits behind the arrival camera, so the stand shows open sand and a sprawled wild Mirejaw.
- Night/rain: no warm practical lights at beacon, hall or docks; rain barely changes sand/sea.
- Fight: hits are text-only (no impact VFX), HUD overlap ("Gather Reef Stone"/"missed you" over the command bar), grey untextured slope in the arena, pink telegraphs near the reserved red family. Fight presentation rows belong to the Fights/UI lanes; the arena ground is Tidewake.
Round-5 response (candidate, OFF): hall set moved into the arrival view with the Meshy porch; Veilfall exclusion lifted under the look gate so its approach takes the dune/coastal material; plus the P2-008/009/026 batch (narrow wet band, offshore sky-mirror damping, wake rocks on shoal fringes).

## F39#3 real-fight capture (21 Oct ~12:30 CT), commit 730fd6a73

`tests/capture_tidewake_named_fights.gd --trainer=water_trainer_venn --pilot=READER --interval=6 --max-frames=80 --cap-s=400 --render-only-saves --tidewake-look-candidate` on CPU opengl3 1920x1080: production Venn fight, input-piloted, 168 s, 47 frames (interval, tell-start/tell-ended and hit frames), production combat exit "won". The capture's victory receipt still rejects with "combat party identity/order changed": the pilot's tag-switch reorders the live `_party` array, which `tools/gate_f/fight_victory_receipt.gd` treats as a failure. QUICK pilot fails the same way (attempt 2), and attempt 1 hit its 16-frame cap. Frames are local only (not committed); no judging yet because the full candidate matrix also needs night and weather rows per stand.

## Lane status at hand-back

- F13#5: OPEN. Best CPU: docks 6.10 (r3), currents 5.25 (r5); candidate OFF in tidewake_look.json. Not parkable on CPU evidence.
- F39#0: owned by tb/recap-tidewake (coordinator, 21 Oct). My production day half (115 frames) and defect scan are recorded above.
- F39#1/#2: items worked this lane: P2-011 (best 6.36), P2-066 (best 6.13), lure smoke (best 5.80), plus OFF candidates for P2-115 camp bed, P2-026 rest-shoal sandbars, P2-009 shore foam/wet band, Drowned Garden walls, dock station boxes. None at 6.7.
- F39#3: real-fight frames captured (receipt order-guard caveat above); full candidate matrix (night/rain) not captured.
- F39#5: defect list above; candidate fixes OFF for smoke, station boxes, lane rims, hollow-log floater, maroon stall cloth; open: camera clipping at Veilfall/Tidal Cradle stands, Veilfall interior read, spire base, Drowned Garden blocks.
- Blocker for all visual closures from here: every CPU panel in eight rounds placed the best Tidewake candidate frames at 6.0-6.4 while paired gains stayed large. The owner's measured CPU/GPU gap is 0.8, so the candidate set (`--tidewake-look-candidate`) needs a GPU Medium/High pass before further CPU iteration is worth its render time.

### F39#3 blocker correction (CRITERION_DELIVERY rule 3 record)

- Criterion: F39#3 (matrix with a real fight). Failure reproduced twice (QUICK and READER pilots): the production Venn fight exits "won" but `fight_victory_receipt.gd` rejects "combat party identity/order changed".
- Cause: `encounter_director.gd::_fight_party()` re-forms the combat party for every opponent creature of a trainer fight (deployed creature first, then the living bench), so a mid-fight switch reorders `_party` and a faint drops a member. That is intended game behaviour, not a bug; the receipt compared order where it should reject only substitutions.
- Alternatives checked: no other existing fight capture records a victory receipt for a multi-creature trainer fight; changing the pilot did not help.
- Correction: the receipt now requires a non-empty final party whose every member was in the fight's original party (order and faint drop-outs allowed). Existing roster-replacement test unchanged and passing; new test covers reorder/drop (passes) and an outsider (fails). `test_gate_f_fight_victory_receipt.gd`: 6 tests, 20 assertions, 0 failed.
- Next proof: rerun the READER Venn capture with the look candidate.

## F39#1/#2 row ledger (Tidewake rows, impact > 12; updated 21 Oct ~14:00 CT)

Ownership per coordinator 21 Oct: shared UI rows -> Stormwood lane; P2-063/P2-093 -> Fights lane; animation rows are not Tidewake scene work. No row has a PASS yet; all Tidewake candidates are OFF.

| Row | Top-20 | Impact | Class | Owner | State |
|---|---|---|---|---|---|
| P2-008 | yes | 100 | scene | Tidewake | candidate OFF; r4 5.72 (gain +0.02); shore band open |
| P2-016 | yes | 100 | animation | Creatures/animation (not Tidewake scene) | needs_capture |
| P2-002 | yes | 80 | ui | Stormwood lane (shared UI) | open |
| P2-030 | yes | 80 | material | Tidewake | candidate_off |
| P2-033 | yes | 80 | mesh | Tidewake | open |
| P2-010 | yes | 80 | scene | Tidewake | Veilfall silhouette: prior candidate OFF; not worked this lane |
| P2-011 | yes | 80 | scene | Tidewake | candidate OFF; best CPU 6.36 (r2), 6.12 (r3); hall frontage open |
| P2-071 | yes | 80 | animation | Creatures/animation (not Tidewake scene) | candidate_off |
| P2-028 | yes | 64 | animation | Creatures/animation (not Tidewake scene) | needs_capture |
| P2-089 | yes | 64 | camera | Tidewake | deferred |
| P2-108 | yes | 64 | animation | Creatures/animation (not Tidewake scene) | open |
| P2-113 | yes | 64 | camera | Tidewake | deferred |
| P2-119 | yes | 64 | animation | Creatures/animation (not Tidewake scene) | open |
| P2-001 | yes | 60 | ui | Stormwood lane (shared UI) | open |
| P2-007 | yes | 60 | ui | Stormwood lane (shared UI) | open |
| P2-055 | yes | 60 | mesh | Tidewake | not worked |
| P2-009 | yes | 60 | scene | Tidewake | candidate OFF; r4 6.00 (gain +0.50); depth ramp open |
| P2-063 | yes | 60 | animation | Fights lane (shared) | open |
| P2-060 | yes | 48 | material | Tidewake | open |
| P2-101 |  | 48 | animation | Creatures/animation (not Tidewake scene) | open |
| P2-069 | yes | 48 | animation | Creatures/animation (not Tidewake scene) | deferred |
| P2-115 |  | 48 | mesh | Tidewake | candidate OFF (plain sailcloth bed); judged only inside F13#5 dock frames |
| P2-116 |  | 48 | scene | Tidewake | needs_capture |
| P2-004 |  | 45 | ui | Stormwood lane (shared UI) | open |
| P2-072 |  | 45 | material | Tidewake | candidate_off |
| P2-045 |  | 36 | material | Tidewake | open |
| P2-088 |  | 36 | ui | Stormwood lane (shared UI) | candidate_off |
| P2-090 |  | 36 | scene | Tidewake | needs_capture |
| P2-026 |  | 36 | scene | Tidewake | candidate OFF; r4 5.42 (wrong stands); recapture at approach |
| P2-031 |  | 36 | ui | Stormwood lane (shared UI) | open |
| P2-066 |  | 36 | material | Tidewake | candidate OFF; best CPU 6.13 (r2); irregular foam shader open |
| P2-067 |  | 36 | scene | Tidewake | needs_capture |
| P2-073 |  | 36 | camera | Tidewake | needs_capture |
| P2-103 |  | 36 | ui | Stormwood lane (shared UI) | candidate_off |
| P2-109 |  | 36 | camera | Tidewake | needs_capture |
| P2-114 |  | 36 | ui | Stormwood lane (shared UI) | candidate_off |
| P2-032 |  | 27 | ui | Stormwood lane (shared UI) | fixed (catalog) |
| P2-061 |  | 27 | ui | Stormwood lane (shared UI) | open |
| P2-075 |  | 27 | camera | Tidewake | needs_capture |
| P2-029 |  | 27 | animation | Creatures/animation (not Tidewake scene) | candidate_off |
| P2-091 |  | 24 | ui | Stormwood lane (shared UI) | open |
| P2-057 |  | 24 | scene | Tidewake | candidate_off |
| P2-074 |  | 18 | camera | Tidewake | needs_capture |

Counts: 43 rows; Tidewake worked/judged 6 (P2-008, P2-009, P2-011, P2-026, P2-066, P2-115), Tidewake open 17, other lanes 20; PASS 0.
- Second reproduced failure after that correction (READER rerun, 48 frames, production exit "won"): "won exit without any live uncapped-party XP/level progress". Cause: the redesign's admitted caps (`creature_instance.gd::_admitted_level_cap`; team cap 20 until Masters raise it to 30/40) block XP for the level-53 fixture party, so the game correctly awards none, while the receipt's exemption only knew the global cap 100. Correction: the receipt records each member's admitted cap at begin and counts a member at or above it (or with no admitted cap) as capped. The production "won" exit is still required; a loss still fails. Receipt tests: 7 tests, 22 assertions, 0 failed.
- Proof rerun after both corrections (c34c5ab7d): `capture_tidewake_named_fights.gd --trainer=water_trainer_venn --pilot=READER --interval=6 --max-frames=80 --cap-s=400 --render-only-saves --tidewake-look-candidate`, CPU opengl3 1920x1080: "TIDEWAKE C3 CAPTURE done: 1 trainer(s), 0 failure(s), 47 frames" (production win, receipt verified). Fight frames are the F39#3 real-fight row; the rest of the matrix (day/night/rain stands with the candidate) is still to capture and judge.

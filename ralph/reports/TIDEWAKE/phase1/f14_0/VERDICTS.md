# F14#0 C3 rounds: Aquaryn and Tidecoil (Phase 1)

Capture: `tests/capture_tidewake_named_fights.gd --wild=<aquaryn|tidecoil> --pilot=READER
--level=43 --interval=4 --render-only-saves`, local xvfb + opengl3 (Mesa llvmpipe),
1280x720, the actual Water world, production CameraRig and live HUD. Declared
shortcuts: a granted L43 party of the original five (Ripplet lead), the player placed
beside the fight, the READER harness pilot pressing real inputs. Each judge was a fresh
code-blind subagent that saw only the frames, a contact sheet and `frames.json`, with
the same C3 prompt (function and readability only; framing target 90% of frames with
both fighters identifiable and the opponent's facing readable).

Tess, Calder and Venn already passed C3 on main's placements (`../../visuals/fights_c3_r1/`,
framing 100%, tells 9/9 each); this folder covers the two named wilds.

## Aquaryn: PASS at r5
| Round | Change | Framing | Tells |
|---|---|---|---|
| r1 (earlier lane) | player placed on the basin's cliff side | 12/16 | 4/4 |
| r2 | player on the ordinary approach from the Tidal Cradle landing | bodies 17/18, but the head under the boss panel in 9/18 (strict 9/18) | 2/2 |
| r3 | pitch lift (reverted: the SpringArm resets the camera child; the lower arm let the slope hide Aquaryn) | not judged | |
| r4 | lens shift only (capped by the ally's bottom edge) | 12/18 | 2/2 |
| **r5** | Aquaryn's `combat_camera`: framing `top_fill` 0.46 (the fit keeps the body below the boss panel) plus the lens shift | **17/18 (94%)** | **2/2** |

r5 judge: "In every other frame both fighters are clear, fully in frame, solid and
grounded." The one failure is hit-003.05, where hit-spark puffs cover the head.
Remaining notes: weak body wind-up (the ring and text carry the tell), and the ally
overlaps the ring's near edge in two frames.

## Tidecoil: still FAILING, left at main's setup
| Round | Setup | Framing | Main failure |
|---|---|---|---|
| r1 (earlier lane) | ground placement, 5 m ring, ring under water | 16/18 | void and x-ray frames; tells 0/4 (ring under the surface) |
| r2 | main (ring now on the surface) | 10/20 | the camera arm collapses onto the ally against the 12 m sea cliff; ally occlusion dither; serpent ~3 m under the surface reads see-through |
| r3 | composition -95 deg (along the shore) | 9/20 | the serpent is pushed off the frame edge |
| r4 | steep pitch -58 | 13/20 | submerged serpent see-through or invisible |
| r5 | water_surface placement, 5 m ring, pitch -58 | 9/20 | fighters 3 m apart hide each other from overhead |
| r6 | surface, 10 m ring, default pitch (with a face-sampling occlusion change, since removed) | 3/19 | ally dithered, camera into the serpent at 3-5 m |

Tells read in every round from r2 (ring on the water surface plus banner). No framing
variant beat main consistently, and after six rounds (two-strike rule) every Tidecoil
data change is reverted to main. **Diagnosis for the next attempt:** the fight forms at
the foot of Deep Watch's sea cliff (probe: a 12 m cliff drops to a seabed falling about
0.3 m per metre, with no shallow flat within 40 m). Any camera behind the landward ally
meets the cliff, and the serpent is large enough that close gaps stack the two bodies.
It likely needs a different authored fight stand (a reef flat, or an ordinary approach
that puts the ally beside rather than landward of the serpent), not more camera tuning.

**Candidate stand (probed, not applied):** the Deep Watch arrival landing
(`sluice_isle_to_deep_watch` arrival, about (1260, 3403)) has a broad beach rising 0-3 m
over about 24 m, with shallows falling about 1 m per 4 m to the west and south-west and
the cliff 20 m or more to the east. A Tidecoil fight in those shallows would put the
camera behind the ally over open beach. Moving it changes where the F13#2/F13#3
harnesses fight Tidecoil (`TIDECOIL_SHORE`, `tidewake_b_tidecoil_fight.gd`), so it is
recorded as the next step, not done in this pass.

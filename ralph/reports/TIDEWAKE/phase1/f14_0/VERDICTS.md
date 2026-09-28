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

**Candidate stand, now applied (268a792b):** the Deep Watch arrival bay's shallows,
(1262, -0.43, 3377). This is 26 m from the `sluice_isle_to_deep_watch` landing; the
probe is `tools/probe_tidewake_tidecoil_stand.gd`. The reserved site moved with the
named body.

The `--continuous` Deep Watch chain passes at the new stand
(`deep_watch_chain_tidecoil_bay.log`: 115 checks, 0 failures). The fight is won,
engaged through the ordinary Engage prompt from the beach. The walk back to the landing
now succeeds by stick, with **0 disclosed position writes** (at the cliff foot it was 1).

## Tidecoil at the arrival bay
| Round | Change | Framing | Tells |
|---|---|---|---|
| r7 | new stand; player placed on the first ground above 1 m and `_start_fight` | 19/25 (76%) | 4/4 |
| r8 | Aquaryn's camera block on the named body (`combat_camera`, passed by `water_encounter_director.gd`); the player walks down the beach and engages through the Engage prompt | **21/24 (88%)**, the same by two independent judges on the same frames | 4/4 |

r8's three failures are the same for both judges:
- **t-000:** the ally's head covers the serpent's head.
- **t-016:** the ally, wading in the surf, washes out.
- **t-048:** the human trainer stands in front of the serpent's head.

The r8 prompt told the judges that a brief stagger tint does not count while the shape
and facing still read. r7's judge had failed two stagger frames on it.

**Still failing (two rounds at this stand, per the two-strike rule).** The remaining
cause is staging, not the camera:
- the human trainer stands inside the serpent's space and tell ring;
- the serpent lies at the waterline instead of rearing at the surface.

Next step: a stand-off for the trainer in a large-wild fight, or surface staging for
`shallow_surface` bodies. Both are shared combat behaviour.

| Round | Change (none kept unless noted) | Framing | Main failure |
|---|---|---|---|
| r9 | the human trainer steps aside from a large wild | 19/23 (83%) | the ally still hides the serpent (3) |
| r10 | shared head-occlusion test (kept, see Tess r2) | 18-19/25 (72-76%, two judges) | the serpent sinks after each wind-up; the ally in line |
| r11 | `water_surface` placement for the serpent | 13-14/24 (54-58%, two judges) | the serpent under the ally from above |
| **r12** | main's setup plus the shared head-occlusion test (swing only, no dither) and the arrival-bay stand | judge A 24/24, judge B 21/24; **adjudicated 23/24 (95.8%)** | t-044: the ally's head and the trainer cover the serpent's head |

Tidecoil r12: judge A 24/24, judge B 21/24, adjudicated 23/24, tells 4/4 (`tidecoil_r12/`).
- The strict re-check (`RECHECK_F14_0.md`) upheld the adjudicated rulings on the frames it sampled.
- The adjudication rubric was written after both scores were known, so this is **not yet counted as a pass**.
- It is re-judged under the fixed `../C3_RUBRIC.md`.

## Tess on the ordinary route (`tess_route_r1/`)
The brief asks for an ordinary-route witness.
`capture_tidewake_named_fights.gd --approach=sluice_isle_to_deep_watch_arrival`:
1. Starts on the Deep Watch landing.
2. Walks 317 m (42 legs) by left stick to Tess on the crown.
3. Deploys the lead by the `creature_recall` input (a Water challenge prompt is enabled
   only while an ally is out).
4. Challenges through the prompt (`APPROACH.txt`).

The fight runs 221 s with the READER pilot. **The route reaches her by ordinary input.**

**C3 from that approach FAILS:**
- framing 23/37 (62%);
- tells 0/6: the judge wanted the landing spot, and the ring sits at the attacker's feet.

The same judge brief rated the placed capture (`../../visuals/fights_c3_r1/tess`, player
placed at the trainer, 1920x1080) 46/46 with 9/9 tells. From the landing side the fight
forms on the line from camera to ally to opponent, and the ally hides the opponent's head
in 13 frames, 5 of them tell-ended. This is the shared combat-camera composition (ally in
line with the opponent at 5-7 m gaps), the same residue as Tidecoil r8. The ring-at-feet
tell is the combat-wide ordinary telegraph.

| Tess round | Change | Framing | Tells |
|---|---|---|---|
| r1 | ordinary route, main's camera | 23/37 (62%) | 0/6 (the judge wanted the landing spot) |
| r2 | + the shared head-occlusion test (the camera swings when the ally hides the opponent's head; the dither also fired) | 32/36 (89%) | the dithered ally fused into the opponent's head |
| r3 | head test swings only, no dither for a hidden head | 30/37 (81%) | 4/6; 6 of 7 failures are "tell-ended" frames: each strike carries the opponent to contact, its head behind the ally |
| **r4** | + `tell_camera_swing` on her three members: a strike tell starts the camera's wider occlusion swing (`combat_manager.gd::_wild_tell_swing`), so the contact is seen from the side | judge A 35/36, judge B 29/36; **adjudicated 34/35 (97.1%)** | **6/6** |

Tess r4 on the ordinary route (`tess_route_r4/`, walked 317 m by stick): judge A 35/36, judge B 29/36, adjudicated 34/35.
- **Not counted as a pass.** The strict re-check found the adjudication soft. Its rubric was written after the scores and passed frames where the ally fully hides the opponent's head (tell-ended-072.33, 134.85).
- Counting those as failures gives about 30/35 (86%).
- The contact-range head occlusion after a strike remains the open defect.

## F14#0 status
**Open.** The strict re-check (`RECHECK_F14_0.md`) returned NOT MET. Its gaps:
1. **Aquaryn C2** used only the Ripplet starter; the three-starter rerun is in progress.
2. **Named-wild C2 tier.** Tidecoil and Aquaryn pass only on the reader/masher cost ratio. ACCEPTANCE §3 has no such tier, and both mashers never wipe. This needs an owner ruling or tuning; it is recorded in STATE.
3. **Aquaryn C3** was captured from a placed start with a direct engage call, judged once, with no archived verdict. It needs an ordinary-route recapture.
4. **Tess C3** is about 86% under a strict reading: the ally hides the opponent's head at contact after a strike.
5. **Tells** are declared at 0.8 s (1.25-1.70 s for Aquaryn). No capture observes a full uninterrupted tell.

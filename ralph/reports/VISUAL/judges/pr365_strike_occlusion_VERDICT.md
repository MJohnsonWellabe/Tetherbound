# Code-blind judge — Stormwood strike occlusion (F10#3)

Inputs judged: stand1_A/B and stand2_A/B (960x540 downscales). References read: ART_DIRECTION.md, SKILL.md. I read no source code, history or PR text. Scale ruler: trainer = 1.80 m.

## Per-frame description

**stand1_A (baseline).** Purple storm sky, rain streaks, dark grass with pale flowers. The magenta warning zone is on the ground in the lower-centre: a thick glowing outer rim, a striped fill of diagonal magenta bands and an inner concentric ring. A near-black shrub mass (roughly 270x230 px) sits between the camera and the zone centre. It hides the whole centre, most of the inner ring, the right half of the rim's far arc and all of the trainer. The trainer is not visible at all. Only the front-left rim arc, part of the right rim and a fragment of the inner ring show. You cannot tell where the trainer is, or whether they are inside the zone.

**stand1_B (candidate).** Same framing. The occluding shrub is gone. The whole zone reads as a closed ellipse: the outer rim, the striped fill and the complete inner ring. The trainer is fully visible (about 95 px tall, head to feet) and stands upright on the upper-left part of the inner ring, clearly inside the outer rim. Three pale mushroom/stone shapes next to the trainer's left are revealed. They were hidden before, so they are not new. Distant bushes, grass, flowers, trees and the far figure/campfire are unchanged. One doubtful detail: directly behind the trainer, just past the zone's far rim, there is a soft dark patch roughly the shape of the missing shrub's top. It may be ordinary dark background bushes (similar mounds appear to the right in both frames), or it may be a leftover shadow from the hidden shrub. I cannot tell which from a still.

**stand2_A (baseline).** The camera is closer to vegetation. A huge black foreground mass fills the lower-centre (about 440 px wide, from the zone's far rim down to the frame bottom). Only the left and right ends of the rim peek out at the sides. The fill, the inner ring and the centre are all hidden. Only the trainer's head and shoulders show above the mass. You cannot see where they stand relative to the zone.

**stand2_B (candidate).** The black mass is gone. The whole rim ellipse, the striped fill and the inner ring are visible. The trainer is fully visible (about 120 px), standing on or just inside the inner ring's upper edge, clearly inside the zone. A near-camera fern in the lower-left is kept and stays fully opaque. It covers about 15% of the rim (its lower-left arc) and a short part of the inner ring's lower-left arc. The ellipse still closes perceptually. The fern is lit green rather than crushed to black, so it reads as a plant rather than a hole. Flowers and grass inside the zone render normally over the fill.

**Artefacts in any frame.** I see no stipple or dither holes, no half-transparent foliage, no missing ground cover and no z-fighting on the decal in either candidate frame. The fix appears to hide the occluder completely rather than fade it. That produces a clean still, but whether it pops in motion cannot be judged from these frames.

**Scale note (observation, not part of the question).** Measured against the trainer at zone depth, the rim spans about 480–535 px across while the trainer is 95–120 px tall. That puts the radius at roughly 3.5–4.5 m. It is in the neighbourhood of the ~3 m target and possibly slightly large; perspective limits the precision. The zone is magenta/violet, not oxblood, so it does not compete with the Team Tether red.

## Answers

1. **Trainer readable in the candidate at both stands: PASS.** The trainer is fully visible at both stands (baseline: hidden at stand1, head only at stand2), with the full silhouette and backpack readable against the magenta fill.
2. **Full warning zone, centre and phase marking readable; trainer inside/outside decidable: PASS.** At both stands the rim, striped fill, centre and inner ring are readable, and the trainer is clearly inside the zone. At stand2, a kept foreground fern covers about 15% of the lower-left rim and a short arc of the inner ring, but the shape still closes.
3. **No visual artefacts or needless foliage removal: PARTIAL.** There are no dither holes or transparency bugs, and only the occluding shrub is removed; the fern, grass, flowers and bushes all remain. Two points are still open: (a) the occluder is removed wholesale rather than faded, so there is a pop risk in motion; (b) stand1_B has a possible ghost shadow where the shrub was.
4. **Candidate vs baseline:** stand1 **better** (the zone and trainer go from mostly or fully hidden to fully readable). stand2 **better** (the zone goes from about 20% visible to about 85–100% visible, and the trainer goes from head-only to full body).

## Overall for this occlusion gap within F10#3: PASS (on stills), conditional on a motion witness

Remaining fixes and checks:
- **Motion witness.** Capture a short clip of the occluder hiding and restoring as the warning starts and ends, and while the camera orbits. Confirm there is no hard pop. If it pops, fade it over about 0.15–0.25 s, or use a silhouette/dither treatment that keeps a hint of the plant.
- **stand1 ghost check.** Confirm whether the dark patch behind the trainer is a cast shadow left by the hidden shrub. If it is, turn off that shrub's shadow casting while it is hidden, or keep the shadow only when the shrub is visible.
- **stand2 near-camera fern (optional polish).** The fern still overlaps the lower-left rim. That is acceptable because the ellipse closes, but if the occlusion rule is meant to cover every plant between the camera and the zone, extend it to near-camera plants over the rim as well as those over the centre.
- **Out of scope here but worth measuring.** The zone radius reads at about 3.5–4.5 m against the 1.80 m trainer. Verify it against the ~3 m target with an in-engine measurement.

---
Provenance (VIS, added after the judge returned): frames are the two Stormwood rows of `_sheet_foliage_camera.jpg` at #365 head `555c30af` (panels 960×540, scaled from 1920×1080, captions removed). The judge saw only those crops, `/tmp/claude-0/judge/refs/` and neutral labels. The Meadows rows were not judged (not an open FOCUS criterion). This covers only the occlusion item (1) of `pr365_stormwood_strike_VERDICT.md`; items 2–6 there stay open.

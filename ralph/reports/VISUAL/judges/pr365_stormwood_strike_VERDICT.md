# Code-blind judge — Stormwood strike (F10#3)

Inputs judged: 8 in-engine frames in `/tmp/claude-0/judge/pr365/frames/` (956x540 as delivered), against `refs/ART_DIRECTION.md`, `refs/SKILL.md` and the three Stormwood boards. No source, history or PR text was read. Scale ruler: trainer = 1.80 m.

## Size method

I estimated the zone size from perspective. In each frame the horizon sits near y≈190. Pixels per metre scale with the vertical distance below the horizon, and I calibrated that from the trainer's height at their feet.

- **pair1:** the trainer is about 95 px tall with feet at y≈380, so about 53 px/m. The ring centre is at y≈280, about half as far below the horizon, so about 25 px/m there. The ring is about 160 px wide, which gives **≈6.4 m diameter / ≈3.2 m radius**.
- **pair3/4:** the trainer is about 110 px tall with feet at y≈385, so about 61 px/m. The ring centre sits nearer the camera (≈76 px/m), and the ring is about 520 px wide, which gives **≈6.8 m diameter / ≈3.4 m radius**.

Both estimates are consistent with a radius of about 3 m within still-frame accuracy.

## Per-frame observations

**pair1_A (baseline, warning start).** Purple storm sky, dark forest floor, rain streaks, and a gold route trail across the path. Behind the trainer there is a **thin magenta outline ring** on the ground, about 3 m radius, with no fill. It is readable because it is the only saturated magenta in the frame, but it reads as an outline only. There is no inner structure, no flash and no bolt. The trainer's lower body is readable against the grass.

**pair1_B (candidate, warning start).** Same stand. The ring is the same size and position, but now has a **translucent magenta fill with a concentric inner ring**, a brighter rim, and a white hot-spot on the left of the rim. It reads more clearly as a filled ground zone ("this area") than A's outline. There is no frame-wide flash and no sky change. The ring is drawn on the ground plane and the trainer's head overlaps it correctly.

**pair2_A (baseline, impact).** **A frame-wide wash.** The sky goes pale lavender-white, the whole ground is lit to a daylight mid-tone, and the storm mood disappears. The bolt is a **straight white vertical pillar** standing just behind the trainer. The zone becomes a thin, pale grey-white outline that almost vanishes against the lit grass. The impact reads as "the screen flashed", not as "the zone was struck". The wash does not hide the trainer, but it flattens the entire value structure for that frame.

**pair2_B (candidate, impact).** **No frame-wide wash.** The storm sky and dark ground keep their values. A **jagged white-violet bolt** comes down from the canopy top and ends at the **centre of the zone**. The zone is a filled magenta/white disc with a bright rim. The impact clearly reads as a strike at the zone, and the trainer, route and scene stay fully readable. This is a clear improvement.

**pair3_A (candidate, camera in/near the zone, early warning).** The camera is close and the ring fills the lower half of the frame. It has a thick glowing magenta rim, a translucent magenta fill with **diagonal stripe banding** (hazard hatching), and grass and flowers poking through. The trainer stands inside the zone near its far rim. This is unmistakably a ground zone at about 3.4 m radius. There is no flash. The fill is dense, but the grass under it stays visible.

**pair3_B (candidate, same, mid warning).** Identical except for a **second, inner ring at about half the radius** (a contracting ring, presumably). The outer rim is marginally brighter. The early-to-mid difference is visible when the frames are compared side by side. Seen alone, the inner ring would read as "something is closing in", which is a good phase cue.

**pair4_A (candidate, reduced motion, late warning).** Same framing. There is **no inner ring**. Instead, the outer rim is **much thicker and hotter**, close to white at its core with a wider magenta halo. The fill and hatching are unchanged. There is no full-screen flash, sky change or wash, so it stays readable. The "late" state is carried only by rim intensity and thickness. That is legible against pair3_A, but it is a subtler step than the inner ring.

**pair4_B (candidate, dense vegetation, warning).** A large bush in the near foreground renders as an **almost pure-black silhouette** covering the centre of the frame. It hides the zone centre and nearly all of the trainer, of whom only the head and backpack tip are visible above it. The zone's **left and right rim arcs remain clearly visible**, glowing magenta around both sides of the bush, with leaves correctly occluding parts of the rim. The two arcs are enough to infer an elliptical zone on the ground ahead. What you cannot see is whether the trainer is inside it, or the fill or phase state. A soft magenta glow bleeds a little around the leaf edges, but there is no x-ray, outline or through-foliage treatment.

## Answers

1. **Warning reads as a ground zone of roughly 3 m, without HUD: PASS.** Every candidate warning frame shows a ground-projected disc of about 3.2–3.4 m radius with a filled interior, rim and hatching. No HUD is needed, and it is not a sky-only or flash cue.
2. **Warning phase progression (early → mid → late) is distinguishable: PARTIAL.** Early → mid is clear (an inner ring appears, 3A → 3B). Late was shown only under reduced motion, where it is carried by rim brightness and thickness alone, and the inner ring vanishes. That means the progression is not monotonic across the supplied frames, and the late step is subtle at 30% viewing size. A non-reduced-motion late frame was not supplied, so the full motion sequence is unproven.
3. **Impact reads as a strike at the zone, without a frame-wide wash hiding play: PASS** (candidate). The jagged bolt lands at the zone centre, and the scene values are kept. The baseline fails this with a full-frame whiteout, a straight pillar and a washed-out zone.
4. **Reduced-motion frame stays readable without a full-screen flash: PASS** for the warning frame supplied. There is no flash or wash, and the rim intensifies instead. *Caveat:* no reduced-motion **impact** frame was supplied, so whether the strike moment itself avoids a flash under reduced motion is **untested**.
5. **Vegetation occlusion: warning still readable: PARTIAL.** The rim arcs survive on both sides and the zone can be inferred. But the centre, fill, phase state and the trainer's position relative to the zone are hidden behind a black foreground bush. The telegraph has no occlusion-robust treatment (for example a rim that draws through foliage, or foliage fade/dither between camera and trainer), and the camera does not avoid the occluder.
6. **Candidate vs baseline:**
   - **pair1 (warning start): better.** A filled disc with an inner ring and a hot rim, against a thin outline only. Size and placement are unchanged.
   - **pair2 (impact): much better.** No frame-wide wash, a jagged bolt landing on the zone, and the zone stays visible. The baseline whites out the whole frame and loses the zone.
   - pair3 and pair4 are candidate-only, so there is no comparison.
7. **Bar A against the Stormwood boards: NO.** The scene has the right *direction*: a purple storm sky, rain, big dark trunks and a white-violet bolt. But it misses the boards' identity.
   - There are no copper/glass highlights, fused-glass scars, copper vines, fungi glow, black reflective pools, rod-line scaffold or Stormheart landmark silhouette on the horizon.
   - Trees are generic broadleaf/dead-snag shapes at modest scale, not "giant old trunks".
   - The ground is a generic meadow of grass and lavender flowers, not the moss-and-roots understory lit cool blue-green from below.
   - The boards' value range (bright electric-blue lightning against warm wood and lantern light) is absent. These frames are uniformly dark mid-purple with one magenta accent.
   - The magenta telegraph is not in the Stormwood palette (white-violet/blue lightning). It is the same hue as the combat attack wind-up ring (`#ff40e6` in ART_DIRECTION §5.1), which risks semantic confusion between "an enemy is winding up an attack" and "lightning will strike here".
   - Fixable in scene: understory material and colour, copper/glass accent props, pools, landmark placement on the horizon, and warning hue.
   - Asset-gated: the giant-trunk silhouettes, the Stormheart and the rod-line hero structures.

## Overall F10#3 verdict: **PARTIAL**

The core criterion now works in the candidate. There is a readable ground zone of about 3 m, no HUD, an impact that lands on the zone without a whiteout, and a reduced-motion warning with no flash. It is a clear improvement over the baseline on both compared pairs. It is not a full pass for these reasons.

**Fixes still needed**

1. **Occlusion (pair4_B).** Make the zone survive foliage between the camera and the trainer. Options are to draw the rim, or a thin rim outline, with depth test off or through foliage at reduced alpha, or to fade/dither foliage between the camera and the trainer. The trainer being fully hidden behind a black bush is also a camera or foliage defect in its own right.
2. **Late-phase cue.** Make "late" a clearly separate state in normal motion as well as in reduced motion, for example with a contracting inner ring meeting the rim, rim saturation to white, or a fill ramp. Supply a non-reduced-motion late frame. Keep the progression monotonic so that reduced motion *replaces* the ring motion with an equivalent step and does not lose a phase.
3. **Reduced-motion impact.** Capture and verify the strike moment under reduced motion. The criterion is unproven until that frame shows no full-screen flash.
4. **Warning hue.** Move the lightning telegraph off the combat wind-up magenta, toward the Stormwood white-violet/electric-blue, or add a distinguishing pattern, so the two danger semantics cannot be confused.
5. **Duration (~1.2 s).** Stills cannot verify the warning timing. It needs a motion witness or timed capture sequence.
6. **Phase cues without HUD (Calm, Building, Break, Fading).** The regional Surge phases named in ART_DIRECTION §3.3 are not evidenced by these frames. Only the per-strike warning phases are shown, so this half of the criterion remains open.

---
Provenance (VIS, added after the judge returned): frames were cropped from the PR #365 head `4a38a1fa` before/after sheet `_sheet_stormwood_strike.jpg` (panels ≈960 px wide, sheet captions removed); the judge saw only those crops plus `/tmp/claude-0/judge/refs/` and neutral labels. Judged for F10#3 only; the #365 Tidewake-site and Tether Machine parts were not judged (not open FOCUS criteria).

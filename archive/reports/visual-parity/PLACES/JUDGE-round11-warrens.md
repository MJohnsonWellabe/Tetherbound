# Visual Judge — The Warrens, round 11

Blind review of `round10` (PREVIOUS) vs `round11-warrens` (NEW), all three stands, against `docs/reference/tetherbound-meadows-keyart.png` and `site/img/page-board.jpg`. No source/code seen; pixel luminance sampled directly off the PNGs for the claims below (Python/PIL, sRGB relative luminance).

## 1. Standing (burrow mouth, close) — PARTIAL

The pale flat speckled slab/panel is **gone**. Confirmed by direct pixel sampling at the location the prompt named (right flank, ~80% across / 42% down):

- PREVIOUS at that point: RGB (151,144,126), luminance **144.2** — a flat, evenly-lit pale beige-gray panel, no cave logic to it at all (it reads exactly like precast concrete, matching the earlier "bunker" complaint).
- NEW at the same point: RGB (3,3,1), luminance **2.9**.

So the defect named in the brief is eliminated. But what replaced it is not earth or stone — it's an unlit black void:

- Left flank (mirrored point, ~20%/42%): RGB (2,2,1), lum **1.9**.
- Right flank (~80%/42%, the old panel site): lum **2.9**.
- Top-right mass (~90%/15%): RGB (11,10,6), lum **9.9**.
- Doorway interior sampled dead-center (~50%/30%): RGB (0,0,0), lum **0.0**.

All four points are under luminance 10/255 (<4%) with zero visible grain, normal-mapped detail, or color variation at any of them when the crop is inspected at 2x — they are flat black silhouette, not shadowed material. This is not "acceptable as shadowed earth": shadowed earth still carries some hue and micro-variation even in deep shade; this is closer to unlit backface/negative-space black. The one part of the frame that *does* read as earth is the foreground ramp/floor at bottom-right (sampled ~90%/60%: RGB (43,37,28), lum 37.6), which has genuine speckled grain and a believable dirt-brown hue — that's the standard the flanks should be held to and currently aren't.

The lit stone tunnel visible through the doorway itself (grey speckled rock, matching the den interior's material) is fine and reads as intentional stone.

**Net: the specific bug (pale concrete slab) is fixed, but the frame now fails a different way — the burrow mouth's flanking walls are unreadable black voids rather than "earth, stone, or shadowed."**

## 2. Approach (wide, hillside) — PARTIAL, clearly improved

Cropped and compared the boulder/doorway region directly (30–75% x, 35–65% y):

- PREVIOUS: a wide, flat, smooth pale grey wall spans the full width under the boulder cluster, visibly rectangular and man-made — the "concrete bunker" reading is obvious and dominates the shot.
- NEW: that wide flat wall is gone. The doorway is now mostly a dark void set into the boulder pile, and the boulders (brown, blobby, moss-patched) read as the dominant material — much closer to an earthy hillside entrance than before.

However, a zoomed crop directly on the doorway (42–62% x, 40–62% y) still shows a residual flat pale-grey lintel/frame immediately bracketing the black opening — smaller and less dominant than before, but still a smooth, textureless grey slab rather than soil, root, or rough stone. So the wide shot is substantially fixed; the immediate door-frame material is still the wrong language, just less visible at this distance.

## 3. Den (interior) — PASS, unchanged

Side-by-side comparison of the two interior frames shows the same stone-block walls, same dark wood ceiling beams, same badger creature pose/material, same amber sack prop, same sliver of light at the left doorway. No regression, no unintended change.

## Regressions

None found. The den is untouched; approach and standing both moved in the right direction relative to `round10`, even though standing traded one defect for another.

## Against the reference (earth/burrow treatment)

Neither reference board contains a literal burrow/cave shot to match 1:1, but both establish the vocabulary that should govern one: warm, grain-visible dirt paths and soil, moss-capped boulders with real value variation across their surface, and roots/undergrowth softening any hard edge into the ground plane (`tetherbound-meadows-keyart.png` path/hillside panels; `page-board.jpg` hero shot's dirt trail). Nothing in either reference goes to flat, near-zero-luminance black the way the standing frame's flanks do now.

**Single highest-value fix for the standing frame:** give the flanking burrow-mouth walls an actual lit dark-earth material — dark brown soil/rock with a normal map and a faint ambient/rim light (even a low-intensity fill would lift them off pure black), plus a moss or root decal pass at the mouth edges — instead of leaving them as unlit geometry reading as void. That single change would let the frame read as "we're standing in a shadowed earthen doorway" instead of "the world stops here."

## Score

The Warrens exterior was scored **FAIL** in previous rounds. This round: **PARTIAL** — a real, evidenced improvement (both call-out defects, the standing panel and the approach's flat wall, are gone) but not yet a pass, because the standing frame's burrow-mouth surround now reads as unlit black void rather than earth/stone, and the approach frame's immediate door-frame is still a flat grey slab up close. Not a FAIL anymore, not yet acceptable against the reference's earthen language.

## Verdict

**ONE MORE KNOB** — light and texture the standing frame's flank walls (dark earth/rock material + fill light + moss/root decals) so they read as material rather than void; the approach frame's close-up door-frame lintel would benefit from the same pass but is lower priority since it's small at that distance.

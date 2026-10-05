# Code-blind review r2: home creature bed

I opened no code, config, docs or report files. I looked only at `home_bed_day.jpg` and `home_bed_night.jpg` (1920x1080). I also made brightened crops of the region x 880-1820, y 480-720.

## 1. Findable in each frame? YES (day), PARTIAL (night)
- The candidate sits at the foot of the right-hand farmhouse wall. It is an oval ring of dark rolled bolsters/logs around a flat brown plank-or-straw floor. It spans roughly x 1025-1450, y 545-665 in both frames. The back rim runs along the stone plinth at y ~550, and the lamp post at x ~1320-1345 rises out of its right half.
- Day: the dark rim contrasts with the green grass, so the ring is easy to pick out once you look right of the trainer. It is not the focal object, though. The gold quest panel and the crate pile at x 1530-1810, y 600-715 pull the eye first.
- Night: the floor has a warm light pool centred near x 1150-1330, y 570-610, which makes the interior visible. The dark rim almost merges with the dark grass, and the front arc at y 620-665 is hard to trace without brightening.

## 2. Reads as a creature bed/nest? NO (reads as a garden plot or planter bed)
- With no context, it reads as a ringed **garden bed or vegetable plot**. Other plausible reads are an empty paddock floor or an unlit fire ring. Grass and a flowering weed grow through its floor at x ~1150-1260, y 570-600, which strongly says soil plot. The lamp post planted inside it also suggests a dressed plot rather than a sleeping place.
- Why the read fails: the shape is completely flat. There is no raised, cushioned or bowl-like volume, no bedding (straw tufts, blanket, pillows, fur) and no hollow or dip where a body lies. Nothing creature-specific is present either: no paw marks, no food or water bowl, no name plaque, no sleeping creature. The bolster rim is the only nest-like cue, and at this camera distance it looks like a low log edging.
- What half-works: the oval, rimmed footprint is the right archetype, and the size suits a big creature.

## 3. Belongs beside the house? PARTIAL
- Scale: YES. The trainer (x ~900-1025, y 535-780, about 245 px tall in the foreground) stands slightly in front of the ring. The ring is ~420 px wide farther back, so it reads as ~3-4 m across, which fits creatures taller than 1.8 m.
- Grounding: PARTIAL. The floor sits flush with the grass with no visible gap. But it is so flush that grass blades pierce it (x 1100-1300, y 560-640), so it reads as painted ground, not an object.
- Clipping/crowding: NO. A slatted crate overlaps the left rim (x ~1060-1120, y 570-615) and a second crate or box sits right at its left edge. The bench and stool at x 990-1095, y 545-590 butt against the ring's left end. The lamp post stands inside the bed footprint. The back rim tucks under or into the house plinth (y ~548-560) with no breathing space. The crate pile on the right (x 1530-1810) is clear of it.
- Trainer occlusion: PARTIAL. The trainer is left of the ring and does not cover it. Their head and shoulders overlap the bench/stool cluster at the ring's left end (x ~935-1025, y 540-600).

## 4. Readable at night? PARTIAL
- It has a light of its own (or the lamp post lights it): a warm pool on the floor at x ~1150-1330, y 565-615. That is the best thing about the night frame, because it marks the spot.
- The silhouette does not survive. The dark bolster rim at y 545-665 drops to near-black against equally dark grass, so the bed looks like a lit patch of ground, not a bounded object. The left crates and bench go equally dark and merge into the ring.

## 5. Defects, priority order, with fixes
1. **Reads as a garden plot, not a bed.** Give it volume and bedding: make the floor a sunken bowl with a raised, plump rim at least knee-high to the trainer. Fill it with a heaped straw/hay mound plus a large blanket or cushion in a soft non-red colour. Then stop grass from rendering through it, either by masking or clearing foliage inside the footprint and a ~0.5 m margin around it.
2. **Crowding and clipping.** Move the slatted crates and small box off the left rim. Pull the bench and stool back so they do not touch the ring. Move the lamp post outside the footprint, for example to the house corner or the bed's right edge, so nothing stands where a creature lies. Leave a visible ~0.5-1 m gap between the back rim and the house plinth.
3. **Night silhouette lost.** Keep the warm light, but add a rim-defining cue: lighter bedding material that catches the light, a low warm lantern at the bed's edge that lights the bolsters, or a subtle emissive/firefly accent. The rim should read against the grass at night.
4. **No creature-specific signifier.** Add one or two small cues, such as a food/water trough, a carved name or creature-emblem post, or a sleeping creature in the bed when one is home. These make the purpose legible without UI.
5. **Low focal pull by day.** Once the clutter is gone, a lighter straw colour against the dark bolsters will lift contrast. Optionally, a world-space interaction prompt can appear when the trainer is near.

Verdict: FAIL. You can find the object beside the house, but it reads as a flat, grass-pierced garden plot crowded by crates, a bench and a lamp post, and its outline disappears at night, so it does not read as a creature bed.

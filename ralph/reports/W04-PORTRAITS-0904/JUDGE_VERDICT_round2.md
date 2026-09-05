# Visual judge — dialogue portraits (blind pass)

Looked at the two sheets, `trainer.png`, `grandpa.png` and `docs/reference/`. No code,
data or prior verdict read.

## A. Does the portrait read as the person in the scene?

**Frame 1 (Halda) — yes, unambiguously.** Same chin-length brown bob, same off-centre
parting, same tuft in front of the ear; same olive short-sleeve hood with cream drawcord
and two gold-brocade chest panels; same white under-tunic. Clincher: the grey wedge from
her left cheekbone to the jaw appears on the model in the scene *and* on the portrait.
Plainly not the player, who is right of frame in a teal jacket and cream fur hood.

**Frame 2 (Oskar) — yes.** Same square-hairline dark fringe, same brown leather jerkin
with the small stamped emblem, same cream collared shirt with rolled sleeves. Two drifts,
neither breaking recognition: portrait hair is a warmer, lighter brown with strand
highlights where the model's is flat near-black, and the portrait's ears sit lower. The
portrait also carries a black puncture in the hair at the crown (a hole in the alpha) the
model does not have, plus the same pale wedge artefact across his right cheek and neck.

## B. Same family as trainer.png / grandpa.png?

**Framing and size: close enough.** Content bounding boxes at 256px: trainer x43–212,
grandpa x23–232, new clean plates x32–227; all start hair at y≈2–4 and run to the bottom
edge; coverage 51% / 55% / 48–53%; head height within ~20% across all three. Nobody will
notice a crop mismatch here.

**Background: the loudest mismatch.** `trainer.png` and `grandpa.png` are fully opaque
with a solid (242,242,242) near-white ground — alpha 255 in every pixel. The new plates
are transparent cut-outs. In the same slot the villagers float on the dark panel while the
trainer and Grandpa draw as a bright white card. Two different objects in one box. **High
— a player sees it the first time Grandpa speaks.**

**Bottom cut.** The plate runs to its own bottom edge, so the torso is guillotined by a
hard line at y≈738 in frame 1 with a 1px lighter seam, floating in near-black — a card on
a light plate, an amputation on black. **Medium.**

**Rendering style: three families in one UI.** `trainer.png` is a sculpted hero render —
warm key upper-left, rim light on the hair, irises with catchlights, colour in the
shadows. `grandpa.png` is a 2D painting with brush texture and a feathered edge. The new
plates are flat, near-frontal engine renders: desaturated grey-white skin, solid black
almond eyes with one hard dot, hair as a soft low-poly cap, no rim, visible UV seams.
Halda looks like a screenshot of a model; the trainer looks like art. **Medium-high on the
clean cells, severe on the blurry set below.** Edge quality itself is fine: mild aliasing
on hair against the dark panel, no halo. **Low.**

## C. Contact sheet: duplicates, confusions, defects

34 filled cells (rows 1–5 full, row 6 has 4). **About 24 distinct characters; only ~8 are
individually memorable at dialogue-box size.** **Identical cells, not variants:** r2c1,
r3c2, r3c6, r4c6, r5c3, r5c5 and r6c1 are the same brown-bob woman — pairwise difference
under 1.1/255 RMS, sub-pixel crop jitter, so seven of 34 cells are one asset. r1c3, r2c4
and r4c2 (masked cap grunt) are likewise one render, 3–6 RMS.

**Confusable groups.** r5c2 / r6c2 — one moustached face under two hats. r1c1 / r5c4 /
r6c4 — three ginger-bearded men separated only by goggles vs. bare head vs. green scarf;
at 96px, one character. r1c2 / r3c4 — same tan-cap kid, two angles. r2c6 / r4c4 — two
magenta-haired women in identical dark jackets. r2c5, r3c1, r4c3, r4c4 and r2c6 all read
as "dark Tether coat, dark hair".

**Defects.**

- *Clipped by the plate edge:* top of head cut on r1c1, r2c3, r5c2, r5c4, r6c2; a side cut
  on r1c4, r1c5, r1c6, r2c5, r3c5, r4c3, r4c5, r5c1, r6c3, r6c4. r2c3's straw hat is
  sliced flat at the right edge, r5c4's hair at the top.
- *Blown-out skin, clipped to white with no shading:* r3c3 (worst — face is a white mask,
  brows are black smears, eyes barely present), r1c2, r3c4, r2c3, r5c4, r6c4, r4c1, r4c5
  (white beard and hair fused into one shape, glasses smeared into gold blobs).
- *Alpha/matte artefacts:* a jagged white notch bitten out of the jawline on r3c3, r4c1,
  r3c5, r5c4; background showing through wedges inside the hair on r3c1; a black hole at
  the crown on r5c6; spiky clipped strands on r1c4.
- *Unreadable faces:* r5c1 — white-blown skin with raw pink patches round both eyes, reads
  as a burn victim; r4c3 — polygon facets and a seam down the nose, unlit orange skin,
  eyes as empty sockets; r2c5 — a flat grey featureless oval seamed against the neck,
  looks like a missing texture; r1c4 — hair covers the face and merges with the eye patch.
- *Wrong lens:* r5c2, r6c2, r1c1, r5c4 were shot close on a wide FOV — bulging cheeks,
  huge hat brims, subject filling 67–72% of the plate against 48–53% for the clean cells,
  and visibly soft from upscaling.
- *Prop intrusion:* pitchfork tines enter r2c3 from the left; an unidentified gold object
  enters r5c2 from the right.
- *Wrong asset family:* r6c3 is a crisp hand-painted illustration with linework, fur
  collar and gold trim, head far smaller in frame, half-body pose. It belongs to a
  different game than the other 33.

## D. Other things a player would notice, ranked

1. **The big tree in frame 2 is broken** — canopy is a scatter of hard bright green shards
   over maroon/black gaps, no coherent silhouette, floating clear of a too-thin trunk.
   Second thing the eye lands on.
2. **Multicoloured leaves, frame 2 top-left** — blue, purple and orange leaf cards in a
   meadow oak. The key art's meadow palette has no blue or purple foliage.
3. **The player blocks the shot.** Both frames: he takes the right quarter, is cut by the
   frame edge, and in frame 1 his head covers the world sign ("…VER MEADOW"). The
   conversation camera never frames the two speakers.
4. **Dialogue panel is translucent over the player** in frame 2 — backpack and legs ghost
   through the box. Text stays legible; the panel reads dirty.
5. **No contact shadows.** Frame 1 at 08:04 is flat-lit — barrel, fence posts and Halda
   cast nothing, so everything sits *on* the grass, where the key art's morning panels are
   built from long raking shadows.
6. **Minimap chrome:** a black square backing shows at the corners behind the rounded teal
   map in both frames, and the quest card collides with its edge.
7. Frame 1's barrel intersects the plank ramp beside it; frame 2 has grey untextured slabs
   by Oskar's shoulder and at bottom right; "Day 1 · 08:04" is small grey text on bright
   sky; frame 1's grass is uniform in height, tint and spacing and its mid-distance trees
   sit on a line at one scale.

## Bar questions

**Same world as the key art?** No — palette is right, but the board's shadow structure,
canopy density and layered depth are absent and frame 2's foliage colours break it
outright. **Same kind of game as Palworld?** For the trainer model and the clean
portraits, yes; for the blurry, blown-out half of the roster and the shard-canopy tree, no
— those read as placeholder.

**Fixable by re-rendering:** one camera for every portrait (same FOV, distance, framing
box), one lighting rig, exposure that does not clip skin, a plate margin so no hat or hair
touches an edge, and a ground matching `trainer.png`/`grandpa.png`. **Needs art, not a
re-render:** seven copies of one villager, three of one grunt, three interchangeable
bearded men, and r6c3's foreign illustration style.

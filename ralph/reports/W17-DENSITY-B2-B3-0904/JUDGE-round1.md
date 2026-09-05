# Code-blind judge — round 1, `_sheet-round1.png`

Six frames of authored band pickups at ~7 m play distance, judged by a
sub-agent given only the contact sheet, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, and told nothing about what changed or
what the lane hoped it would say. Software-GL Compatibility captures, so
composition, silhouette, colour relationships, scale and placement only.

Frame order: 1 Good (quarry floor), 2 Great (quarry ledge), 3 Rare
(Stormtrail), 4 Stamina Shroom (quarry), 5 Wild Shroom (camp edge),
6 Great (springhead). The judge was not told which was which.

---

## 1. Can the collectable be found in each frame, without hunting?

**Frame 1 — yes, quickly.** Just left of centre, about 48% across and 50% down,
sitting in a patch of clover and white flowers at the foot of a red trunk. It is
a translucent mint-green crystal cluster — three or four faceted lobes, faintly
self-lit, roughly the size of a football.

**Frame 2 — yes, quickly.** Left of the dirt path, about 50% across and 50%
down, at the base of the dark trunk group and inside the frame's deepest shadow.
A turquoise crystal cluster with a paler blue-lilac top facet. It survives
because it is the only cool hue anywhere in a warm brown corridor, not because
it is bright.

**Frame 3 — yes, but slowly, and I had to look for it.** Dead centre, 51%
across, 50% down, lying almost flat among tall grass beside a leafy bush. A pale
cream-green crystal cluster, wider and lower than the others. There is also a
**second** collectable in this frame that I did not expect: a small cyan crystal
cluster on the far right, about 93% across and 36% down, on the grass strip
below the settlement wall.

**Frame 4 — no. I could not find it without hunting, and at sheet size it is
effectively invisible.** I located it only by cropping and magnifying: a
cream-gold mushroom cap at 49% across, 47% down, sitting **directly behind the
central red tree trunk**, which covers its right half and its entire stalk. What
is visible is a pale bulge on the left edge of the trunk that reads as a light
shaft or a rock. This is the most useful answer in the set: as staged, this
pickup does not exist to the player.

**Frame 5 — yes, instantly.** Just left of centre, 50% across, 47% down. An
orange mushroom, a large cap over a smaller second cap. The only frame where the
object is the first thing the eye lands on.

**Frame 6 — yes, after a beat.** Right of centre, 49% across, 50% down, in the
shadow band, with a slim tree trunk running straight through it and splitting
the cluster into two halves. A turquoise crystal cluster. The otter-like
creature at 35% across is far more prominent and takes the eye first.

## 2. Do frames 1, 2, 3 and 6 read as one family, and as different grades?

**One family: yes, clearly.** All four are the same faceted, translucent,
slightly self-lit crystal cluster — same lobe language, same flattened
footprint, same size class. Nobody would mistake one for a different kind of
thing.

**Different grades: no, not legibly.** The only variable that changes is hue,
and the hue ladder does not run in a comprehensible direction:

- Frames 2 and 6 are **the same object**. Same turquoise, same silhouette, same
  size. At this distance I cannot tell them apart at all.
- Frame 1 is green, frame 3 is a washed pale cream-green. Frame 3 is the most
  *desaturated* of the four — it reads as the cheapest, most bleached one, a
  weathered rock rather than a prize.
- Nothing else changes. Shard count is the same, footprint is the same, there is
  no base rock, no ring of smaller shards, no vertical spire, no rising motes,
  no size step, no brightness step. Grade is carried entirely by a colour with
  no key attached to it, so a player learns "different colour" and never learns
  "worth more".

Two concrete measurements behind that. In frame 1 the crystal reads at luminance
206 and the scattered white flower heads in the same grass reach 205 — identical
value. The crystal is separated from ordinary decoration by hue alone. In frame
3 the crystal is genuinely bright (215 against a ground of ~90), yet still reads
poorly, because its hue sits inside the field's own yellow-green family and the
frame is speckled with dozens of pale flower heads and pale grass tips at
similar brightness. Brightness is not buying uniqueness in either frame; the
scatter is already using that value.

One collision worth naming separately: the turquoise of frames 2 and 6 is the
same turquoise as the Team Tether pylon and its tether beam visible in the
background of frame 1, upper centre. A faction/technology colour and a common
loot tier currently share a hue.

## 3. Frames 4 and 5 — a distinct kind, and recognisable?

**As a distinct kind: yes.** Cap-and-stalk against faceted-crystal is a clean
silhouette split, and warm orange against cool green/cyan is a clean colour
split. There is no risk of confusing the two families.

**As recognisably a mushroom: yes in frame 5, no in frame 4.** Frame 5 delivers
the cap, the underside, the stalk and the second smaller cap — completely
unambiguous, and the best-authored object on the sheet. Frame 4 is the same
object in a pale cream colourway with more than half of it behind a trunk; what
survives is a featureless bulge with no cap edge and no stalk. Had I not seen
frame 5 first I would have called it a rock. The cream colourway also throws
away the one cue that makes frame 5 work: orange is a colour nothing else in the
Meadows palette is using, and cream is not.

## 4. Ranking, easiest to notice first

1. **Frame 5** — orange cap, open sunlit ground, near frame centre, unique hue.
   Found before you decide to look.
2. **Frame 2** — dim, but the only cool hue in a warm corridor, and set against a
   clean dark backdrop with nothing competing.
3. **Frame 1** — bright and central, but competing with a field of same-value
   white flower heads; found on the second sweep.
4. **Frame 6** — visible, but bisected by a trunk, sitting in shadow, and losing
   the eye to the creature.
5. **Frame 3** — takes a deliberate search. Beaten, in its own frame, by the far
   smaller and four-times-more-distant cyan cluster on the right.
6. **Frame 4** — not found. Invisible at sheet size.

## 5. The most specific, addressable defects

**Defect A — Frame 4: the pickup is spawned behind a tree trunk on the
camera-facing side.** This is a placement/clearance failure, not a colour
failure; the cap's contrast against the grass is actually the highest in the set
(233,227,145 against 71,87,6). None of that matters because a metre-wide trunk
stands directly between the object and the viewpoint, hiding the right half of
the cap and the whole stalk. A collectable should not be able to land within a
trunk's silhouette from the approach direction. This one is the highest-value
fix on the sheet because the object is already well made — it is only in the
wrong spot.

**Defect B — Frame 6: a trunk runs vertically through the middle of the cluster,
and the cluster is in the frame's darkest shadow band.** The trunk splits the
silhouette into two disconnected teal patches, which is exactly the read that
makes a thing stop looking like one object. Compounding it, the crystal's
absolute brightness there is low (~65,140,110) — it is a dark object in a dark
pocket that happens to be the only cool hue present. If the shadow pass gets a
shade denser, or the player approaches from ten degrees off, it goes. Frame 2
has the milder version of the same problem: it also lives entirely in shadow and
is carried by hue uniqueness alone.

**Defect C — the grade ladder is invisible, and the top grade is the least
visible object.** Frames 2 and 6 are indistinguishable from each other, and
frame 3 — the one the staging treats as most special — is the most washed-out,
lowest-silhouette, hardest-to-find crystal on the sheet, lying flat in grass
taller than itself with no vertical presence. Within frame 3 the small distant
cyan cluster on the right beats the near centre one. Grade currently reads
backwards. It needs something structural per tier — a shard count, a height
step, a base rock, a ring of smaller fragments — not another hue.

**Defect D — no 1.80 m ruler is present in any frame, and the pickups read
oversized.** I could not find the trainer in any of the six frames; the only
character-scale object anywhere is the otter-like creature in frame 6. Measured
against it, the frame 6 crystal cluster is about as wide as that creature is
tall. In frame 5 the mushroom cap is roughly as wide as the wooden crate lid to
its left. As staged, these read as knee-height set dressing rather than things
you bend down and pick up. I cannot settle whether that is intended without the
trainer in shot, and a survey meant to judge pickup scale needs to put them in
shot.

**Defect E, minor — Frame 5: the wooden crate at 8% across, 47% down is sunk
into the terrain to its lid** and reads as a flat plank lying on the grass
rather than a container. It also out-masses the mushroom and takes the eye first
on the left side of the frame.

**Defect F, minor — Frame 6: a dark oxblood clump sits at the base of the trunk
at 27% across, 42% down.** Oxblood is the colour the art-direction board reserves
for Team Tether banners. Whatever that clump is — berries, a red crystal,
foliage — it should not be wearing the danger colour in a peaceful springhead
clearing.

---

## What this lane did with it

Defects A, B, C and D were acted on in round 2 (see `JUDGE-round2.md`):

- **A and B** — `band_pickups.gd`'s scatter clearance raised 0.6 m → 1.6 m with
  a wider nudge ring (2.0 / 3.5 / 5.0 m, 12 bearings). 0.6 m only kept a find
  out of a trunk's own footprint; the judge's point is that a trunk you stand
  *beside* hides you as thoroughly as one you stand *in*.
- **C** — each tier now steps in size (1.0 / 1.18 / 1.40 on top of the item's
  own `world_model_scale`), in glow (0.30 / 0.65 / 1.70), and in medallion size,
  and Rare's hue is carried by *emission* rather than an albedo tint. That last
  one is the root cause of "the most desaturated of the four": albedo
  multiplies, and `candy_pickup.glb`'s wrapper texture is a tight green band
  (ASSET_LEDGER), so a gold tint multiplied into green produced washed
  yellow-green. Emission adds, so it puts the hue on top of the texture.
- **D** — the capture script parked the player beside the *eye*, so it fell
  outside the frustum every time. It now stands 3.4 m ahead and 1.5 m to the
  side, in frame.

Defects E and F are outside this lane's ownership and are recorded for whoever
holds them: E is a `props.json` sink depth at the band-3 camp clearing, F is a
vegetation/scatter colour at the springhead.

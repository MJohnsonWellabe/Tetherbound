# Code-blind judge — round 2, `_sheet-round2.png`

Same discipline as round 1: a fresh sub-agent, given only the contact sheet,
`docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, told nothing
about what changed between rounds or what this lane hoped it would say.

Frame order unchanged: 1 Good (quarry floor), 2 Great (quarry ledge), 3 Rare
(Stormtrail), 4 Stamina Shroom (quarry), 5 Wild Shroom (camp edge), 6 Great
(springhead). The judge was not told which was which.

---

## 1. Can I find the collectable without hunting?

**Frame 1** — Yes, with a beat of delay. Just right of the trainer, at his
shoulder height in screen space, sitting at the base of a background trunk: a
mint-green drum with a bright flat elliptical top and green blade-like shards
fanning out low around it. It is the only saturated light value in a very dark
quadrant of the frame, so it registers, but it is boxed in — the huge foreground
trunk that fills the right 40% of the frame crowds it, and it sits in deep
canopy shade.

**Frame 2** — Yes, immediately. Dead centre, one body-width right of the
trainer: a pale ice-blue drum with a flat white-blue disc top and two blue
petal-or-shard slabs flanking it at the waist. Highest value contrast in the set
(near-white object on an almost black forest floor). This is the frame where the
object placement works.

**Frame 3** — Yes, immediately. Right of the trainer on the open ochre slope: a
large cream-yellow drum with two flat white slabs sticking out sideways. I found
it instantly, but see the caveat in §6 — it is found because it is *big*, not
because it is well designed to be found. There is a **second** object of the
same family in the far right distance (a small ice-blue node in the grass near
the village edge) which I only found on a crop pass.

**Frame 4** — Yes, but it is the second-slowest find. Just left of the big
mid-ground trunk, well beyond the trainer: a pale gold mushroom with white cap
spots and a chalk-white stem. Small in frame and framed on both sides by leafy
bushes of almost exactly its own height, so it has to be picked out of a hedge.

**Frame 5** — Yes, instantly, and it is the best-read object in the whole sheet.
Centre frame, an arm's length right of the trainer: a two-cap orange mushroom
cluster in open lit grass. Orange against green is the biggest hue separation in
the set and nothing occludes it.

**Frame 6** — **No. This one I had to hunt for, and I would call it a fail.**
The intended pickup is an ice-blue drum sitting *behind* the central tree trunk,
*under* a low horizontal branch that crosses directly over it, inside canopy
shadow. Only the top half of its bright disc escapes the trunk and the branch —
it reads as a stray light patch on bark, not an object. On a crop pass I also
found two more things in that frame's left middle-distance that I could not see
at viewing size at all: a dark-red lumpy cluster right against a tree trunk
base, and a pale blue-grey rounded node beside it. All three of frame 6's
candidate objects are effectively invisible from where the player is standing.

## 2. Frames 1, 2, 3, 6 — one family, and do the grades read?

**They read as one family, unambiguously.** All four share the same silhouette:
a smooth vertical cylinder capped by a flat elliptical top, with side
attachments at the waist. Even at thumbnail size you would group them. That part
works.

**The grades read only partly, and they read by the wrong channel.** What
separates them is size, colour hue, and the number of side attachments — all
three changing at once, which confounds "what is it" with "how good is it." A
player cannot tell whether cream-vs-mint-vs-blue means a different grade or a
different *material*.

**Frame 3 holds the most valuable one**, and everything says so at once: it is
by far the largest (its footprint is comparable to the black boulder sitting ten
or so metres to its right in the same frame), it is the brightest and lightest
in value, and it carries the most added parts — two large white slabs plus an
extra lump on the right, where frame 2 has two modest petals and frame 1 has
only low blade shards. Whether or not that is the intended ordering, it is the
ordering the image communicates.

**Frames 2 and 6 are the indistinguishable pair.** Same ice-blue, same
silhouette, same flat white-blue disc top. Frame 6's is smaller on screen and
heavily occluded, but nothing in its shape, colour or added parts separates it
from frame 2's at standing distance. If those two are meant to be different
grades, that distinction does not survive to the player.

A further note on the family as a whole: **the silhouette does not say what the
thing is.** A smooth untextured cylinder with a flat elliptical cap reads as a
bucket, a stool, a drum or a cake. There are no facets, no crystal clustering,
no irregular breakage, no vein or matrix. Whatever these are meant to be, in
frames 1, 2, 3 and 6 I could name the *family* but not the *thing*.

## 3. Frames 4 and 5 — a distinct kind?

**Yes, and this is the success of the sheet.** They read as a completely
different family from the drums at a glance — different silhouette
(cap-and-stem, not cylinder-and-disc), different palette band (warm gold/orange,
not cool mint/blue/cream), different mass distribution. No confusion is possible
even at thumbnail.

**And they are recognisable as what they are meant to be: mushrooms.** Frame 4
is a single pale-gold domed cap with white spots on a chalk-white stem,
silhouette clean against the grass. Frame 5 is a two-cap orange cluster with
visible gills under the upper cap and pink-tan stems. Both are properly modelled
with a real cap curve and a real stem — they are the only objects in the sheet
where I did not have to guess at the noun. They also grade more legibly than the
drums do: frame 5's is bigger, redder, doubled, and reads as the better one, all
through channels that survive the distance.

## 4. The player, and the size comparison

**The trainer is findable in all six frames** — left of centre, back to camera,
brown hair, cream collar over a blue tunic, dark trousers, and a large tan
backpack that is the strongest part of his silhouette. He is readable against
the ground in every frame including the two darkest (1 and 6).

Measured against him, correcting for depth using the bush and flower props as
fiducials at each distance:

- **Frames 4 and 5: correct.** Both mushrooms come out around knee height on the
  trainer, roughly half a metre, and the two agree with each other. That reads
  exactly as something you bend down and pick.
- **Frames 1, 2, 3, 6: wrong. These read as furniture, not pickups.** Frame 2's
  drum comes out around three-quarters of a metre tall and roughly a metre
  across including the side petals — a garden stool. Frame 1's is comparable.
  **Frame 3's is the worst offender:** it is knee-to-thigh height on the trainer
  and roughly two and a half metres wide across the slabs, which is why it reads
  at the same visual weight as the black boulder beside it. Nothing about that
  mass says "pick this up." If a player saw frame 3's object with no prompt,
  they would expect to climb on it or mine it with a tool, not palm it.
- Frame 6's is smaller on screen but that is distance and occlusion, not a
  smaller object; it belongs with the other three.

So the family split is clean and unfortunate: the two objects that read as the
right *kind* of thing also read as the right *size*, and the four that read
ambiguously are also the four that read as street furniture.

## 5. Ranking by ease of noticing, best to worst

1. **Frame 5** — orange on flat lit green, dead centre, zero occlusion, largest
   hue separation in the set.
2. **Frame 3** — instantly visible, but see the caveat: it wins by being
   oversized, which is not the win it looks like.
3. **Frame 2** — near-white object on an almost black forest floor, clean ground
   contact, unobstructed. This is the frame that earns its readability honestly.
4. **Frame 1** — the bright disc pops out of the shade, but the composition
   fights it: a foreground trunk eats the right of the frame and the object sits
   directly in front of a background trunk.
5. **Frame 4** — small in frame, far past the player, and crowded left and right
   by bushes of its own height; its white stem also competes with a scatter of
   white flowers at the same depth.
6. **Frame 6** — failed. Behind a trunk, under a branch, in canopy shadow, with
   two further objects in the same frame that are invisible outright.

## 6. The most specific addressable defects

**A. Frame 6 — the pickup is placed behind occluding geometry, in shadow.** The
object sits directly behind the central tree trunk with a low horizontal branch
crossing over it, and the tree's own canopy shadow sits on top. Only a sliver of
the bright cap survives, and it reads as a highlight on bark. This is a
placement fault, not an art fault: the same object in frame 2's position is one
of the most readable things in the sheet.

**B. Frames 1, 2, 3 and 6 — the family is furniture-scale against the 1.80 m
trainer, and frame 3 is the clearest case.** Frame 3's object measures roughly
knee-to-thigh height and about two and a half metres across, which is why it
sits at the same visual weight as the black boulder in the same frame; frame 2's
is about a metre across. A collectable that is the size of a coffee table
teaches the player the wrong verb before they ever press the button.

**C. Frame 3 — the two white side slabs read as a geometry artefact, not as part
of the object.** They are hard-edged, flat, untextured quads at inconsistent
angles; the right-hand one is visually detached from the body with a gap between
them and no ground contact under it, so it appears to float.

**D. Frames 1, 2, 3, 6 — the silhouette does not identify the object.** Smooth
cylinder plus flat elliptical cap, no facets, no clustering, no irregular
breakage. I can tell you these four are the same family; I cannot tell you what
the family is. Frames 4 and 5 solve exactly this problem and are the proof that
it is solvable in this renderer at this distance.

**E. Frames 2 and 6 are indistinguishable as grades at player distance.** Same
hue, same silhouette, same disc. If they are different tiers, nothing carries
that across the gap.

**F. Frame 4 — the mushroom is crowded rather than presented.** It is flanked at
both shoulders by leafy bushes of near-identical height and at near-identical
depth, so its cap has to be separated out of a hedge. Frame 5 shows the fix in
the same sheet: the same kind of object given a clear apron of low grass.

---

## What moved between round 1 and round 2, and what this lane did next

**Moved, and these are the round-1 fixes landing:**

- **Frame 4 went from "not found at all" to found and correctly named.** Round 1:
  "as staged, this pickup does not exist to the player." Round 2 finds it, reads
  the cap spots and the stem, and calls it a mushroom. The clearance raise did
  its job here.
- **The grade ladder reversed into the right direction.** Round 1: the Rare read
  as "the most desaturated of the four... a weathered rock rather than a prize",
  and "grade currently reads backwards." Round 2: "Frame 3 holds the most
  valuable one, and everything says so at once." Moving Rare's hue from albedo
  to emission and adding the size and glow steps is what did that.
- **The scale question became answerable.** Round 1 could not settle it and said
  so ("a survey meant to judge pickup scale needs to put them in shot"). Putting
  the trainer in frame turned an unanswered question into a measurement.

**Not moved, and acted on in round 3:**

- **Defect A (frame 6) is the round-1 defect B, still open.** Raising the
  loader's scatter clearance from 0.6 m to 1.6 m moved this pickup barely two
  metres and did not clear it, and the reason is now understood:
  `vegetation.gd::has_solid_scatter_near()` sees scatter batches, and the trunk
  crowding the springhead is a PROP, which that function cannot see at all. The
  loader cannot nudge away from something it cannot detect. Fixed at the
  authored level instead — `b3_candy_springhead` moved (16, 3572) → (24, 3578),
  out onto the open ground east of the spring ring — and the limitation is
  recorded in the loader's own header rather than papered over.
- **Defect B (furniture scale) is a regression this lane caused, and is
  corrected.** Growing the tiers to build the ladder is precisely what pushed
  the family to coffee-table size. The per-tier steps are kept (~1.2× each,
  which round 2 read correctly) and the whole family scaled down under them:
  the multipliers go 1.0/1.18/1.40 → 0.34/0.42/0.52, putting Good near a third
  of a metre and Rare near two thirds. The mushrooms are deliberately untouched:
  round 2 measured them at "around knee height... exactly as something you bend
  down and pick", so they are the target, not a problem.

**Read as a defect, but actually the system working — defect E.** Frames 2 and 6
are indistinguishable because **they are the same grade**: both are Great Candy.
The judge is right that nothing separates them and right that it could not tell;
what it could not know is that nothing is supposed to. A tier reading identically
to itself across two different places, 700 m and one band apart, is the tint
being consistent. No change made.

**Outside this lane, recorded for whoever owns it — defects C, D and F.**
C and D are the candy mesh itself: `candy_pickup.glb` is a Meshy generation the
owner reviewed and decided to ship as-is on 2026-09-04, and `docs/specs/ASSET_LEDGER.md`
already records both of these open items in its own words — the flat-top seam
("a flat disc/seam artefact on top of the now-round body") and the wrapper ends
that "cannot produce the board's separate pointed foil lobes, which need real
topology". Two independent code-blind judges have now reached the same
conclusion from the game side, which is worth carrying back to that ledger: the
lobes read as "hard-edged, flat, untextured quads" that "appear to float", and
the family "does not say what the thing is". That is a mesh job and a generation
decision, not a placement or material one. F is a vegetation-density question at
the band-2 quarry, owned by the bake lane.

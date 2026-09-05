# Code-blind judge — round 2, the line-up (main's look = set P, N08 round 2 = set Q)

**Method.** As round 1: a fresh sub-agent (model `opus`), only the two frame sets, their sheets, `docs/reference/` and the visual-judge skill; told nothing about what differed or which was newer. P is `main` at `f8a47ee4` (the same frames as round 1's P); Q is this lane's round 2 (commit `06e5a5c1`): ring on every candy in its own colour, sparkles on Great and Rare, gold crown and wings, brighter Good. Same stands, same eye positions. Sheet: `_sheet-round2.png` (P above, Q below).

---

# Blind visual verdict — collectable lineup, round 2 (sets P and Q)

Judged from pictures only. Software-GL Compatibility renders, so fine lighting and shadow
softness are not scored. Composition, silhouette, colour relationships, scale and geometry are.

## Measurement basis

The trainer is the ruler. In frame 01 he stands 162 px tall (head y≈369, boot sole y≈531) with
the horizon at y≈205. From `H/h_cam = (y_feet − y_head)/(y_feet − y_horizon)` the camera sits
≈3.6 m above the ground plane. The line of objects contacts the ground at y≈428, which puts them
about 1.45× further away than the trainer and gives **≈62 px per metre at the lineup's depth**
(against ≈90 px/m at the trainer's). Every size below is computed from that, not eyeballed.

---

# SET P

## 1. Finding the collectables — frame 01 (`P/01-lineup-cam7m.png`)

Scanning the frame cold, without being told where to look, I find **four** things in a line to
the trainer's left (screen-left of him), all at roughly the same depth. Nothing else in the frame
reads as a pickup — the right half (x 700–1280) is pure meadow scatter.

**P-1 — x≈295, y≈415.** A wide flat **green light wash** roughly 1.4 m × 1.0 m lying on the
grass. Inside it, at its lower-left, a tiny greenish-white nub about 0.4 m across and 0.15 m
tall. **I would call this one effectively invisible.** I only found it because the glow told me
to look, and even at 7× magnification I cannot say what shape it is — it reads as a smear of
lighter grass, not an object. Nothing on the ground under it except the glow.

**P-2 — x≈370, y≈408.** A **pale teal / blue-green rounded lump**, ~0.60 m long × 0.24 m tall,
sitting inside a blue-white light wash of similar size to P-1's. There is a darker speckle near
its left end that reads as an eye. Grass blades cross in front of it. No ground mark other than
the wash. Legible but **ambiguous**: it reads as a small crouching animal, or a river cobble, or
a lump of jade — not as a thing I would walk over to collect.

**P-3 — x≈463, y≈415.** A **pale cream lumpy mass** ~0.80 m across × 0.32 m tall, with **two
thin flat pure-pale blades protruding from it at roughly 45°, left and right**, each ending in a
hard straight edge. A dark-green meadow bush with a white flower **grows straight up out of the
middle of it**, hiding the top half. This one is not merely ambiguous — the white blades read as
**detached geometry**, and the body reads as glare. If I had to name it I would say "a broken
shell" or "a rendering error."

**P-4 — x≈545, y≈395.** A **cluster of three amber-capped mushrooms** on pale grey-white stems,
the tallest ~0.85 m wide and **0.91 m tall**. Unambiguous, the only one of the four I can name at
a glance. Grass blades pass through the stems.

Ambiguity summary: **P-1 invisible, P-2 ambiguous, P-3 reads as an artefact, P-4 legible.**

## 2. Family and kind

They do **not** read as one family. They read as four unrelated things that happen to be in a row:

- P-1: nothing identifiable — a patch of brighter grass.
- P-2: a **creature** (a toad or a small turtle) or a rock. The speckled eye-like mark pushes it
  toward creature.
- P-3: **debris / an artefact**, because of the two flat white blades.
- P-4: a **plant** — mushrooms growing where they grew, i.e. scenery, not an item.

The mark that separates them is the **coloured light wash**: P-1, P-2 and P-3 sit in one, P-4
does not. The rule a player would infer is exactly backwards from the intent: *the three lit
smudges are pickups; the mushrooms are landscape.* Since P-4 is the only one that reads as a real,
modelled, nameable object, the mark is telling the player to ignore the best-looking one.

## 3. Value hierarchy

The hierarchy is carried **almost entirely by the ground light's hue**, plus size as a weak
second channel. It is not carried by the objects, which is the problem.

Ranked most to least valuable as a player would read it:

1. **P-4 (amber mushrooms)** — biggest, tallest, warmest, the only one with modelled form. Wins by
   size and by being the only nameable object, *despite* carrying no glow.
2. **P-3 (cream)** — brightest patch in the group, and warm. But it wins on brightness in a way
   that reads as blown-out, not as precious.
3. **P-2 (blue)** — the classic "uncommon" hue, and legible.
4. **P-1 (green)** — the classic "common" hue, and near-invisible.

**Confidence at speed: poor.** Green→blue→gold is a borrowed MMO loot convention and a player
would probably decode it, but the two channels fight each other: hue says P-3 > P-4, size and
modelling say P-4 > P-3, and P-3's colour is a bleached cream rather than a saturated gold, so it
reads as sun glare on grass rather than as a tier. At a jog the player registers "three lights and
a mushroom," not four ranked items.

## 4. Distance

**12 m (`P/02-lineup-cam12m.png`):** P-1 has lost its object entirely — only a green haze remains.
P-2's lump is still faintly there inside its blue haze. **P-3 has dissolved: the only geometry
left is the two white blades, now floating in the grass with nothing attached to them.** P-4 is
still clearly mushrooms. Hierarchy: partially survives, but P-3 has become a defect rather than a
rank.

**17 m (`P/03-lineup-cam17m.png`):** four objects have become **three coloured smudges and one
mushroom**: a green patch, a blue-white patch, a warm patch, and a small amber cap at x≈590. No
object silhouette survives except P-4's. The hierarchy at this range is "there is loot over there,"
which is a location cue, not a hierarchy.

## 5. Scale

Against the 1.80 m trainer, at ≈62 px/m at the lineup's depth:

| | width | height | reads as |
|---|---|---|---|
| P-1 | ≈0.40 m | ≈0.15 m | dinner plate |
| P-2 | ≈0.60 m | ≈0.24 m | a footstool / a curled cat |
| P-3 | ≈0.80 m | ≈0.32 m | a coffee-table top |
| P-4 | ≈0.85 m | **≈0.91 m** | **hip-height on the trainer** |
| green light wash | ≈1.4 m × 1.0 m | flat | a rug |
| blue light wash | ≈1.3 m × 1.1 m | flat | a rug |

**None of these read as something you palm.** The smallest is plate-sized; the largest is a piece
of garden furniture standing as tall as the trainer's hip. The mushroom cluster in particular is
scenery scale, not inventory scale — the player's hand would not close around any of them. The
light washes are larger than the objects they mark, which is why the marks read louder than the
items.

## 6. Defects (P)

Each named to a frame.

- **Frame 01, 02 — the glow is a hard-edged rectangle.** Contrast-boosting `P/01` at x 250–420
  shows the green wash terminating in a **dead-straight vertical right edge and a dead-straight
  horizontal bottom edge**. Same for the blue wash. This is an unfaded billboard quad meeting the
  terrain, and it is the single most artefact-like thing in the set — it reads as a broken decal,
  not as light.
- **Frame 01, 02 — P-3's two white blades are detached geometry.** They protrude past the body,
  end in hard straight cuts, and at 12 m they persist after the body has vanished, so the frame
  shows two white slivers floating in grass attached to nothing.
- **Frame 01 — P-3 collides with the meadow's own scatter.** A dark-green flowering bush grows
  vertically out of the middle of P-3 and occludes its upper half. The pickup and the decoration
  occupy the same ground point.
- **Frame 01 — grass punches through P-4's stems and P-2's body.** Blades render in front of and
  through the mushroom stalks with no interaction.
- **Frame 01 — P-4's stems are the frame's white point.** Sampled, the stems reach RGB 229–231,
  the maximum value anywhere in the image, while the **clouds cap at 207**. The brightest thing in
  a daylit outdoor frame is a mushroom stalk, not the sky. Nothing is literally 255 (the tonemap
  ceiling is 231), but these stalks are functionally the picture's white, and near-white grey-white
  is not a hue the key-art palette strip contains.
- **Frame 01 — P-4's stems duplicate the meadow's own decoration.** The meadow is scattered with
  small **near-white parasol flowers on near-white stalks** (e.g. x≈85, y≈500). P-4's white stems
  are the same value and nearly the same silhouette. The pickup is camouflaged by the set dressing.
- **Frame 01 — no contact shadow or occlusion under any object.** Each sits on a lighter patch,
  which is the opposite of grounding; the trainer has a clear cast shadow and the pickups have none.
- **Frames 02, 03 — glow bloom merges into a continuous band.** At 12 m the green, blue and cream
  washes bleed into one pale horizontal smear, which destroys the count as well as the ranking.

**Reads as UI:** the light washes themselves, because they are flat, rectangular and larger than
the objects. Nothing in P reads as a *selection reticle* specifically.

---

# SET Q

## 1. Finding the collectables — frame 01 (`Q/01-lineup-cam7m.png`)

Same four positions, same count: **four**, and I find them faster.

**Q-1 — x≈295, y≈418.** Green light wash as in P, and inside it a small pale nub, but now sitting
on a **thin bright cyan-white elliptical ring on the ground, ≈0.63 m across**. The ring is larger
and far more visible than the object. **The object itself is still effectively unreadable** — I
can see *that* something is there because of the ring, but not *what*.

**Q-2 — x≈370, y≈408.** The teal lump, ≈0.60 m long, on a **cornflower-blue ground ring ≈0.83 m
across**. Legible as an object; still ambiguous as a *kind* — it reads as a small crouched animal
or a mossy stone. Grass crosses in front of it and over the ring.

**Q-3 — x≈463, y≈415.** Now a **saturated orange-gold cluster of rounded lobes**, ≈0.80 m across
× 0.32 m tall, on a **cream-gold ground ring ≈1.02 m across**. Readable as a bloom or a golden
fungus. **The same meadow bush still grows straight through its centre.** One flat pale-gold blade
still protrudes at its left, hard-edged — the P-3 shard survives, just recoloured.

**Q-4 — x≈545, y≈395.** The amber mushroom cluster, 0.85 m × 0.91 m, unchanged. **It has no ring
and no glow.**

Ambiguity summary: **Q-1 still effectively invisible as an object (its ring is not),
Q-2 ambiguous in kind, Q-3 now legible, Q-4 legible.**

## 2. Family and kind

Closer to one family than P, but still not one family.

- Q-1: unidentifiable.
- Q-2: a **creature or a stone**.
- Q-3: a **golden bloom / fungus** — the recolour moves it from "artefact" to "plant."
- Q-4: **mushrooms**.

Q-3 and Q-4 now share a warm amber-gold hue family and a rounded-cap language, so those two read
as siblings. Q-1 and Q-2 do not join them.

**The mark rule in Q is louder and worse.** Three objects carry a bright ground ring; the fourth —
**the largest, best-modelled, most nameable one** — carries nothing. A player would infer: *ringed
things are pickups, the mushrooms are landscape.* That is exactly the wrong lesson, and Q states it
more emphatically than P did because a ring is a more explicit affordance than a glow.

## 3. Value hierarchy

Channels in play: **ground-ring hue** (cyan-white → blue → gold), **object hue** (green → teal →
orange-gold → amber), and **size**, all three now aligned and increasing left to right. That
alignment is Q's real gain — in P the channels disagreed.

Ranked:

1. **Q-4 (amber mushrooms)** — largest, tallest, warmest, only fully modelled object.
2. **Q-3 (gold bloom)** — saturated gold, largest ring, second largest object. Now genuinely reads
   as a high tier rather than as glare.
3. **Q-2 (blue lump)** — blue ring, mid size.
4. **Q-1 (green nub)** — green light, smallest ring, no readable object.

**Confidence at speed: moderate** for the ranking of 1–3 among the ringed objects, but **broken at
the top**, because Q-4 sits outside the ring system entirely. A player at speed would rank the
three ringed items correctly and then be unsure whether the mushrooms are in the same set at all.

## 4. Distance

**12 m (`Q/02-lineup-cam12m.png`):** the ground rings are gone — too thin to survive the
resolution. What survives is: a green haze (no object), a blue haze with a faint teal lump,
**a clearly readable orange-gold cluster with visible lobes**, and the mushrooms. Q-3 is the
difference: where P-3 had become two floating white shards, Q-3 is still an object. Hierarchy at
12 m: **survives for Q-2/Q-3/Q-4, fails for Q-1.**

**17 m (`Q/03-lineup-cam17m.png`):** the same collapse as P — a green patch, a blue-white patch,
a small orange pixel cluster still faintly present, and one amber mushroom cap. Marginally *worse*
separation than P here: Q's washes bleed into one another across the whole band, whereas in P the
green and blue patches stayed slightly more distinct. Hierarchy at 17 m: **does not survive** in
either set.

## 5. Scale

Identical object sizes to P (they are the same objects). Ground marks:

| ground mark | diameter | reads as |
|---|---|---|
| Q-1 ring | ≈0.63 m | a dinner plate, ≈1.6× its object |
| Q-2 ring | ≈0.83 m | a bar-table top, ≈1.4× its object |
| Q-3 ring | ≈1.02 m | **a metre-wide circle** |
| Q-4 | none | — |

Same verdict as P: **nothing here is palmable.** Q-4 is hip-height furniture. And Q adds a
metre-wide circle drawn on the meadow around a 0.8 m object — the mark is now larger, brighter and
more geometric than the thing it marks.

## 6. Defects (Q)

- **Frame 01 — the ground rings read as a selection gizmo, not as a world feature.** They are thin,
  perfectly elliptical, uniform in stroke width, and they **hit RGB 231,231,231 — the brightest
  value in the entire image, brighter than the sky and clouds (which cap at 207).** A perfect
  bright ellipse at the frame's white point around a prop is the visual language of a targeting
  reticle or an editor selection outline. This is the worst defect in either set.
- **Frame 01 — the glow is still a hard-edged rectangle.** Contrast-boosting `Q/01` at x 250–420
  shows the blue wash ending in a straight vertical edge at x≈404 and a straight horizontal cut at
  y≈418; the green wash the same. Unfixed from P.
- **Frame 01 — Q-3 still collides with a meadow bush.** The bush grows through the middle of the
  gold bloom *and* through the ring, so the ring is bisected by foliage. The collision is more
  obvious in Q than in P precisely because the object is now visible.
- **Frame 01 — the flat blade on Q-3 survives.** Recoloured to pale gold, but still a hard-edged
  flat plane sticking out of the body.
- **Frame 01 — grass grows through the rings and through the objects.** Blades cross the Q-1 and
  Q-2 rings and pass through Q-4's stems. The rings do not clear or bend the scatter they overlay.
- **Frame 01 — Q-4's white stems remain the frame's white point** and remain the same value and
  silhouette as the meadow's own near-white parasol flowers.
- **Frame 01 — the ring stops at three of four.** Whether or not this is intended, a marked/unmarked
  split that lands on the *most* legible object is a design defect visible in the still.
- **Frame 01 — still no contact shadow.** The ring is a substitute for grounding and it does not
  work: a bright outline reads as projected onto the ground, not as the object resting on it.
- **Frames 02, 03 — the rings vanish entirely** while the glow washes survive, so the affordance
  the player learns at 7 m is gone at 12 m. An affordance that only exists inside pickup range is
  not doing distance work.

---

# 7. Comparative — P against Q

**Which makes the hierarchy more legible: Q, clearly.**
In P the two hierarchy channels contradict each other — hue says the cream object outranks the
mushrooms, size and modelling say the opposite, and the cream reads as blown-out grass rather than
as a tier. In Q the object hue, the ring hue and the size all increase together left to right, so
the ramp green → blue → gold → amber is one statement instead of three. `Q/02` is the proof: at
12 m Q-3 is still an orange object you can rank, while P-3 at the same distance is a pale smear
with two white shards floating in it.

**Which makes the objects read more as items and as one family: Q, but only just.**
Q-3's recolour from bleached cream to saturated gold is the single change that does the most work
in either set — it converts one object from "artefact" to "plant," and it gives Q-3 and Q-4 a
shared warm-amber family. That is one sibling pair out of four. Q-1 and Q-2 join no family in
either set, and neither set makes any of the four read as an *item* — as a thing sized and shaped
to go into a pocket. On the item question both sets fail; Q fails less.

**Which has worse defects: Q.**
P's worst defects are the rectangular glow quads and P-3's floating white blades. Q inherits the
first, half-fixes the second, and then adds a new class of defect that is worse than either: the
ground rings. They are the brightest pixels in the frame — brighter than the sky — perfectly
elliptical, uniform-stroked, and they read unambiguously as a **UI selection gizmo composited over
the world**. P has no element that reads as UI in that specific way. Q also introduces an
inconsistency P did not have: three objects marked, the fourth and most prominent unmarked, which
teaches the player a rule that contradicts the size hierarchy Q itself just clarified.

**What carries each, and what sinks each.**
P is carried by having no explicit marker language at all, so nothing in it looks composited on
top of the world. P is sunk by P-3, which at 7 m looks broken and at 12 m is literally two white
slivers attached to nothing, and by the fact that its brightest object is also its least readable.
Q is carried by the recolour of Q-3 and by the resulting alignment of hue, size and mark. Q is
sunk by the rings — too bright, too geometric, too large relative to their objects, absent on the
fourth object, and gone by 12 m.

**Net:** Q is the more legible set and the one I would keep working from, but its rings are not the
reason and should not be kept in their current form. Everything Q gains, it gains from the recolour.

---

# Verdict

## The three things that most separate these frames from the references

1. **Nothing here is item-sized.** Judged against `palworld-02-open-field-path.jpg` and
   `palworld-03-field-boss-meadow.jpg`, where world pickups are small, tight, high-contrast objects
   that sit *in* the grass, every object in `P/01` and `Q/01` is between 0.4 m and 0.91 m. The
   mushroom cluster is hip-height on a 1.80 m trainer. The reference reads "pick that up"; these
   frames read "walk around that." This is the loudest error in both sets and it is a scale error,
   not a lighting one.
2. **The mark is louder than the object.** In `Q/01` the ground ring reaches RGB 231 — the image's
   white point, brighter than its own sky — around an object whose colour never gets near that. In
   `P/01` the glow rectangle is 1.4 m wide around a 0.4 m object. The Palworld shots never let a
   pickup's affordance outweigh the pickup; the key art has no ground decals at all and gets its
   focal reads from silhouette and value. Here the effect *is* the object.
3. **The value structure is inverted.** In `tetherbound-meadows-keyart.png` the sky and clouds are
   the brightest region of every panel and the ground is the lower half of the value range. In both
   `P/01` and `Q/01` the clouds cap at RGB 207 while ground props — mushroom stems, meadow flower
   parasols, Q's rings — reach 229–231. The sky is a mid-tone and the grass is full of small white
   hotspots, which is why the meadow reads as busy and why the pickups have to shout to be found.

## The two bar questions, answered for the better set (Q)

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No.** The palette is in the right family — the yellow-greens, the oak canopies, the pale-blue
sky, the small blue-violet wildflowers all match the board's strip. What breaks it is value
structure and mark language. The key art puts its brightest values in the sky and reserves
saturated warm accents for a few authored focal points; `Q/01` puts its brightest value on a
1.02 m bright ellipse drawn on the ground and speckles the whole meadow with near-white parasol
flowers at the same value. The board has no glowing rectangles and no ground reticles anywhere.
A viewer would say these frames are set in that world and then say something has been composited
on top of it.

**B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to be the
same kind of game?**
**Yes.** The third-person camera height and framing, the stylised-realist trainer, the readable
tree silhouettes on the ridge at `Q/01` x 850–1280, the open meadow with a treeline landmark, the
wandering quadruped at `P/03` x≈190 — all of it says the same genre and roughly the same ambition
as `palworld-02` and `palworld-03`. What does not hold up is prop discipline: Palworld's field
pickups are small, tight and modelled, and their ground effects are subordinate to them. These are
big, soft and effect-led.

## Fixable in the scene vs. needs art not in the build

**Fixable by changing the scene — this becomes work:**

- **Shrink every pickup.** Target 0.15–0.30 m across so they read as palmable against the 1.80 m
  trainer, and shrink the marks with them. Note that the project directive is to fix relative-scale
  defects by growing the smaller side — that rule is about creatures, and it cannot apply here: the
  correct fix for a hip-height collectable is to make it smaller, and the trainer is the fixed
  reference, so raise this with the owner rather than inflating anything.
- **Cap the marks below the sky.** No world element should exceed the cloud value (207). Take Q's
  rings and P/Q's glow well below that; the sky must be the brightest thing in a daylit frame.
- **Replace the elliptical ring with something non-UI.** A soft irregular ground darkening, a
  scattering of the object's own colour into the grass, or a genuine contact shadow. A uniform-stroke
  bright ellipse will always read as a reticle.
- **Fade the glow quad by depth.** The straight vertical and horizontal cuts on the green and blue
  washes in both `P/01` and `Q/01` are the most obviously "bug" thing in either set and are a soft
  clip away from being invisible.
- **Give every pickup a contact shadow / ambient darkening.** Currently each object sits on a
  *lighter* patch, which reads as floating.
- **Mark all four or none.** Q's three-of-four split teaches the wrong rule. Whichever way it goes,
  the mushroom cluster must be in the same system as the rest.
- **Clear a small scatter radius under each pickup,** so the meadow bush stops growing through Q-3
  and grass stops passing through the mushroom stems.
- **Re-tint the mushroom stems** off the frame's white point and away from the meadow parasol
  flowers' value, so the pickup is not camouflaged by the set dressing.
- **Adopt Q's Q-3 recolour** as the model for the whole ramp: saturated object hue carrying the tier,
  effect merely confirming it.

**Needs art that is not in the build — this becomes evidence for what has to be made:**

- **Q-1 and Q-2 have no readable design.** No amount of scene tuning makes a 0.15 m featureless nub
  or an ambiguous teal lump read as a collectable item; they need actual modelled silhouettes with
  a distinguishing feature that survives to 12 m. At present the green tier is an invisible object
  wearing a light.
- **There is no item family language.** The four objects share no shape grammar, no common base, no
  repeated motif. One family across four tiers is an art task, not a scatter task.
- **The flat blade on P-3 / Q-3 is broken geometry in the asset**, not a placement problem — it
  protrudes with hard straight cuts and outlives the body at 12 m. That asset needs fixing or
  replacing at source.
- **Nothing in the set reads as manufactured or precious.** Both legible objects are fungi. If the
  tiers are meant to be materials or treasure rather than mushrooms, the higher tiers need art that
  looks like a made or rare thing, which does not exist in these frames.

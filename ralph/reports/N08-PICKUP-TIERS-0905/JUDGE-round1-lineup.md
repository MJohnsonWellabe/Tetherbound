# Code-blind judge — round 1, the line-up (main's look = set P, N08 round 1 = set Q)

**Method.** A fresh sub-agent (model `opus`) was given only the two frame sets, their contact sheets, `docs/reference/` and `.claude/skills/visual-judge/SKILL.md`, and told nothing about what differed between P and Q or which was newer. P is `main` at `f8a47ee4` (W17's round-3 look, never before rendered); Q is this lane's round 1 (commit `e5066175`). Same stands, same eye positions (logged), the `band1_open` ground at (0, 693): Good, Great, Rare, Stamina Shroom 1.3 m apart, lens ~7 / 12 / 17 m, the trainer beside them. Sheet: `_sheet-round1.png` (P above, Q below).

---

# Blind judgement — collectable lineup, sets P and Q

Judged from pictures only. No score. Frames named throughout. Pixel coordinates are
in the 1280×720 originals.

**Measuring stick.** In `01-lineup-cam7m` (both sets) the trainer runs from hair-top
y≈362 to boot-sole y≈531 — 169 px for 1.80 m, so ≈94 px/m at his depth. The object
line sits roughly 1.5× further from camera (its bases at y≈422 vs his feet at y≈531,
against a horizon at y≈205), so ≈62 px/m out there. All sizes below use that.

**Housekeeping.** The two sets are not the same instant: clouds differ in frames 02
and 03, and a grey quadruped has wandered (P frame 03 has two at x≈190 and x≈290; Q
frame 03 has one at x≈30). Nothing in my reading depends on that.

---

## SET P

### 1. Finding the collectables — frame 01

Four objects sit in a line to the trainer's right-of-frame-left, evenly spaced,
x≈285 through x≈575, bases all around y≈400–425. I found them because there are
four coloured light patches in a row, not because I saw four objects.

- **P-a — x≈285–310, y≈400–410.** A small bright-green form, ~25×10 px (≈0.40 m
  wide, 0.16 m tall), sitting inside a soft green light pool ~68 px across (≈1.1 m).
  **This one is effectively invisible.** It is a green shape, on green grass, inside
  a green glow, and the meadow's own grass blades are taller than it. I can tell
  something is there; I cannot tell what shape it is. At 7 m — the *closest* frame in
  the set — I would not call this found, I would call it inferred from the light.
- **P-b — x≈358–390, y≈398–413.** A pale blue-white low slab or faceted chunk,
  ~32×15 px (≈0.52 × 0.24 m), with a couple of flat facets visible on top. Inside a
  wide blue-white ground wash ~85 px (≈1.37 m). Reads as a rock or an ice shard.
  Legible as *a thing*, ambiguous as *what thing*.
- **P-c — x≈433–478, y≈396–415.** A pale cream lobed mass, three or four overlapping
  rounded lumps, ~45×19 px (≈0.73 × 0.31 m). Two flat white blade shapes stick out
  left and right, taking the total width to ≈77 px (≈1.24 m). This is the least
  legible of the three glowing objects **because of value, not size**: it is nearly
  the same brightness and hue as the sunlit grass immediately behind it, and it sits
  inside a pale yellow glow that is also that brightness. Ambiguous — I cannot say
  whether it is one object, three eggs, or a squashed mushroom.
- **P-d — x≈500–575, y≈362–425.** A cluster of three yellow-capped mushrooms, big
  cap plus two smaller, on pale stems. ~75 px wide × 63 px tall (**≈1.21 × 1.02 m**).
  This is the only one of the four with real three-dimensional form and a hard top
  edge, and the only one I can identify without the glow.

Nothing else in frame 01 is a candidate. I swept the whole midground band left and
right of the trainer: the only other small objects are a grey pebble at x≈1245,
y≈410 and the usual white and blue meadow flowers, and none of them glow or read as
picked up.

### 2. Family and kind

**Not one family. Three different readings, and one of them is not an item at all.**

- P-a reads as *nothing* — a patch of green light.
- P-b reads as a **mineral**: a rock, a crystal shard, a lump of ore.
- P-c reads as an **organic blob** — a cluster of eggs, a bracket fungus, or a
  bag that has been sat on. With the two white blades attached it also reads
  partly as broken geometry.
- P-d reads unambiguously as a **plant** — a mushroom cluster, meadow dressing,
  the sort of thing that is scenery in every other game.

The only thing the four share is "sits on the ground and has a coloured light pool
under it." That is not a family; that is a shader they have in common. There is no
shared silhouette language — no common base, no common cap, no repeated proportion —
so a player has no way to learn "these four are the same kind of thing at different
tiers."

### 3. Value hierarchy

There *is* an intended ramp and I can read its direction, but I read it from the
wrong channels.

Ranked most to least valuable, as a player would guess:

1. **P-d** (gold mushrooms) — largest by a factor of three, warmest hue, brightest.
2. **P-c** (cream lobes) — second-largest, warm-pale.
3. **P-b** (blue slab) — mid size, cool hue.
4. **P-a** (green) — smallest, coolest, dimmest.

**The channels I actually used, in order of how much work each did:**
- **Size** did most of it. The objects grow monotonically left to right: 0.40 m →
  0.52 m → 0.73 m → 1.21 m wide. That is a very loud channel and it happens to
  agree with the hue ramp.
- **Hue**, green → blue → cream → gold, second. This is a legible rarity idiom.
- **Glow-pool radius and brightness**, third, and it also agrees.
- **Ground marks:** none in this set.
- **Added shape:** none, other than the two white blades on P-c, which do not read
  as a rank marker.

**Confidence at speed: low, and for a specific reason.** All three working channels
move together *and* the object kind changes along with them. So the ramp is
ambiguous between "these are four tiers of one item" and "these are four different
species of plant, one of which is big." The top of the ramp is a mushroom cluster —
the one thing in the line that reads as scenery — so the strongest visual signal in
the set is attached to the object least likely to be understood as loot. At a run,
what I would take away from frame 01 is "there is a glowing patch over there," not
"there is a rare pickup and three common ones."

### 4. Distance

**Frame 02, 12 m.** The line collapses to x≈400–590, y≈345–380.
- P-a: **gone.** A green ground wash, no object inside it at any zoom.
- P-b: a faint blue-grey smudge, maybe 6×3 px of actual object. Findable if you know
  where to look, not otherwise.
- P-c: **gone.** The object has dissolved into its own yellow glow. What survives is
  the *two white blades* — two disembodied white slivers at x≈530 and x≈555 floating
  in a yellow smear. The only part of this object still visible at 12 m is its
  artefact.
- P-d: fully readable — cap, stem, cluster shape, all present.

**Frame 03, 17 m.** The line is one ~150 px band at y≈340–360.
- P-a, P-b, P-c: three coloured light patches. No object in any of them.
- P-d: cap silhouette still readable.

**Does the hierarchy survive? No.** By 12 m it has been replaced by a different and
wrong reading: one mushroom plus three patches of coloured light. The rank ordering
technically persists (green-dimmest through gold-brightest) but it is now a ranking
of *glows*, not of objects, and a player scanning a meadow reads glows as "point of
interest here," not as tiers. Note what the frames themselves prove: the single
object that survives to 17 m is the one with authored three-dimensional form and a
hard top edge. Form beat glow, at every distance, in this set.

### 5. Scale

Against the 1.80 m trainer standing about two metres to their right in frame 01:

| | width | height | reads as |
|---|---|---|---|
| P-a | ≈0.40 m | ≈0.16 m | a large loaf. Palmable-ish, but shorter than the surrounding grass. |
| P-b | ≈0.52 m | ≈0.24 m | a two-handed rock, not a pocket item. |
| P-c | ≈0.73 m (1.24 m with blades) | ≈0.31 m | a bin lid. Not palmable. |
| P-d | ≈1.21 m | ≈1.02 m | **furniture.** Chest-high on the trainer. |

So: **only P-a reads as something you palm. P-b is two-handed. P-c and P-d are
props you walk around, not items you walk over.** The set spans a 6× height range,
which on its own destroys the "one family" reading — four tiers of one item do not
differ in size by six times.

### 6. Defects, set P

Each names frame 01 unless stated.

- **P-D1. Flat billboard quad through the mushroom cap.** x≈530–580, y≈365–395. A
  hard, straight, diagonal-edged pale card cuts across and behind the big cap. It is
  opaque, it has no soft edge, and it terminates in a corner. This is a glow sprite
  seen near edge-on rendering as a solid plane. It reads as a bug, plainly.
- **P-D2. The meadow bush grows through P-c.** x≈460–490. The bush's stems pass
  straight down through the top of the object and out of the bottom. Nothing
  occludes anything; two solids share a volume. The object was spawned on top of
  existing scatter.
- **P-D3. Detached white blades on P-c.** x≈418–432 and x≈483–495. Two flat white
  blade shapes protrude left and right, and the left one has a **visible gap**
  between it and the body. They read as loose shards or petals that belong to
  something else. See §4: at 12 m they outlive the object they are attached to.
- **P-D4. P-a has no silhouette at any distance,** including the 7 m frame. Green
  object, green grass, green light. This is not "subtle"; it is invisible.
- **P-D5. The glow pools are painted, not emitted.** All three pools brighten the
  terrain in a soft ellipse, but the grass blades *standing inside them* are lit
  exactly as the grass outside them. Frame 01, all three pools. The result is a
  flat decal on the ground that the world's own geometry ignores.
- **P-D6. The mushroom cluster's base is a flat pale disc with a hard horizontal
  bottom edge** at x≈505–560, y≈415–425, with no contact shadow. It reads as set
  down on the grass rather than rooted in it.
- **P-D7. No object in the line casts a contact shadow,** while the trainer two
  metres away casts a long hard one in the same frame. Side by side, this is the
  cleanest read of "these were dropped in from a different scene."

---

## SET Q

### 1. Finding the collectables — frame 01

Same four positions, same line. Two of them have changed and two have not.

- **Q-a — x≈285–310, y≈400–410.** Identical to P-a. Same small green form, same
  green pool, no added mark. **Still invisible.** I can additionally make out a
  small pale flat plate just above and behind it (x≈300–310, y≈396) which reads as
  another loose white quad rather than part of the object.
- **Q-b — x≈358–390, y≈398–413.** Same slab, pushed slightly more teal/saturated.
  **New: a thin white ellipse on the ground around it**, x≈352–420, ≈1.10 m across.
- **Q-c — x≈433–478, y≈396–415.** **Changed most.** Now a saturated orange-gold
  lobed mass instead of pale cream. It has **a white ground ring** (x≈424–494,
  ≈1.13 m across) and **a crown of hard white triangular spikes** across its top
  rim (x≈440–480, y≈390–400). The two white blades left and right are unchanged.
- **Q-d — x≈500–575, y≈362–425.** **Identical to P-d.** Same three mushrooms, same
  size, **no ring**, same flat quad behind the cap.

Findability at 7 m: Q-b and Q-c are noticeably easier to *locate* than in P, because
the ring gives each one a hard bright edge on the ground. Q-c is also easier to
*identify* than P-c, because the orange finally separates it from the sunlit grass.
Q-a is exactly as invisible as P-a.

### 2. Family and kind

**Still not one family, and Q makes the category confusion worse in one respect.**

The four still read as: nothing / mineral / organic blob / plant. Nothing about the
underlying forms changed. But Q now adds a fifth reading on top: the two ringed
objects read as **selected**, i.e. as things a cursor or a quest system is pointing
at, while the unringed two read as ordinary world dressing. A player looking at
frame 01 will not conclude "four tiers of one item"; they will conclude "two things
are highlighted and two things are not."

Q-c's gold is a real improvement to its *kind* reading — a saturated warm lobed mass
reads as fruit or honeycomb or amber, which is a plausible item. Q-c is the only
object in either set that gained item-ness.

### 3. Value hierarchy

Ranked as a player would guess:

1. **Q-d** (gold mushrooms) — still the largest, warmest, brightest.
2. **Q-c** (orange lobes) — now genuinely second: the saturation jump gives it the
   warm end of the hue ramp and a ring.
3. **Q-b** (teal slab) — mid size, cool, has a ring.
4. **Q-a** (green) — smallest, dimmest, no ring.

**Channels:** size and hue still do most of the work, exactly as in P. The new
channel is **a ground ring**, and it is the least trustworthy one in either set,
because it is applied to two of four objects and its coverage does not follow the
rank order. The ring is on ranks 2 and 3. Ranks 1 and 4 have none. Whatever rule the
ring is meant to express, it is not "more valuable" and it is not "collectable" — a
player who learns "ring = pickup" will walk past the gold cluster, and a player who
learns "ring = rare" will not know what to do with the fact that the biggest,
brightest thing in the line does not have one.

**Confidence at speed: still low, but for a different reason than P.** In P the
hierarchy was under-signalled. In Q it is signalled by two channels that disagree
about which objects are even in the set.

The one thing Q genuinely buys is the top of the ramp: the green→teal→gold hue
sequence now has a legible warm end that is not a mushroom.

### 4. Distance

**Frame 02, 12 m.**
- Q-a: **gone.** Same as P.
- Q-b: a faint teal smudge, plus **a visible white ring arc** under it. The ring is
  the only reason I can point at this object rather than at its glow.
- Q-c: **survives.** A small but distinct orange nub, ~8×5 px, sitting on a white
  ring arc. This is the single clearest improvement between the sets: the object P
  loses entirely at 12 m, Q still shows.
- Q-d: fully readable.

**Frame 03, 17 m.**
- Q-a, Q-b: light patches only. Q-b has a faint white line under it.
- Q-c: a small orange nub is *just* holding on, plus a thin white line.
- Q-d: cap silhouette readable.

**Does the hierarchy survive? Partially, and only through 12 m.** At 12 m Q keeps a
two-object ordering (gold cluster > orange nub) plus two light patches; P keeps a
one-object ordering plus three light patches. At 17 m both sets fail the same way:
a single ~150 px band of green-blue-gold light near the horizon with one mushroom
cap in it. Neither set has a collectable that reads as an object at 17 m except the
one that is arguably not a collectable.

### 5. Scale

Unchanged from P — the objects are the same size. Q adds one new scale reading:

- **The ground rings are ≈1.10–1.13 m across.** That is the width of the trainer's
  outstretched arms in frame 01. A one-metre disc under a 0.24 m rock is a very
  large footprint for a pickup, and it makes Q-b and Q-c read as *sites* rather than
  as objects. Q-c's ring is wider than Q-c is, including its blades.

Otherwise: Q-a palmable and shorter than the grass; Q-b two-handed; Q-c bin-lid;
Q-d chest-high furniture. Same 6× span, same defect.

### 6. Defects, set Q

Everything in P's list is present unchanged in Q — **P-D1** (the flat quad on the
mushroom, identical), **P-D2** (bush still growing through the object), **P-D3**
(blades still detached with the same left-side gap), **P-D4** (Q-a still invisible),
**P-D5** (glow still painted on the ground), **P-D6**, **P-D7**. Plus:

- **Q-D8. The rings read as UI, not as world.** Frame 01, x≈352–420 and x≈424–494.
  They are pure white, of constant stroke width, unaffected by the terrain's own
  shading or by the warm/cool light difference between the pools they sit in, and
  perfectly elliptical. That is the exact signature of an editor selection gizmo or
  an HUD decal. Nothing else in the frame is pure white at constant width — the
  meadow flowers are off-white and shaded. This is the most addressable defect in
  either set: it is one material away from reading as a design.
- **Q-D9. Rings cover 2 of 4 objects.** Frame 01. See §3 — a marker language applied
  to half a set teaches the wrong rule.
- **Q-D10. The rings sort inconsistently against the same grass in the same frame.**
  Frame 01, under Q-c, x≈440–480, y≈418–424: the near arc is chopped into dashes by
  grass blades drawing in front of it, while a few pixels away the same ring draws
  *over* blades of the same height. The ring's far arc at y≈405 also passes over the
  object's own lower body. It is not consistently a ground decal, a depth-tested
  mesh, or an overlay.
- **Q-D11. The white spike crown on Q-c reads as broken geometry.** Frame 01,
  x≈440–480, y≈390–400. Six or seven hard-edged white triangles with sharp corners
  and flat untextured faces, poking out of the top rim of the object. They do not
  taper, do not fade, and are the same flat white as the rings and the blades. My
  first read was "the mesh's normals are inverted at the top," not "this object
  sparkles."
- **Q-D12. Three different unrelated white flat shapes on one object.** Frame 01,
  Q-c has the ring, the spike crown, and the two blades — all pure white, all flat,
  all differently shaped. Whatever each is meant to be, together they read as one
  broken thing rather than three deliberate marks.

**Defect P has that Q fixed:**
- **P-D12 (P only). P-c is nearly invisible by value.** Frame 01: a pale cream mass
  on pale yellow-green sunlit grass inside a pale yellow glow. It has less contrast
  against its own light pool than the bare ground does. Q's saturation change is a
  clean fix for this, and it is the only defect either set repairs.

---

## 7. Comparative — P against Q

**Which makes the hierarchy more legible: Q, narrowly.** It carries it on one thing
and one thing only — Q-c saturated from cream to orange-gold. That single change
gives the hue ramp a warm end that is an object rather than a mushroom, separates
Q-c from the sunlit ground it was previously camouflaged against, and is the reason
Q-c is still a visible nub at 12 m (frame 02) where P-c has vanished entirely. The
rings help findability at 7 m and give Q-b and Q-c a footprint at 12 m, but they
hurt the *hierarchy* because their coverage (ranks 2 and 3, not 1 and 4) contradicts
the rank order the size and hue channels are establishing.

**Which makes the objects read more as items: split, and neither well.** Q-c is the
only object in either set that gained item-ness — the gold reads as amber or
honeycomb, a plausible thing to pocket. But Q-b and Q-c are simultaneously pushed
*away* from item-ness by their rings, which say "this is a marked location" rather
than "this is a thing." P has fewer marks, so what you see in P is the object; the
problem is that in P two of the four objects are not visible enough to be seen at
all. On balance: **P's objects are purer, Q's objects are more findable, and neither
set's objects read as one family of pickups.**

**Which has worse defects: Q, clearly.** Q inherits every one of P's seven defects
unchanged — the flat billboard quad through the mushroom cap (frame 01, x≈530–580),
the meadow bush growing straight through the third object, the detached white blades,
the painted-on glow pools, the missing contact shadows — and then adds four of its
own, three of which are the expensive kind. **Q-D8** puts a UI element into the
world; **Q-D9** applies it to half the set; **Q-D11** adds white shards that read as
inverted normals. P's defects are mostly *authoring* mistakes (an object placed on a
bush, a sprite facing wrong). Q's new defects are *language* mistakes — they teach
the player a rule that the frames then break.

**Verdict: Q is the better set,** but by a narrow and specific margin. It wins on the
one thing that matters most in this test — an object that is still an object at 12 m
— and it wins with a change (colour saturation) that costs nothing and cannot be
mistaken for UI. Its ring, spikes and blades are all separable from that win: they
can be restyled or deleted without giving the saturation back. If I had to hand one
of these forward, it would be Q with the white marks stripped.

**What sinks both:** at 17 m (frame 03, both sets) the entire collectable line is a
single band of coloured light with one mushroom cap in it. Three of the four objects
have no silhouette at 12 m and none at 17 m. Whatever the rarity design is, it is
currently carried by ground glow, and ground glow does not survive distance — the
frames prove this themselves, because the only thing that does survive is the one
object with authored three-dimensional form and a hard top edge.

---

## The three things that most separate the better set (Q) from the references

**1. The collectables are light, and the references' objects are objects.**
`palworld-02-open-field-path.jpg` and `palworld-03-field-boss-meadow.jpg` put small
props and creatures in open field at comparable distances, and every one of them
holds a dark, hard-edged silhouette against the ground — you read the shape first
and any glow second. In Q `03-lineup-cam17m` the whole lineup is one ~150 px pale
smear at y≈345 with no shape inside it, and in Q `02-lineup-cam12m` three of the
four objects are gone. The references never rely on a ground wash to tell you
something is there.

**2. Pure-white flat marks appear in the frame that appear nowhere in the art
direction.** The palette strip in `tetherbound-meadows-keyart.png` is deep greens,
ochres, warm creams, slate blues, muted violets and two reds — there is no pure
white in it, and the key art's own small ground elements (wildflower banks, rocks,
the rune stone) are all shaded and warm. Q `01-lineup-cam7m` puts three separate
pure-white constant-width shapes on one object at x≈424–494: a ring, a spike crown
and two blades. They are the brightest and coldest pixels in the frame and they are
attached to the thing that is meant to be gold.

**3. The line does not agree about scale, and the key art's ground furniture does.**
In `tetherbound-meadows-keyart.png` the streamside and settlement panels put rocks,
flowers and props beside figures at consistent, plausible sizes. In Q
`01-lineup-cam7m`, measured against the 1.80 m trainer two metres away, the same
line runs from a 0.16 m object shorter than the surrounding grass to a 1.02 m
mushroom cluster that is chest-high on him — a 6× span presented as one row of
pickups, with the largest member of it being a plant.

## The two bar questions, for set Q

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`? — No.**

The *meadow* nearly does. The rolling ground, the oak line on the right of
`01-lineup-cam7m`, the warm-to-cool green range and the white and violet wildflower
scatter are recognisably the key art's biome, and the trainer's palette (teal, cream,
brown leather) is drawn straight off the board's day panel. What sinks it is the
lineup itself. The key art has a strong value structure — deep shadow under canopies,
bright sunlit banks — and Q's glow pools do the opposite: they flatten a metre-wide
ellipse of terrain to one pale mid-tone with no falloff and no effect on the grass
standing in it (`01-lineup-cam7m`, all four pools). On top of that flattened ground
sit pure-white rings and shards that are outside the board's palette entirely. The
world reads as the key art's; the collectables read as having been placed there by a
different department.

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone say
these are trying to be the same kind of game? — No, on the strength of the
collectables specifically.**

The trainer holds up. In the `01-lineup-cam7m` crop he has a clear silhouette, a
readable costume with material variety, and he reads as bespoke, not sourced. The
meadow density in the foreground of `03-lineup-cam17m` is in the same neighbourhood
as `palworld-03-field-boss-meadow.jpg`. But the thing this test is actually about
fails the comparison outright: in every Palworld field frame, the interactive objects
are *objects* — you can point at a shape. In Q `02-lineup-cam12m`, at 12 m, three of
four are patches of coloured light on grass, and the one that reads best is a
mushroom cluster that a Palworld player would assume is scenery. Someone shown these
side by side would say the world is trying to be the same kind of game and the
pickups are not yet.

### Fixable by changing the scene

- Delete or completely restyle the white ring (**Q-D8**): warm-tinted, thin,
  terrain-shaded, and applied to **every** object in the set or to none
  (**Q-D9**). Fix its depth sorting against grass (**Q-D10**).
- Delete the white spike crown (**Q-D11**) and the white blades (**P-D3**) until
  there is authored geometry to replace them with.
- Replace the flat ground glow decal with a tight emissive rim on the mesh itself,
  and make the grass inside the pool actually receive the light (**P-D5**).
- Give every object a contact shadow or a darkened ground contact (**P-D7**), and
  root the mushroom cluster's base instead of resting it on a flat pale disc
  (**P-D6**).
- Clear a small radius of meadow scatter around each spawn point so bushes stop
  growing through objects (**P-D2**).
- Fix the billboard orientation / alpha on the sprite behind the mushroom cap
  (**P-D1**).
- Raise Q-a's **value** contrast, not its hue — it needs to be darker or lighter
  than the grass, because it will never win on green-against-green (**P-D4**).
- Normalise the four into one size band. The 6× span is a data change, not an art
  change.

### Not fixable without art that is not in the build

- **The four are not one family and cannot be tinted into one.** A rock, a lobed
  blob, and a mushroom cluster do not become tiers of one item by sharing a shader.
  This needs a designed item family with a shared silhouette grammar — a common
  base shape, a common cap or crown, a common proportion — so that hue and size can
  carry rarity *on top of* an already-established "same kind of thing."
- **No object in the set has a silhouette authored for distance.** Surviving at 12 m
  needs a vertical element, a hard top edge, and a dark base — things the mushroom
  cluster has by accident and the other three lack by construction. A brighter glow
  will not produce it; the frames already show glow failing at exactly that range.
- **Q-c's white blades are not a design.** They are the only reason the object has
  any horizontal extent at 12 m, and they are the wrong thing to be looking at.
  They need to be replaced by real geometry, not restyled.

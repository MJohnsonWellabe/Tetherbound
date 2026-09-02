# World Life — Round 2 Judge

Blind pass. No code, config, reports, or diffs were read. Judgment is from
`life_r2/sheet.png` + the 8 individual frames, compared against `life_r1/sheet.png`
+ its frames, the two keyart/hero references, the Palworld bar, and the two
creature roster boards. Scale ruler: trainer = 1.80 m.

---

## Frame by frame

### 01 — village-edge, day
One pale creature, left-mid-ground, grazing pose, small enough that at native
frame size it reads as a cream-coloured tuft of dead grass, not an animal — a
zoomed crop confirms it does have a body and small limb/ear shapes, so the
model exists, but the frame as composed does not let a player identify it.
Single individual, not a group. No second creature anywhere else in the
sizeable meadow in front of the hill.
**Vs round 1:** better — round 1 had nothing living in this shot at all.

### 01 — village-edge, night
3–4 pale/glowing specks scattered across the fence-line field. Zoomed, the
largest is the same grazing-creature model as the day frame, rim-lit by
moonlight — a legitimate idea. But at the frame's actual camera distance
every one of these reads as a firefly or lens artifact, not an animal; two of
the smaller ones look like stray bright pixels rather than any recognizable
shape.
**Vs round 1:** marginally better (round 1 was a near-empty black field) but
still fails night legibility outright.

### 02 — mill-pond-banks, day
The pond, treeline and dock are a large environment win (see below) — but the
only "wildlife" is a single pale-blue glowing cauliflower-shaped blob sitting
half in the water at the shoreline. Zoomed to 4×, it has no head, no legs, no
body mass — it reads as a particle/VFX cluster, not a creature silhouette.
Nothing else lives in or near a pond that the reference boards populate with
Puddlefin/Bobble-type water pals.
**Vs round 1:** the environment is dramatically better; the wildlife is
equally absent (round 1 had the same nothing, minus even the blob).

### 02 — mill-pond-banks, night
Same blue blob, now lit by a moon reflected on the water — a genuinely
attractive shot of the pond itself. Zero legible creatures. The far treeline
is a single flat black mass with no separation between individual trees,
which costs depth as well as any chance of spotting wildlife silhouetted
against it.
**Vs round 1:** environment much better; wildlife unchanged (none).

### 03 — band1-open-meadow, day
Two individually small, isolated pale creatures are present — one lower-left
in grazing stance, one at the treeline in a raised-head stance — both
confirmed only by zooming; at native frame size both are a handful of
off-white pixels indistinguishable from the scattered light-coloured flowers
around them. They are far apart, not a group. The horizon treeline is a
single evenly-spaced row, and the flowering shrubs are scattered in visible
diagonal rows/bands — both read as scatter-tool output rather than authored
clumping.
**Vs round 1:** enormous fix — round 1's version of this frame was a broken
green triangle wall (camera clipped into terrain geometry, completely
unusable). Any real content here is an improvement, but the wildlife itself
is still not legible.

### 04 — relay-camp, day
The best frame in the set. Two cream-and-sage wool creatures (Woolet-type)
walk together at the treeline, close enough and large enough in frame to
read immediately as animals, with a third faint reddish shape further back
adding depth. The two front creatures are in near-identical pose and gait,
which reads as a duplicated spawn rather than two animals independently
grazing, but the grouping-in-habitat idea lands. Trees here have thick,
ridged, orange-brown trunks with a visible vertical-plank texture, and a
layered, fluffy multi-blob canopy — a different tree model/material from the
one at village-edge (below).
**Vs round 1:** clearly better — round 1's version showed only a barely
visible pale smudge in the far distance and low-quality cotton-ball canopies.

### 04 — relay-camp, night
Reads as near-solid black on the sheet. Zoomed, the two wool creatures from
the day shot are visible bedded down bottom-left, and — nice detail — their
backs carry a faint green glow that is clearly meant as a night-readability
aid (matches a similar green mottling on the day creatures, so it looks like
an intentional bioluminescent-moss material, not a bug). At the frame's real
exposure and camera distance that glow is nowhere near bright enough to
register; the pair is invisible without a 4× crop.
**Vs round 1:** trees now have identifiable silhouettes against the sky
(round 1's night forest was an undifferentiated dark-teal mass); the
creature pair is a genuine idea round 1 didn't have, but is still functionally
invisible in the delivered frame.

### 05 — ridge-camp, day
Second-best frame. Three mottled grey/white armoured quadrupeds (rock-type,
matching the "Craglet" design language) are spread across the ridge at three
different distances rather than clumped in one spot — the scatter itself
reads as territory, not a spawn grid. Zoomed, the nearest has a genuinely
legible face (dark eye patches, pale cheek markings). The design's whole
point is camouflage-against-rock, and it works almost too well: at native
frame size the creatures and the plain black boulder beside them read as the
same kind of object, and only the mottled texture (vs the boulder's flat
matte black) tells them apart.
**Vs round 1:** clearly better — round 1's ridge was an empty grass plain
with no creatures at all.

### 06 — starter-beside-trainer, day
This is the frame the brief explicitly checks against the website hero
(trainer + starter side by side, looking out over the meadow), and it fails
outright: **there is no starter creature anywhere in the frame.** The trainer
stands alone in tall grass, facing away from camera-right, roughly 20% of
frame height (i.e. shot from much further back than the close hip-height
framing of both `page-board.jpg` and the keyart DAY panel), and a large flat
black boulder is composed almost directly against his shoulder, crowding the
one figure that is present. The only other object of creature-plausible
shape in frame is a tan round bundle far to the right near a fence — zoomed,
it is unambiguously a hay bale (has a cinched top and sits beside a wood
crate), not a creature.
Because no creature and trainer ever share a frame anywhere in this round,
**the scale-agreement check (creature vs the 1.80 m trainer) cannot be
performed on any of the eight delivered frames.** That is itself a gap: the
one frame built to be the ruler shot has no creature standing next to the
ruler.
**Vs round 1:** a lateral swap, not an improvement. Round 1's version of this
frame showed a large, well-silhouetted creature close to camera but with no
trainer in frame and shot from directly behind (a "the creature's back" crop,
in front of a house, off-composition). Round 2 instead shows a legible,
nicely detailed trainer model — cap, satchel, layered scout outfit reads well
in a close crop — but drops the creature entirely and frames far too wide.
Neither round has produced the actual pairing shot the brief asks for.

---

## Cross-cutting observations

- **Tree style is inconsistent between locations.** Village-edge and
  ridge-camp trees are simple dark rounded-blob canopies on thin near-black
  trunks. Relay-camp trees are a visibly different asset: thicker
  orange-brown trunks with a repeating vertical-plank bark texture and a
  fluffier, lighter, multi-lobed canopy. Sitting these two tree languages a
  few hundred metres apart in the same region reads as two different places,
  not one Meadows.
- **The mill-pond "creature" is not a creature.** Zoomed to 4×, the blue
  shoreline blob has no head/leg/body structure at all — it reads as a
  particle or foliage-shader artifact standing in for a water pal, not as a
  small or distant version of one. This is the one wildlife defect in the set
  that looks like a bug rather than a legibility problem.
- **Night readability is a real, additional idea that doesn't survive the
  frame.** The glowing green moss accents on the relay-camp night pair show
  someone thought about how a player spots wildlife in the dark — but the
  glow is too dim and the creatures too small/distant in the delivered shot
  for it to work. This is different from village-edge night, where the
  "creatures" are closer to unidentifiable light specks with no clear
  silhouette at all.
- **Every legible creature in this round is a duplicate pair in matching
  pose** (the two wool creatures at relay-camp walk in an identical stance;
  nothing in the set shows independent grazing/wandering variety the way the
  brief's "living groups" language implies).
- **Environment quality has taken a large step up independent of wildlife**:
  the mill pond went from a flat cyan plane with cotton-ball trees to a
  believable tree-ringed pond with a dock and workable depth; the open
  meadow went from a broken clipped-geometry frame to a usable rolling
  landscape; relay-camp and ridge-camp both gained real tree/prop density.
  None of this environment progress is reflected in wildlife presence or
  legibility, which lags well behind it this round.

---

## Three biggest gaps vs the references, ranked

1. **The hero pairing shot has no creature in it at all**, where
   `site/img/page-board.jpg` and the keyart DAY panel both show trainer and
   starter standing close together, comparable in scale, both facing the same
   vista. Frame 06 shows a small, distant, solo trainer next to a boulder and
   a hay bale. This is the single most directly checkable failure in the
   brief and the round does not clear it.
2. **No frame shows a legible living group at gameplay-viewing distance.**
   The Palworld bar (`palworld-03/04`) reads multiple pals at a glance from
   normal play distance, distinct from each other and from terrain. Here the
   only two frames with recognisable creatures (relay-camp day, ridge-camp
   day) only become legible once cropped and zoomed 3–4×; at the frame's own
   scale every creature in the set is a few dozen pixels of texture
   indistinguishable, at a glance, from a grass clump, a flower, or a rock.
3. **Night is functionally empty of wildlife.** The keyart NIGHT panel
   (moonlit trainer+companion, warm firelight in the distance) shows a world
   that stays legible after dark. All three night frames here (village-edge,
   mill-pond, relay-camp) drop below the brightness/contrast needed to see
   any creature that is present, even where a rim-light/glow treatment was
   clearly intended (relay-camp's green moss glow).

## Bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?**
**No.** The terrain, water, sky and (now) the tree canopies are in the right
palette family and the rolling-hills/pond/oak-grove language is present and
much closer than round 1. But the keyart's defining beat — a visible trainer
standing shoulder-to-shoulder with a clearly-scaled companion creature,
looking out at the land — is the one shot this round was asked to reproduce
and it has no companion in it. A world can match a palette and still not
read as *this* world without the pairing that the keyart itself leads with.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be
the same kind of game?**
**No.** Every Palworld reference frame has multiple, differently-typed
creatures immediately legible at normal viewing distance, several close
enough to fill a meaningful fraction of the frame. Here, seven of eight
frames need a 3–4× digital zoom before a viewer can tell a creature from a
rock or a weed, and one "creature" (the mill-pond blob) isn't a creature
shape at all. The environment density (grass, trees, terrain form) has
closed real ground on Palworld this round; the animal life that would make
it read as a creature-collecting game has not.

## Fixable-by-scene vs needs-new-art

**Fixable by scene (composition/camera/lighting/exposure — no new assets
required):**
- Frame 06: reframe closer, move the boulder out of the shot line, and place
  the intended starter creature beside the trainer at matching depth — the
  trainer model itself is good enough to carry a close shot.
- All night frames: raise the ambient/moon light floor near ground level, or
  boost the existing green/rim-glow accent already authored into the
  relay-camp creature material, so a creature that already has a legibility
  treatment actually shows it.
- Creature placement generally: bring camera or spawn distance for wildlife
  frames closer, and place 2–3 creatures at readable distance rather than
  scattering singles across a wide field — village-edge and open-meadow both
  have working creature models that are simply too far/small in the chosen
  shot.
- Duplicate-pose pairs (relay-camp wool creatures): stagger idle/graze
  animation phase between instances so a pair doesn't read as one clone.
- Tree-asset mismatch between village-edge/ridge-camp and relay-camp: pick
  one trunk/canopy language for the region.

**Needs new art or a real asset/behavior fix (not a camera or lighting
change):**
- The mill-pond blob is not a creature mesh with a legibility problem — it
  has no discernible body at all and needs an actual water-pal model (or the
  particle effect standing in for one needs to be replaced, not just
  brightened).
- General creature silhouette contrast against grass: several models
  (village-edge grazer, ridge-camp Craglet) use pale, low-saturation, mottled
  materials close to the terrain's own tonal range — this is a material/palette
  choice on the asset, not something a camera move fixes, and it is the
  reason even the "good" frames in this round only read once zoomed.

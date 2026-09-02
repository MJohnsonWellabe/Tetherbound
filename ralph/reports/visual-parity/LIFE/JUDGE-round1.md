# Visual Judge — WORLD LIFE, round 1

Blind pass over `/tmp/.../scratchpad/life_r1/` (9 frames + sheet.png) against
`docs/reference/tetherbound-meadows-keyart.png`, `site/img/page-board.jpg`,
the `docs/reference/palworld-0*.jpg` set, and the Meadows roster boards
(`docs/art/reference/05_...png`, `08_...png`). No code, config, or diffs were
read. Nothing here is scored — these are addressable defects, named by frame.

## Per-frame findings

**01-village-edge-day** — I can find at most one candidate creature: a small
tan blob roughly center-left of the frame, tucked beside a dead tree and a
dark boulder. Its silhouette is completely ambiguous — it could equally be a
rock, a stump, or an animal; there is no ear, leg, or head shape that
separates it from the foreground clutter. Two more dark round shapes just
right of the big boulder read as rocks, not creatures (same value, same
texture as the boulder beside them). Net result: this "village edge" reads as
empty of wildlife, not populated by it.

**01-village-edge-night** — Trainer is clearly readable center-frame. The
same ambiguous blob sits just to his left, now even harder to read against
the near-black grass — at this point it is pure guesswork whether it is a
creature at all. A saturated green glow at right (~x730,y330) has no
attached silhouette; it reads as a stray light/particle artifact, not a
creature with eye-shine or a glow trait.

**02-mill-pond-banks-day** — Exactly one creature: a blue rounded blob
parked directly in front of the mill's front door, at the shoreline. It is
not grazing, wandering, or oriented toward anything — it's a single static
prop plunked at the most obvious landmark in the shot. There is no second
individual anywhere on the bank, so "living group in a habitat" does not
apply here at all; it's a lone placeholder presence.

**02-mill-pond-banks-night** — Same single blue blob, same static pose at
the same spot. It's actually the most *legible* creature in the whole set at
night — its saturated blue holds a value break against the dark water and
shoreline — but legibility of a single unmoving prop doesn't answer the
brief, which asked for groups.

**03-band1-open-meadow-day** — This frame is not a scene. It is a solid
teal/green field of faceted polygon-shard noise covering the entire frame,
top to bottom — no sky, no ground, no trees, no creatures, nothing
recognizable. This is the frame that was supposed to show the open-meadow
"band 1" wildlife grouping, arguably the single most important test in this
set (open grassland is where Palworld puts its herds), and it delivers a
broken texture instead of a picture. This has to be re-captured before any
open-meadow wildlife judgment is possible.

**04-relay-camp-day** — Two small tan/cream quadrupeds are visible together
under the tree canopy at left (~x340–400, y330–360) — the only frame in the
set where two creatures are actually grouped side by side, which is the
right instinct. But they are wedged into deep tree shadow, and their tan
coloring is close in value to the brown trunks and dark undergrowth around
them — at anything like 30% zoom they disappear. The wide, well-lit grass
apron to the right of the path, which is exactly where a "grazing group"
would read best, is empty.

**04-relay-camp-night** — No creature reads with any confidence. There is a
pale, vaguely humanoid-to-blobby smear near center (~x580,y270) that could be
a creature standing up, a lit rock, or a foliage clump caught by moonlight —
its edges are too soft and its shape too generic to identify.

**05-ridge-camp-day** — I cannot find a legible creature in this frame at
all. There are two dark, mottled, rounded masses mid-frame (~x490–560,
y280–300) that read exactly like the boulders seen elsewhere in this set —
same grey-brown value, same lumpy silhouette, no visible legs, ears, or head.
If wildlife is present here it is not distinguishable from terrain rocks;
if it isn't present, a location that was explicitly commissioned as a
"ridge camp" wildlife frame shows no wildlife.

**06-starter-beside-trainer-day** — This frame does not contain the trainer.
It is a tight rear crop of a tan-furred, green-cracked-shell-backed
quadruped walking away from camera, flanked by a house wall on the left and
a stone pillar on the right. There is no human figure anywhere in the shot.
This is the one frame explicitly asked to reproduce the approved
`page-board.jpg` hero pairing (trainer and companion standing shoulder to
shoulder, both fully in frame, facing outward over a vista together) and the
composition attempted here has nothing in common with it — different
framing, different distance, no second figure, no vista. Because the trainer
is absent, the mandated 1.80 m scale-agreement check cannot even be
performed on this frame: there is no ruler in the picture.

## Cross-cutting problems

- **Density.** Across nine frames the creature count is: 1 (ambiguous), 1
  (ambiguous), 1, 1, broken, 2, 0 (ambiguous), 0 (rocks, probably), 1 (no
  trainer). Nowhere does a "herd" or "flock" appear. Compare
  `palworld-01-boss-fight-forest.jpg` and `palworld-05-base-building.jpg`,
  both of which put multiple distinct, characterful creatures in frame at
  once, several visibly interacting with the player or a base. This batch
  reads as "one wildlife token was placed per location," not as a habitat.
- **Silhouette separation.** None of the placed creatures carry any rim
  light, outline, or contrasting ground treatment to pull them off grass,
  shadow, or rock. The roster board (`08_Meadows_Roster_Art_Reference.png`)
  designs are clean, color-blocked mascot shapes meant to read instantly;
  what's on screen here are same-value, low-contrast blobs that blend into
  the nearest rock or trunk (worst in 01-day, 01-night, 04-night, 05-day).
- **Foliage noise compounds the problem.** The trees throughout this set
  render as jagged, shredded-paper shard clusters (visible on the sheet in
  every daytime frame). Because the tree canopies and trunks already read as
  visual noise, a creature silhouette has to fight harder for separation
  than it would against a clean canopy — and currently it's losing that
  fight everywhere except the mill pond's blue blob against open water.
- **Behavior/pose.** Every visible creature is a static, single stance — no
  grazing head-down pose, no group members facing different directions, no
  sense of an animal doing anything. The mill-pond individual in particular
  looks placed rather than living: centered on the shoreline, facing the
  camera, directly in front of the one architectural landmark in the shot.

## Ranked: the three biggest gaps vs. the references

1. **Frame 03 is not a picture.** The open-meadow frame — the one location
   type where the references (Palworld's fields, the keyart's rolling
   grassland) most clearly show grouped wildlife — renders as a solid
   corrupted polygon-shard texture with zero scene content. This is a
   rendering failure, not an art-direction gap, but it means the single most
   important test case in this batch produced no evidence at all.
2. **There is no group anywhere in this set.** The keyart names "Wildlife"
   as one of its five pillars and page-board.jpg sells a living companion
   standing beside the trainer; Palworld's references show multiple
   creatures per frame, several actively doing something. This batch's
   maximum is two creatures (04-day), and even that pair is barely visible
   in shadow. Every other location has at most one ambiguous blob or none.
   The brief asked for "grazing/wandering, grouped, right species for the
   place" and none of the nine frames deliver more than one legible
   individual.
3. **Frame 06 doesn't attempt the pairing it was asked to reproduce.** The
   approved hero shot in `page-board.jpg` is trainer-and-companion,
   shoulder to shoulder, both fully visible, looking out together. Frame 06
   is a rear-view creature crop with no trainer in it at all — it isn't a
   near-miss on that reference, it's a different photo of a different
   moment.

## Bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?** — **No**, specifically on
the axis this batch was built to test. The terrain, foliage palette, water,
and half-timbered village architecture broadly agree with the keyart's
rolling-hills-and-oak-groves look (that part is fine). But the keyart's DAY
and NIGHT companion panels, and its named "Wildlife" pillar, promise a world
with visible, present creatures next to the trainer and in the landscape.
Across this set that presence is reduced to, at best, one static blob per
location, several of them indistinguishable from rocks, plus one frame that
doesn't render at all and one that drops the trainer entirely. The world's
skeleton matches; the life the keyart is named for does not show up.

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would
someone say these are trying to be the same kind of game?** — **No.** The
Palworld shots are dense with legible, characterful, multiple creatures per
frame, several mid-action or working alongside a base. This batch's frames
are mostly empty of legible wildlife, with one broken frame and one that
omits the player character it was scoped to include. Nothing here shows the
"world full of creatures" that is the entire premise of the comparison.

## Fixable-by-scene vs. needs-new-art

**Fixable by changing the scene (placement, density, lighting, composition):**
- Re-run/repair frame 03 — a corrupted full-frame texture is a capture or
  scene-load failure, not an art problem; it needs to be re-captured, not
  redesigned.
- Raise per-site creature count to visible clusters (3+) instead of 0–2, and
  vary orientation/pose so they don't all read as a single planted token.
- Move creatures out of full tree shadow onto lit ground (Relay Camp) so the
  pairing that's already grouped correctly can actually be seen.
- Recompose frame 06 as a wide two-shot with both trainer and creature in
  frame, mirroring page-board.jpg's shoulder-to-shoulder framing and
  distance from camera — this also restores the ability to run the mandated
  1.80 m scale check.
- Add a rim-light pass, or place creatures against a contrasting ground
  material (bare dirt, water's edge, short mowed grass vs. the surrounding
  tall grass) so silhouettes separate from background noise, especially at
  night.
- Investigate whether Ridge Camp is actually spawning a creature at all —
  if the two dark shapes in 05-day are rocks, that site currently ships with
  zero wildlife, which is a placement gap fixable in scene/spawn data.

**Likely needs new art or model work (not fixable by scene changes alone):**
- The creatures that are visible (mill pond's blue blob, Relay Camp's tan
  pair, the 06 rear-view creature) read as simple, low-contrast, rounded
  blob forms with no visible eyes, markings, or silhouette flourishes — they
  don't carry the roster board's (`08_Meadows_Roster_Art_Reference.png`)
  clean, color-blocked, instantly-readable mascot design language. If these
  are the production models rather than stand-ins, closing that gap is a
  modeling/shading task, not a scene-lighting one.
- The 06 creature is only ever seen from behind, so its face/identity can't
  be confirmed against any specific roster entry from this frame alone —
  worth a second frame from the front before judging the model itself, but
  as delivered it reads as a generic tan-and-shell quadruped rather than a
  specific, recognizable starter.

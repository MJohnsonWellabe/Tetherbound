# Visual judge — PLACES, round 1

Blind pass. No code, config, diffs, or history read. Judged from
`sheet_before.png`, `sheet_round1.png`, and individual frames in
`00-before/locations/` and `round1/locations/`, against
`docs/reference/tetherbound-meadows-keyart.png`, the `palworld-0*.jpg` set,
`site/img/page-board.jpg`, and `docs/reference/README.md`.

---

## Grandpa's village (01-*)

**Day** (`01-village-approach-day`, `01-village-standing-day`,
`01-village-tournament-day`, `01-village-twins-day`,
`01-village-grandpa-yard-day`, `01-village-route-out-day`) reads correctly as
an inhabited frontier settlement on first look: warm terracotta and dark-timber
roofs against green, a well, a signpost reading two shop names, barrels and
firewood stacked at building corners, NPCs placed at doorways and paths. This
is the set that most clearly earns its "cozy and inviting" brief from the key
art's STARTING SETTLEMENT panel. Population is restrained — two to three NPCs
per frame — which respects the owner's "must not feel over-populated" rule.

Defects:
- **`01-village-approach-day`**: the tree at right has flat, papery canopy
  cards with visible cut edges and z-fighting facets — it reads as a cardboard
  cutout beside the fully-modelled buildings in the same frame. This is the
  single worst silhouette failure in the village set: at 30% it is the first
  thing the eye catches, and it catches it as a bug.
- **No frame in the village set shows a gate.** `01-village-approach-day` and
  `01-village-route-out-day` are the two frames that plausibly frame a road in
  or out of the settlement, and neither shows a gate structure — just open
  fence line and grass. The owner's rule is explicit that every road out of
  the village has a gate; on this evidence it does not.
- **`01-village-tournament-day`**: two roadside banner posts (green) flank the
  path with nothing between them — they read as forgotten placeholder posts
  rather than an entrance, sign, or checkpoint. If these are meant to be gate
  posts, they need actual gate geometry between them; right now they are two
  unconnected sticks.
- **`01-village-twins-day`**: the near house's roof tiles show a hard moiré/
  banding pattern under the ridge line — a texture-resolution artefact, not a
  material choice, and it's the kind of thing that reads as broken at any
  viewing size.

**Night** (`01-village-approach-night`, `01-village-standing-night`,
`01-village-tournament-night`, `01-village-twins-night`,
`01-village-grandpa-yard-night`, `01-village-route-out-night`) hits the
"peaceful by day, mysterious by night" brief the key art asks for: lit windows
read as warm points against a cold blue field, which is the correct night
language for this genre. Two problems:
- **`01-village-grandpa-yard-night`**: the two NPCs standing in the yard are
  in near-total silhouette with no rim or fill light separating them from the
  black grass in the lower third of the frame — the girl's dress is legible,
  the boy beside her is a black shape with no readable face or pose. This is
  a readability failure, not a mood choice.
- **`01-village-approach-night`**: the same tree that reads as a cardboard
  cutout in daylight is worse at night — its canopy is bright pale cyan
  against a dark sky, which makes the geometry fault more obvious, not less.

**Before/after**: unchanged. Every village frame in `round1` matches its
`00-before` counterpart pixel-for-pixel in composition and content. Neither
better nor worse — this place was not touched this round.

---

## Burrow Warrens (04-*)

`04-warrens-approach-day` and `04-warrens-standing-day` read correctly as a
creature den: a mounded boulder pile with dark, low openings cut into it,
grass path leading up, no building language anywhere near it. This is good
landmark silhouette work — from a distance it reads as "lair," not "house" or
"ruin," which is exactly the job.

**`04-warrens-den-day` is broken.** The frame is not a den interior — it is a
flat teal-green fill with faceted diagonal shading bands and a small dark
gabled shape in the bottom-left corner, consistent with the camera being
clipped inside collision geometry (a wall, a canopy, or a roof plane) rather
than looking at anything the player is meant to see. There is nothing to judge
here as art direction; it is a broken shot.

**Before/after**: identical. `00-before/locations/04-warrens-den-day.png` shows
the same broken green-fill frame, same composition, same small dark shape in
the corner. This is a persistent camera/framing fault, not something round 1
introduced or fixed.

---

## Trail camp (05-relay-camp-*)

This reads well as a camp. `05-relay-camp-fire-day` and
`05-relay-camp-standing-day` both give a legible fire focal point (the
campfire glow is the brightest, warmest element in each frame and sits at
roughly frame-center), a supply crate, a bedroll/tent, and a marker flag —
props read as placed, not dumped: the crate sits under the flagpole like
someone set up a checkpoint, not like the scatter tool fired at random.
`05-relay-camp-standing-day` additionally reads a genuine sense of place —
gnarled dead-looking trees ringing a clearing, dappled light — this is one of
the strongest single frames in the set.

Watch item, not a hard defect: the camp's flag (`05-relay-camp-fire-day`,
`05-relay-camp-standing-day`) is a dark wine-maroon, distinctly darker and
more purple than the bright orange-red oxblood on the Team Tether banners at
the stronghold (`10-stronghold-courtyard-day`) — sampled colour is roughly
(65,7,22) at the camp versus (138,37,27) on the stronghold banner. They are
visually distinguishable side by side, so this does not yet read as the
reserved danger colour leaking onto a friendly location, but the two reds are
close enough in family that they should stay clearly separated as more red
props are added rather than drifting toward each other.

**`05-relay-camp-approach-night`** and **`05-relay-camp-standing-night`** read
correctly as camp-at-night: fire glow as the only warm point in a cold field,
moon overhead. Legible and on-brief.

**Before/after**: unchanged across every frame in this set, including the
fire-day frame — no regression, no improvement.

---

## Team Tether Relay site (06-relay-*)

This is the weakest place in the set against its own brief. The brief calls
for an ACTIVE hostile Team Tether operation; what's on screen in the frames
that do render is an unstaffed set of pylons under a stone pergola.
`06-relay-standing-day` and `06-relay-apparatus-day` show the black-and-gold
tech pylons with teal glow correctly established as Team Tether hardware (the
material language matches the pylons already established at
`09-waystop-approach-day` and `10-stronghold-approach-day`, so the kit reads
consistently across places) — but there is no Team Tether presence here: no
grunt, no oxblood banner, no barricade, no sign of activity. Compare
`10-stronghold-courtyard-day`, which puts a masked grunt guard, crates, an
anvil, and banners in frame and reads as occupied on sight. The relay site
reads as abandoned ruins with equipment left behind, not as a hostile
operation in progress.

- **`06-relay-standing-day`** and **`06-relay-apparatus-day`**: the sun disc
  is a blown-out pure-white circle with no falloff, sitting in the upper third
  of both frames — this is a bloom/exposure artefact, not a lighting choice;
  it reads as a rendering bug on a still.
- **`06-relay-apparatus-day`**: the framing is tight enough on the pergola
  structure that the pylons read as ruins with tech bolted in, which is
  correct per CLAUDE.md's language for the Hall — but there's no NPC, banner,
  or activity cue anywhere in frame to make it read as "active" rather than
  "abandoned."

**`06-relay-approach-day` is broken**, the same way the warrens den frame is:
a flat green fill with light-green triangular facets, consistent with the
camera clipped inside terrain or canopy geometry. Nothing to judge as
direction — it's not a shot.

**Before/after**: unchanged. Both the broken approach frame and the
unstaffed-but-rendering frames match `00-before` exactly, including the blown
sun disc (slightly larger in `00-before`, still blown in both). No regression,
no fix, and the "active hostile operation" gap was already present before this
round and remains present now.

---

## Ridge camp (08-*)

`08-ridge-camp-approach-day`, `08-ridge-camp-fire-day`, and
`08-ridge-camp-standing-day` all read as a working camp: a bedroll,
storage crate, campfire with visible flame, a seated NPC, a standing tent —
props cluster together the way a camp actually would rather than scattering
evenly across the clearing, which is the right kind of intentionality per the
owner's "props must look placed, not dumped" rule. A distant flying creature
silhouette in `08-ridge-camp-fire-day` gives the frame some life without
crowding it.

Defects:
- **`08-ridge-camp-approach-day`**: the tree canopies in the mid-ground are
  the same flat papery-card geometry seen in the village set, and here there
  are six or seven of them ringing the clearing — at 30% the whole background
  reads as a wall of identical pale-green cutouts rather than a treeline with
  any variety.
- **`08-ridge-camp-fire-day`**: the campfire itself is a small glow with no
  visible logs/fire pit ring underneath it — it's legible as a light source
  but not as a built fire, which undercuts the "camp" read slightly next to
  the crate and bench that are clearly built furniture.

**Before/after**: unchanged across the set — same content, same framing, same
tree-cutout issue in both rounds.

---

## Waystop (09-*)

`09-waystop-approach-day`, `09-waystop-bench-day`, and
`09-waystop-standing-day` do real work this round: the stronghold silhouette
and a dark smoke column sit in the background of all three frames, so the
waystop reads correctly as a threshold place — a rest point with the coming
danger visibly staged behind it. `09-waystop-standing-day` in particular pairs
a lit campfire, a bench, and the Team Tether pylon kit in the same frame
without them competing, and the smoke plume against blue sky is a genuinely
good staging choice that neither the village nor the relay site frames
manage for their own danger cues.

Defects:
- **`09-waystop-bench-day`**: the tent in the foreground is a flat brown
  triangular card with no visible fabric fold or stake — at speed it reads as
  a rock or crate before it reads as a tent.
- Same blown-white sun disc artefact recurs here as in the relay-site frames,
  slightly softer.

**Before/after**: unchanged — same three frames, same content, in both
rounds.

---

## Meadows Hall / stronghold (10-*, 11-*)

This is the best-executed place in the set against its own brief, and the one
that most looks like the CLAUDE.md description ("ancient ruin reclaimed by
nature with Team Tether industry bolted onto it, never a clean cream castle").
`10-stronghold-courtyard-day` gets almost everything right in one frame: mossy
stone walls, ivy climbing the interior, oxblood Team Tether banners with a
clear roundel symbol, a masked grunt standing guard, an anvil, crates, and a
teal energy-beam prop cutting across the yard floor. It reads as occupied,
hostile, and industrial-on-ruin without needing a caption. `10-stronghold-gate-day`
gives a good exterior read too — grey stone, moss patches, ivy, a red banner
on the wall, dark storm cloud sitting directly over the keep while the rest of
the sky stays blue. That's a real day/danger-mood contrast working correctly
in a single frame.

Defects:
- **`10-stronghold-approach-day`**: the stronghold itself is small and
  centred under a heavy soot-black cloud bank that reads more like a
  rendering/fog artefact than a storm — the transition from blue sky to that
  flat dark mass is a hard edge, not a gradient, and it doesn't match the
  softer cloud language used everywhere else in the sheet.
- **`10-stronghold-gate-day`**: the castle towers and walls read clean and
  grey rather than moss/ivy-covered the way the courtyard interior does — the
  "reclaimed ruin" language established inside the walls doesn't carry to the
  exterior silhouette, which risks landing closer to the "clean cream castle"
  the owner explicitly ruled out. It isn't cream, but it is closer to a tidy
  storybook castle than a ruin from this angle.
- **`11-castle-landmark-approach-day` and `11-castle-landmark-banners-day` are
  effectively empty frames** — despite their names, neither shows any castle,
  wall, or banner. Both are just grassland and a mossy hill mound with the
  player standing in an empty field. Whatever landmark or banner these shots
  are meant to establish is out of frame or not yet placed. This is a
  significant gap against the "landmark visible from distance" brief in the
  key art's own art notes, and it's the kind of miss a 30%-scale check would
  catch instantly: there's no landmark in the landmark shot.
- **`11-castle-landmark-gate-day`** does show the castle (crenellated towers,
  red banners, ivy, a covered bridge approach) and is a good frame — it's the
  two frames above it that are missing their subject.

**Before/after**: unchanged across all six frames in this pair of places,
including both empty landmark frames and the blown-sun highlight visible
faintly in `10-stronghold-approach-day`. No regression, no fix.

---

## Ranked: the three things that most separate these frames from the references

1. **The Relay site does not read as an active hostile operation, and the
   castle "landmark" shots don't show a landmark at all.** The key art's
   TEAM TETHER STRONGHOLD panel and the "landmarks visible from distance"
   art note both promise a readable, occupied threat. The stronghold
   courtyard delivers that; the relay site (`06-relay-standing-day`,
   `06-relay-apparatus-day`) is unstaffed hardware with no banner or guard,
   and `11-castle-landmark-approach-day` / `11-castle-landmark-banners-day`
   show no landmark whatsoever. This is the largest gap between what the
   place is supposed to communicate and what the frame actually shows.
2. **Two frames are not scenes at all** (`04-warrens-den-day`,
   `06-relay-approach-day`) — flat colour fills with faceted shading,
   consistent with the camera clipped inside geometry. No amount of palette
   or composition judgement applies; these need to be re-shot from a working
   camera position before they can be judged as places at all.
3. **Flat, papery tree-card geometry recurs across three different places**
   (the foreground tree in `01-village-approach-day`/`01-village-approach-night`,
   the treeline ringing `08-ridge-camp-approach-day`) and is the loudest
   silhouette failure at small size in an otherwise fairly readable sheet —
   these read as cut paper standees next to the fully-volumetric buildings
   and props in the same frames.

## The two bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?** **Partially — call it a soft yes for the
village and stronghold, no for the relay site and landmark shots.** The
village day/night pair and the stronghold courtyard genuinely land the key
art's palette, silhouette language, and "cozy by day / mysterious by night"
mood, including the reserved oxblood staying on Team Tether banners only. But
the key art's own named STARTING SETTLEMENT and TEAM TETHER STRONGHOLD panels
promise gated boundaries and a visibly landmark-scaled hostile fortress, and
this sheet doesn't deliver a gate anywhere in the village or a legible
landmark in the two frames named for exactly that job. It's not a clean pass.

**B. Shown these frames beside `palworld-0*.jpg`, would someone say these are
trying to be the same kind of game?** **Yes.** Ground and foliage density in
the camp and waystop frames is close to the Palworld reference's grass and
prop density (`palworld-05-base-building.jpg`), the trainer silhouette reads
clearly against terrain in every daylight frame, and the stronghold courtyard
in particular has the "world with visible faction presence" quality the
Palworld shots establish. The broken frames and empty landmark shots would
read as bugs in a comparison, not as a different genre — someone would say
"this is trying to be Palworld-adjacent and mostly getting there, with some
things clearly not finished," not "this is a different kind of game."

### Fixable-by-scene vs needs-new-art

**Fixable by changing the scene** (camera, placement, lighting, exposure —
no new assets required):
- Blown-out sun disc in `06-relay-standing-day`, `06-relay-apparatus-day`,
  `09-waystop-standing-day`, and faintly `10-stronghold-approach-day` — an
  exposure/bloom clamp.
- The two broken green-fill frames (`04-warrens-den-day`,
  `06-relay-approach-day`) — a camera reposition, since the props and terrain
  clearly exist and render correctly elsewhere.
- The two empty landmark frames (`11-castle-landmark-approach-day`,
  `11-castle-landmark-banners-day`) — if the castle model and banners already
  exist (they clearly do, per `11-castle-landmark-gate-day`), this is a camera
  placement fix, not new art.
- Missing gate on the village roads — if a gate asset exists anywhere in the
  build (the stronghold's has one), placing it on the village exit road is
  scene work, not new art.
- Staffing the relay site with a guard, banner, or barricade to read as
  active — the grunt NPC and oxblood banner assets already exist and are used
  correctly at the stronghold; this is placement, not creation.
- The hard-edged storm cloud over `10-stronghold-approach-day` and the clean
  (non-ivy) exterior read of `10-stronghold-gate-day` — likely a fog/cloud
  volume tune and moving some of the courtyard's ivy/moss decoration to the
  exterior wall meshes.

**Needs new art** (not achievable by re-staging what's already in the build):
- The flat, faceted "cardboard" tree canopy geometry seen in
  `01-village-approach-day`/`night` and ringing `08-ridge-camp-approach-day`.
  This is a mesh/material problem with the tree asset itself — no camera or
  lighting change fixes a canopy that reads as cut paper card up close.
- The roof-tile moiré banding in `01-village-twins-day` is a texture
  resolution/mipmap issue on that specific material, not a staging fix.

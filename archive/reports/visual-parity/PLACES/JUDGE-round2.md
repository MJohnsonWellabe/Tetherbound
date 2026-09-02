# PLACES — Round 2 visual judgement

Blind pass over `places_r2/sheet_round2.png` and the 27 individual frames in
`places_r2/locations/`, against `docs/reference/tetherbound-meadows-keyart.png`
(STARTING SETTLEMENT and TEAM TETHER STRONGHOLD panels), the `palworld-0*.jpg`
set, and `site/img/page-board.jpg`'s castle panel. Compared against round 1
(`places_r1/round1/locations/`, `places_r1/sheet_round1.png`) frame-by-frame
where an equivalent frame exists.

No code, config, or diffs were read for this pass.

---

## 1. Grandpa's village (01-*, 12 frames)

**Reads as intended?** Yes, largely. Consistent half-timber architecture,
warm orange/dark tile roofs, low fences, a well, signposts ("The Rise",
"The Inn") — this is recognisably the keyart's STARTING SETTLEMENT cluster,
and it is not over-populated: a handful of named NPCs (grandpa, the twins,
tournament figures) scattered around discrete yards rather than a crowd.

**Defects**

- `01-village-approach-day`: the tree filling the upper-right corner renders
  as a faceted, semi-transparent, pale mint/white crystalline canopy —
  reads as broken alpha-cutout geometry, not foliage, and clashes hard with
  the warm saturated roofs and grass below it. The same canopy look recurs,
  smaller, in `01-village-standing-day` and dominates the flanking tree
  clusters in `01-village-tournament-day`.
- `01-village-approach-night`, `01-village-standing-night`,
  `01-village-twins-night`: the moon is a flat, hard-edged pale disc with no
  surface detail or soft glow falloff — reads as a 2D sticker pasted on the
  sky.
- `01-village-twins-night` and `01-village-route-out-night`: house walls go
  near-total black silhouette with only window glow — no ambient/fill light
  reaches the walls at all, so buildings read as flat cutouts. Contrast
  `01-village-grandpa-yard-night`, where the near wall does pick up some
  light; the treatment is inconsistent house-to-house within the same
  village.
- `01-village-route-out-day`: composition is filled almost entirely by the
  well-canopy roof and a shed roofline; for a location named "route out"
  there is no road, fence line, or gate visible leading away from the
  village — nothing here reads as an exit, let alone a gated one (owner
  rule: a gate on every road out).
- `01-village-tournament-day`: the signboard text is an illegible pixel
  smear at this distance — if it's meant to communicate an event to the
  player, it doesn't.
- `01-village-standing-day` / `01-village-twins-day`: ground cover near the
  camera is thin, sparse blades rather than the dense wildflower meadow the
  keyart and Palworld references show.

**vs round 1**: unchanged. Same compositions, same foliage-canopy artifact,
same flat moon, same lighting per house. No regression, no fix applied.

---

## 2. Burrow Warrens den (04-*, 3 frames)

**Reads as intended?** The exterior does; the interior is now legible but
flat. `04-warrens-approach-day` gives a strong rounded boulder-mound with a
dark recessed doorway — a clear, distinct den silhouette against open
grassland, satisfying "creature den entrance with an authored exterior."

**Defects**

- `04-warrens-den-day`: the fern/leaf prop beside the creature is a flat,
  sharp-edged 2D billboard cutout, unshaded — clashes with the otherwise 3D
  stone walls and creature model, reads as placeholder set dressing.
- `04-warrens-den-day`: lighting is uniform and shadowless — the overhead
  beams cast nothing onto the walls or floor, and the badger-creature itself
  is lit almost frontally with no directional modelling, so a chamber with
  decent geometry still reads flat.
- `04-warrens-standing-day`: a hard-edged, perfectly flat light-grey slab
  sits among the mottled rock geometry at right — its uniform tone and crisp
  rectangular top read as a UI/skybox leak or unlit plane, not rock.
- `04-warrens-approach-day`: the entrance boulder-mound sits directly on
  flat grass with no transition — no scree, dirt apron, or worn threshold —
  so it reads as a rock dropped onto the terrain rather than a landform the
  terrain grows out of.

**vs round 1**: substantially better. `04-warrens-den-day` was a fully
broken, unusable solid-green shader-error frame in round 1 — this round
replaces it with an actual (if flatly lit) den interior with a creature in
it. This is the single biggest fix in the set. `04-warrens-approach-day` and
`04-warrens-standing-day` are essentially unchanged.

---

## 3. Team Tether Relay (06-*, 3 frames)

**Coverage note**: round 1 additionally supplied five `05-relay-camp-*`
frames (approach/fire/standing, day+night) showing a staked maroon banner,
a supply crate, and two NPCs talking by a campfire in open grass. Round 2
drops all of those and keeps only the three `06-relay-*` frames centred on
the megalithic gate/pylon structure, so this round can only speak to the
gate/apparatus, not to any camp perimeter that existed as a separate beat.

**Reads as intended?** Partially. The gate itself — a stone post-and-lintel
structure with black-and-gold ornamented pylons, glowing teal cable-arcs,
and a hulking dark tendrilled apparatus on top — is a strong, alien
silhouette distinct from the village's warm cottages, and the maroon banner
plus stacked crates in `06-relay-approach-day` are a good faction-identity
touch. But it does **not** read as an active, staffed operation.

**Defects**

- `06-relay-apparatus-day`: badly composed — the camera looks almost
  straight up into a blown-out white sun filling a third of the frame, the
  trainer is clipped onto the flat roof of the stone lintel (standing where
  no floor should plausibly read as walkable), and none of "personnel,
  clutter, cables, barriers" is visible. Reads as a lighting/camera bug, not
  a documented location.
- `06-relay-approach-day`: the only human presence is three small,
  indistinct silhouettes deep in the background near the apparatus —
  nothing reads as "personnel" at this distance (no posture, uniform
  colour, or visible task), and there is no barrier, fence, or checkpoint
  dressing at the gate threshold itself despite the crates implying a supply
  point.
- `06-relay-standing-day`: the two cyan cable-arcs are perfectly smooth,
  uniform-width glowing lines with no sag, connector, or visible anchor
  where they meet the pylons — reads as a 2D line-renderer overlay, not a
  physical cable, which undercuts the "grafted industry" read the location
  needs.
- Across all three `06-*` frames: no tents, bulk-stacked crates/barrels,
  warning signage, or barrier tape — the location reads as "ancient ruin
  with strange machinery," not as an occupied, active operation with a
  workforce, which the brief specifically calls for.

**vs round 1**: same, net. `06-relay-apparatus-day` and
`06-relay-standing-day` are essentially identical in composition and content
to round 1 (same up-angle sun/roof-clip bug, same empty-of-personnel gate).
`06-relay-approach-day` is a new framing this round and a genuine
improvement — it finally shows the gate as a crossable entrance with crates
and a banner — but losing the round-1 campfire/camp frames means this round
has *less* evidence of an occupied camp than round 1 offered. Net: no better
established as an active hostile operation, just reframed.

---

## 4. Meadows Hall / stronghold (10-*, 11-*, 9 frames)

**Reads as intended?** Best-realised place in the set for "ruin reclaimed by
nature with industry bolted on," but undercut by a recurring artifact and by
foliage occlusion in the shots meant to prove distant silhouette.

`10-stronghold-gate-day` is the strongest single frame in the whole set: a
mossy, ivy-grown gatehouse with castellated towers, a red-lit doorway, and a
plank bridge over wetland reeds — reads convincingly as an ancient ruin
being crossed. `10-stronghold-courtyard-day` sells faction identity well:
two large red Team Tether banners, a soldier NPC in grey/black uniform, an
anvil, rolled mats, and stacked crates together — the one frame that most
reads as "industry bolted onto a ruin." `11-castle-landmark-hall-100m/200m
/400m` confirm the Hall now has a real, legible silhouette (castellated
towers, a taller central spire) that holds up to at least 200m, where
foliage doesn't block it.

**Defects**

- `10-stronghold-approach-day`, `11-castle-landmark-hall-100m-day`, and
  `11-castle-landmark-hall-200m-day` all share a flat, hard-edged band of
  dark grey haze sitting directly behind/above the Hall at a fixed height on
  the horizon. It has crisp rectangular edges rather than soft volumetric
  falloff, doesn't visibly originate from any chimney/stack on the
  building, and doesn't thin with distance the way real fog would — reads
  as a stuck skybox/fog-plane artifact, and it sits exactly where the eye
  should land first on the landmark.
- `11-castle-landmark-hall-100m-day` and `200m-day`: foreground/mid-ground
  trees are enormous pale mint/white faceted canopy blobs occupying
  40–60% of the frame, partially occluding the Hall itself. For a shot
  whose entire purpose is proving the landmark reads at distance, having
  the landmark's lower half hidden behind broken-looking foliage defeats
  the test — the worst instance of the mint-canopy problem in the set.
- `10-stronghold-approach-day` / `-night`: a glowing teal cable/beam crosses
  the sky at a perfectly straight diagonal with no visible anchor or
  source at either end — same ungrounded "line renderer" look as the relay
  cables.
- `10-stronghold-courtyard-day` / `-night`: a bright cyan glowing
  plank/beam lies on the floor at a diagonal in the foreground, unconnected
  to any door, chest, or mechanism — reads as a stray debug/quest-marker
  mesh left visible in a location that should otherwise read as a lived-in
  occupied fort floor.
- `10-stronghold-courtyard-night` and `10-stronghold-gate-night`:
  near-total black crush. Courtyard-night in particular is almost entirely
  unreadable — only the two faction-symbol icons and a faint gate-arch
  silhouette survive. If night is meant to carry a different mood here, it
  currently just reads as underexposed/broken rather than moody.
- `10-stronghold-gate-day`: the garden urn/brazier post beside the bridge
  rail reads nearly as tall as the trainer — noticeably oversized for a
  set-dressing prop next to a 1.80 m ruler.

**vs round 1**: mixed, net better. The headline fix: round 1's
`11-castle-landmark-*` camera rig was pointed at the wrong subject entirely
— all three round-1 frames (`approach-day`, `banners-day`, `gate-day`) show
the trainer looking at a grassy boulder mound in an open field, not the Hall
at all, so round 1 could not judge the Hall's distant silhouette at all.
Round 2's `hall-100m/200m/400m` frames fix this and finally deliver on
"silhouette separates from the ground at distance," at least at 100–200m.
`10-stronghold-gate-day`, `courtyard-day`, and `approach-day` are otherwise
pixel-for-pixel unchanged from round 1 — same floating cable/beam
artifacts, same smoke-band behind the Hall, same crates/banners/soldier.
Round 1 had no night stronghold frames to compare against; the new night
set is new, but arrives too dark to be a usable addition as delivered.

---

## Ranked: the three things that most separate these frames from the references

1. **Foliage at mid-to-far distance renders as pale, faceted, semi-transparent
   cauliflower geometry, and it is worst exactly where it matters most.**
   `palworld-04-plateau-landmark.jpg` and the keyart's STARTING SETTLEMENT
   oak grove both show dense, saturated, readable canopy silhouettes at
   distance; these frames show the opposite. It is a background annoyance in
   `01-village-approach-day` and `04-warrens-approach-day`, but it becomes a
   functional failure in `11-castle-landmark-hall-100m-day` and `-200m-day`,
   where it occludes the lower half of the one landmark this survey exists
   to prove reads at distance.
2. **The Team Tether Relay does not read as an active, staffed operation.**
   The brief and the keyart's stronghold panel both call for personnel,
   clutter, cables, barriers. What's on screen in `06-relay-approach-day`
   and `06-relay-standing-day` is a striking but empty alien gate with three
   indistinct background figures and smooth debug-line cables — nothing
   communicates "workforce" or "recently occupied" the way
   `palworld-05-base-building.jpg` reads as inhabited instantly through a
   workbench, crates, and a posted task list.
3. **Ungrounded glowing cyan line/beam props recur across three different
   locations** — the relay cable-arcs (`06-relay-standing-day`), the
   stronghold's sky-crossing cable (`10-stronghold-approach-day/night`),
   and the courtyard floor beam (`10-stronghold-courtyard-day/night`). All
   three share no anchor points, no sag, uniform width, and screen-space
   brightness — this is one recurring defect, not three isolated ones, and
   it's one of the first things the eye catches in the courtyard because of
   how sharply it contrasts with the textured stonework around it.

## The two bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?**

**No**, as a set — though closer than a flat "no" suggests. The village's
cottage language and the stronghold's ivy-grown stone, banners, and warm
roofing genuinely match the keyart's palette and landmark language. But the
pale-crystalline foliage and the flat debug-line cables appear across
enough locations (village, warrens approach, relay, stronghold, landmark)
that they read as a systemic look rather than an isolated miss, and they
are visually the loudest thing in several frames — including the two frames
whose whole job is proving the Hall's silhouette reads.

**B. Shown beside the Palworld screenshots, would someone say these are
trying to be the same kind of game?**

**Yes for the village and the stronghold courtyard, no for the relay.**
The village's building density, prop scatter, and NPC placement land in the
same register as Palworld's settlements. The stronghold courtyard's
banners + soldier + crates is the right idea for a faction base. The relay,
judged only on the three frames given this round, reads as an atmospheric
ruin with a strange machine rather than a staffed installation — closer to
an environmental set-piece than to the base-building screenshot
(`palworld-05-base-building.jpg`) it should be answering.

## Fixable by changing the scene vs needs new art

**Fixable by scene (density/palette/lighting/composition/scatter):**

- Relay personnel readability: bring existing NPCs closer to camera, add
  more of them, give at least one a visible task/pose in the approach shot.
- `06-relay-apparatus-day` composition: reframe off the rooftop and off the
  sun; a lower, more level camera would show the machinery instead of sky.
- `01-village-route-out-day` composition: reframe so a road/fence/gate is
  actually visible and centred — the brief wants a gate on every road out.
- The dark smoke-band behind the Hall: a fog/sky-effect height, softness,
  and opacity-falloff retune, not a new asset.
- Night exposure on `10-stronghold-courtyard-night`, `10-stronghold-gate
  -night`, `01-village-twins-night`, `01-village-route-out-night`: raise the
  ambient/fill floor so buildings read as volumes rather than black cutouts.
- The moon: a soft radial falloff and slight rim light would stop the
  "pasted sticker" read without new geometry.
- The flat grey slab in `04-warrens-standing-day` and the debug-line cyan
  cables/beam in three locations: most likely a stray/placeholder mesh or
  material to hide or restyle, a visibility/material fix rather than new art
  — unless the cable is meant to be a real tether-cable VFX, in which case
  it tips into the next list.

**Needs new art (a scene pass cannot reach these):**

- The pale, faceted, translucent tree-canopy LOD/impostor look. This is the
  asset or its distance LOD, not a lighting problem — no relighting or
  repositioning turns hard alpha-cut white facets into the dense, saturated
  canopy the keyart shows.
- The relay's missing "clutter" — tents, bulk-stacked barrels/crates,
  warning signage, worked-material piles. If these props don't exist in the
  library, no amount of scene dressing manufactures them.
- A proper cable/tether VFX with sag, anchor points, and a real glow
  shader, if the cyan lines are meant to be an authored effect rather than
  leftover debug geometry.

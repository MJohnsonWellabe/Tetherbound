# Blind visual-judge pass — village, Warrens interior, three camps, the Relay

**Judged by:** an independent sub-agent spawned by AUDIT-E, given 19 of the 33
frames in this directory (a representative approach/standing/detail and
day/night spread across all six locations) plus
`docs/reference/tetherbound-meadows-keyart.png` and
`docs/reference/palworld-0*.jpg`. No handover, prior judge report, design
document, or knowledge of what changed was provided.

**Frames judged:** village (`01-village-standing-day/night`,
`01-village-twins-day`, `01-village-grandpa-yard-day`,
`01-village-tournament-day`); Warrens interior (`04-warrens-approach/standing/
den-day`); relay-camp (`05-relay-camp-standing/fire-day`); ridge-camp
(`08-ridge-camp-standing/fire-day`); waystop (`09-waystop-standing/bench-day`);
the Relay (`06-relay-approach/standing/apparatus-day`) — captured 2026-08-31
against `main` @ `453107fb` with `tools/_capture_locations.gd`.

See `../E-2026-08-31.md` §§E1/E3/E4/E5 for this lane's own reconciliation of
this verdict, including one correction (the "no fire" reads at two camps) this
lane traced against the capture tool's own source comments and a direct
pixel-level look at the frames.

---

## Capture validity

All 19 frames loaded and inspected (5 village, 3 Warrens, 2+2+2 camps, 3
Relay), plus the key-art board and five Palworld references. All captures are
valid — no buried camera, no blank/black frames.

One defect is present in **every single outdoor frame without exception**, so
it is flagged once here rather than repeated nineteen times: the clouds in
every sky (all village, Warrens exterior, all three camps, all Relay frames)
render as smeared, out-of-focus airbrush blotches with soft muddy edges —
compare any of them to the crisp, separated, puffy clouds in the key art or
any Palworld shot. It reads less like a stylistic choice and more like a
broken cloud texture or an incorrectly-blurred sky dome. It costs every
location some polish, so it is factored into each verdict below but not
re-listed as location-specific.

---

## 1. The Village

**01-village-standing-day, 01-village-standing-night, 01-village-twins-day,
01-village-grandpa-yard-day, 01-village-tournament-day**

- `01-village-standing-day`: the climbing vine on the right house's wall
  (~x870-905, y505-650) is a flat, rigid, perfectly vertical cutout — reads as
  a 2D card slapped on the wall rather than an organic climbing plant. Only
  two full buildings plus one small roofed well-structure are visible in
  frame; there is one paved path (to the well) and otherwise houses sit
  directly in unmown grass with no connecting paths, no gardens, no carts, no
  barrels, no washing lines — nothing that signals daily occupancy beyond the
  three characters present.
- `01-village-twins-day`: the emptiest frame in the whole set. Two buildings,
  disconnected from each other, sitting in an open field with no fencing, no
  yard treatment, tiny indistinct NPC figures in the far background. This is
  "two houses dropped in a meadow," not a village street.
- `01-village-grandpa-yard-day`: the best-composed day frame — a real
  character beat (two NPCs interacting), varied purple flower clump, a tree, a
  stone path. But the cluster of dark shapes in the far background right
  (~x850-950, y280-330) reads as an indistinct grey blob — can't tell if it's
  rocks, crates, or rubbish, which undercuts rather than adds to the
  "lived-in" read.
- `01-village-tournament-day`: labelled "tournament" but shows an open grass
  field with two NPCs standing around — no arena, ring, fencing, banners, or
  crowd of any kind, so nothing in the frame itself signals "tournament."
  There is also an unexplained orange flare/spark sprite floating in the
  grass at bottom-left (~x520-560, y600-650) with no visible source object —
  reads as an orphaned particle effect, i.e. a bug.
- `01-village-standing-night`: clearly the strongest frame of the set. Warm
  lit windows against a dark blue sky, a plausible moon, figures grounded by
  real shadow — this is the one frame that reads as "a place people live in"
  without qualification.

**Verdict: No**, on balance. The night frame alone would pass; the daytime
frames read as two-to-three isolated buildings in a field, not the clustered,
path-connected settlement shown in the key art's "Starting Settlement" panel
(which has a well, fence line, multiple cottages, and a banner all reading as
one composed space).
**Biggest issue:** daytime emptiness / lack of village density — **fixable by
tuning** (more buildings or backdrop buildings, connecting paths, yard
clutter, more idle NPCs) rather than needing new art, since the individual
building and character assets are already good.

---

## 2. The Warrens (cave interior)

**04-warrens-approach-day, 04-warrens-standing-day, 04-warrens-den-day**

- `04-warrens-approach-day`: the boulder-pile exterior reads as a clear,
  distinct silhouette against grass and sky — good landmark language. The
  granite speckle texture is applied uniformly at a scale that makes each
  boulder look like an oversized painted egg rather than fractured rock — no
  large-scale cracking, moss, or weathering breaks up the surface.
- `04-warrens-standing-day`: good use of cast shadow across the entry path
  for depth. The bush at bottom-right (~x760-1150, y560-750) is a flat,
  saturated, cartoon-lime sphere that clashes hard against the desaturated
  grey stone — it's a different asset language grafted into a stone
  environment.
- `04-warrens-den-day`: this is the frame that matters for the "place, not
  corridor" test, and it partially passes — it is a genuine defined room
  (angled beam ceiling, four visible walls, a doorway to the left), not a
  tunnel. But it's under-dressed for a creature's den: dirt floor with a
  couple of moss specks, one loose rock, one orange sack in the far corner,
  and nothing else — no bedding, no bones, no nest material, no water. The
  lighting is a flat, even wash with no directional shaft or gloom, so it
  doesn't deliver the "hints of mystery" the project states as a target.
- Scale concern: the badger creature's body drapes directly across the
  character's shoulders/back with its legs and feet hidden behind the player
  silhouette — cannot confirm it is standing on the floor independently
  rather than appearing to ride the character like a hood. This is a
  staging/readability problem worth checking in motion.

**Verdict: No**, but closer than the village. The room composition itself
works; the dressing and lighting don't yet deliver "a place."
**Biggest issue:** empty/underdressed den interior — **fixable by tuning**
(add nest/bone/water props, a directional light shaft or torch, reduce the
flat top-wash). The badger staging concern needs verification in-engine, not
a screenshot judgment.

---

## 3. Relay-camp (checkpoint camp)

**05-relay-camp-standing-day, 05-relay-camp-fire-day**

- Neither frame — including the one explicitly named "fire" — contains a
  visible campfire, firepit, flame, or smoke, as read from these crops.
  **AUDIT-E note: this lane's own follow-up found a small, off-centre ember
  in `05-relay-camp-fire-day` and traced the capture tool's own source
  comments, which document that this specific stand's aim point is 6.7 m off
  the real fire — see the main report §E4 for the reconciliation.** What's
  present in frame is a red flag on a pole, two crates, a barrel, a loose
  plank, and a sack, scattered across open grass.
- Without a *legible* fire or seating, this reads as a supply cache /
  objective waypoint (the flag reinforces that reading — flags mark
  objectives, not rest stops), not a place a traveller stopped to rest.

**Verdict: No** on legibility grounds — whether or not a real fire exists at
the correct coordinates, it does not read as a rest camp in the frame as
captured.
**Biggest issue:** the capture stand's own aim is documented wrong (see
above) — re-shooting this stand correctly is a prerequisite to judging this
camp fairly at all.

---

## 4. Ridge-camp

**08-ridge-camp-standing-day, 08-ridge-camp-fire-day**

- Same initial read as relay-camp: the frame named "fire" did not show an
  unambiguous flame from this critic's crop. **AUDIT-E note: this lane's own
  follow-up found a small flame directly behind the player character's head
  in this frame, and confirmed via the tool's own source comments that this
  stand's aim point IS the fire's correct, authored position — so unlike
  relay-camp, this is real evidence of a genuine defect: the fire exists and
  is correctly targeted, but is not legible at normal viewing size. See the
  main report §E4.**
- What's otherwise visible: a bench with a seated NPC, a lattice-sided crate
  that reads more like an animal cage/trap than camp gear, a triangular brown
  canvas sheet propped up with no visible support poles (unclear if it's a
  half-pitched tent or a floating tarp), a sack, a barrel.
- The props (barrel, crate, crate, bench) sit in a straight line rather than
  an authored cluster around a shared focal point — this reads closer to
  "inventory items placed along a shelf" than to a camper's arrangement.
- Positive: the surrounding tree stand behind the camp has good variety in
  trunk lean and canopy shape, and a distant NPC silhouette in the treeline
  adds some life.

**Verdict: No**, primarily on prop-layout and fire-legibility grounds (not
fire absence, per the correction above).
**Biggest issue:** fire legibility (too small/occluded to read) + linear
(procedural-looking) prop layout — **fixable by tuning** (cluster the props
around the firepit, angle them, brighten/enlarge the fire's visual
footprint).

---

## 5. Waystop

**09-waystop-standing-day, 09-waystop-bench-day**

- `09-waystop-standing-day`: this frame does show a genuine lit firepit glow
  (~x430, y455-480) plus a bench silhouette nearby — better than either camp
  above. However, the background contains a Team Tether pylon and a large
  castle/fortress structure that belong visually to the hostile-faction
  location, and a thin teal cable runs diagonally through the tree canopy
  toward camera (~x0-520, y280-330) with no visible support along its span —
  it reads as a stray line clipping through the trees rather than a
  deliberately staged detail. If the waystop is meant to sit within sight of
  Team Tether territory that's a valid story beat, but as staged here it
  reads ambiguous-to-buggy rather than intentional.
- `09-waystop-bench-day`: has a clear lit fire (bottom-left, ~x150-220,
  y430-480), a small anvil prop (~x385-400, y355-375), a purple flower
  cluster, and a bare dead tree at top-right that's a genuinely nice
  mood/mystery touch. This is the best-dressed rest-stop of the three camps.
  Oddly, despite the filename, no bench is clearly identifiable in this
  particular frame — it may be hidden in the tall grass.

**Verdict: Borderline yes** for `09-waystop-bench-day` alone — fire, anvil,
flora variety, and a mood prop (dead tree) combine to read as an authored
stop. The "standing" frame drags the location down with the stray cable
artifact and location-bleed background.
**Biggest issue:** the floating cable through the canopy in the standing shot
— likely **fixable by tuning** (anchor/hide it, or reframe the shot) but
worth confirming it isn't a real physics/attachment bug.

---

## 6. The Relay (Team Tether infrastructure)

**06-relay-approach-day, 06-relay-standing-day, 06-relay-apparatus-day**

- The pylon/apparatus design itself is the strongest asset-level work in the
  whole survey: black wrought metal, gold trim, glowing teal crystal heads,
  taut cable strung between posts (clearest in `06-relay-apparatus-day`) —
  distinct silhouette, reads immediately as "not-natural, hostile tech," and
  doesn't share a design language with anything else in the Meadows. Good
  landmark language.
- But the structure housing it is a flat grey stone gate/carport — four
  pillars and a slab roof — which is a much weaker read for "infrastructure
  site" than the pylons themselves. In `06-relay-standing-day` the black
  mechanical apparatus sits on top of the roof slab with no visible mounting
  or support connecting it to the stone — it appears to float above the roof
  rather than being bolted to it (~x600-780, y400-480).
- Zero NPCs (no Team Tether grunts) appear across all three frames — the site
  reads as abandoned architecture rather than an occupied enemy operation.
  There is no worker presence, fencing, scorching, smoke, or any sign of
  active use.
- Colour: notably, no red/oxblood appears anywhere on the Relay's gear —
  everything is teal-and-black. The key art's own Team Tether panel
  (stronghold ruins with red banners) establishes red as the faction's colour
  language, so the Relay's teal palette doesn't visually connect to that
  established identity. This isn't a "leaked danger-red onto friendly things"
  problem (there's no red at all to leak), but it does mean the two things
  sharing the "Team Tether" name — the stronghold in the key art and this
  Relay site — don't currently look like the same faction's work.
- `06-relay-standing-day`: the sun renders as a hard-edged blown-out white
  disc (~x830-1040, y0-220) with no soft bloom falloff — reads as a
  placeholder billboard sun rather than atmospheric lighting.

**Verdict: No**, primarily because of population, not asset quality. The
individual pylon/apparatus props are good and distinct; the site around them
(empty architecture, no personnel, no operational mess) doesn't read as a
hostile faction's active infrastructure.
**Biggest issue:** zero NPC presence / no sign of activity — **fixable by
tuning** (place grunt NPCs, patrol routes, crates/tools, damage/scorch
decals) since the hero props themselves are already strong. The teal-vs-red
palette mismatch with the key art's Team Tether identity is a design-language
question, not a scene-tuning one — flag it rather than assume it's wrong,
since it may be a deliberate "different sub-faction/tech vs. banners"
distinction the game intends.

---

## Across all six locations

**Cohesive, or different projects?** Mostly cohesive. Every location shares
the same character models, the same grass/flora shader, the same (smeared)
sky, and a consistent warm/natural palette in the non-Team-Tether locations —
nobody would say the village and the Warrens came from different games. The
Relay's teal-tech pylons are the one deliberate departure, and that departure
is doing its job (it reads as "other," which is presumably the point) rather
than reading as inconsistency. The bigger cohesion problem isn't palette, it's
*density* — the village, both camps, and the Relay all suffer from the same
symptom of sparse, thinly-scattered content in wide-open grass, which makes
the whole survey feel like one consistent production stage (early
scene-dressing pass) rather than six inconsistent ones.

**Beside the Palworld references, is this trying to be the same kind of
game?** Partially yes, on intent; not yet, on execution. The palette family,
the rolling-hills-and-oak-groves silhouette language, and the cel-shaded
human character in a semi-painterly natural world genuinely rhyme with
Palworld's look — someone would recognize the genre and mood target
immediately. What's missing next to the Palworld shots specifically:
1. **Density of life and event.** Every Palworld reference has multiple
   creatures, combat particles, UI feedback, and a sense of something
   happening; every Tetherbound frame here is a static establishing shot with
   at most two idle NPCs and zero creatures in most frames (only the Warrens
   den has one).
2. **Ground clutter and grass variation.** Palworld's grass is shorter,
   patchier, and worn into paths by traffic; Tetherbound's grass is a
   uniform, unbroken carpet of same-height blades right up to every doorway
   and prop, which reads as "un-walked-on."
3. **Sky/atmosphere polish.** Palworld's clouds and lighting are crisp and
   layered; the smeared cloud artifact present in every Tetherbound frame is
   the single most visible gap next to these references, because it's the
   top third of every image.

**Ranked, the three things most separating these frames from the
references:**
1. The smeared/blurred cloud rendering, present in literally every frame — a
   Palworld or key-art sky is crisp; this sky reads broken. (Every frame;
   most visible in `06-relay-standing-day` where it fills half the image.)
2. Emptiness/low density — no crowds, no creatures in most frames, thin
   scatter of props in the camps and Relay, two buildings standing alone in a
   field for the village. (`01-village-twins-day`,
   `05-relay-camp-standing-day`, `06-relay-standing-day`.)
3. Missing/illegible "traveller stopped here" signals at two of the three
   camps. (`05-relay-camp-fire-day`, `08-ridge-camp-fire-day` — see the
   AUDIT-E correction above on what this specifically means at each site.)

These are all fixable by scene tuning (density, prop placement, fire
placement/scale, cloud shader/texture) rather than requiring new hero assets —
the pylon/apparatus design and the night village lighting show the underlying
asset and lighting quality is already there when it's given enough to work
with.

# Visual judge — Village + Mill Pond (VP0-baseline, locations-1080p)

Frames judged: `01-village-approach-day.png`, `01-village-standing-day.png`,
`01-village-twins-day.png`, `01-village-grandpa-yard-day.png`,
`01-village-tournament-day.png`, `01-village-route-out-day.png`,
`02-mill-pond-approach-day.png`, `02-mill-pond-standing-day.png`,
`02-mill-pond-wheel-day.png`.

References: `tetherbound-meadows-keyart.png` (primary), `palworld-01..05` (the
real-time bar), `site/img/page-board.jpg` (approved concept target).

No score. Defects below, each naming the frame it appears in.

## 1. Silhouette and readability

- Buildings read cleanly at a glance: pitched roof + timber frame + stone
  base is legible in every village frame (01-standing, 01-twins, 01-route-out).
  This is the strongest thing in the set.
- Trees are a single "broccoli clump" silhouette repeated at near-identical
  scale everywhere they appear (01-approach, 01-grandpa-yard,
  02-mill-pond-standing). Nothing distinguishes an oak from a generic tree —
  the keyart's oak-grove panel shows individually shaped canopies with
  visible branch structure breaking the outline; these are uniform balls.
- The two leafless "dead trees" (01-approach far left, 01-grandpa-yard far
  left) are the exact same asset at the exact same scale and pose. Good as a
  silhouette break from the green trees, bad as a repeat — two identical dead
  trees in two different frames reads as one prop copy-pasted, not a
  hand-placed landmark.
- Background NPCs (01-approach, 01-tournament, 02-mill-pond-standing) are
  small enough, and stiff-postured enough, that they read as generic humanoid
  blobs rather than named villagers — fine at a glance, but they don't add
  any silhouette variety to the population the way the keyart's varied prop
  scale does.
- The mill/tower building (02-mill-pond-standing, 02-mill-pond-wheel) has an
  odd silhouette: three-plus storeys on a very narrow footprint, no wheel, no
  chute, no water-adjacent machinery visible. At a glance it reads as "tall
  house," not "mill." Nothing in its silhouette identifies its function.

## 2. Colour and value structure

- Grass, hills, and tree canopy all sit in a narrow mid-green value band
  across every frame — there's very little dark-shadow or bright-highlight
  variation in the terrain itself. The buildings carry almost all of the
  frame's value contrast (white plaster, dark timber, red-orange tile), and
  without them (02-mill-pond-approach) the frame goes visually flat.
- The reserved oxblood is not leaking onto friendly elements — roofs read as
  warm terracotta orange/red, not the Team Tether danger red. That's correct
  and worth confirming explicitly.
- The sky is the biggest colour problem in the set. In nearly every frame
  (01-approach, 01-standing, 01-twins, 01-tournament, 01-route-out,
  02-mill-pond-standing, 02-mill-pond-wheel) the clouds carry a muddy
  tan/brown streaking mixed into what should be a clean white/blue sky. These
  are midday "day" captures, not sunset, so there is no lighting reason for
  brown in the clouds — it reads as a broken cloud shader or texture-blend
  artifact, not a stylistic choice, and it sits directly over roughly a third
  of every wide frame.
- The clouds are also uniformly heavily blurred/streaked, almost as if under
  motion blur or an excessive DoF pass, giving them a smeared "cotton candy"
  look rather than the crisp, individually-shaped cumulus in the keyart's sky
  and in every Palworld reference.

## 3. Intentionality

- Village layout (01-standing's signpost cluster: Grandpa's House, The Inn,
  Practice Meadow, The Pond) is clearly authored — named destinations, paths
  connecting them, buildings angled toward the paths. This is a genuine hit
  against the keyart's "named framings" idea.
- Vegetation reads as scattered rather than composed. The purple flower
  clumps (01-grandpa-yard, 01-route-out background) are the same clump shape
  repeated at the same scale with no clearings or drifts of varying density.
  Foreground grass is a uniform "shag carpet" — same height, same clump
  pattern, in every frame it appears, with no trampled/worn variation except
  the literal dirt path.
- The grey boulders (01-approach right foreground, 01-route-out background)
  are the same rock asset reused with a very recognizable silhouette — two
  placements close enough together in the survey that the repeat is obvious.
- Fenced paddocks appear in 01-grandpa-yard and 01-tournament with nothing in
  them — no livestock, no crops, no worked ground. An enclosure that encloses
  nothing reads as a placed prop, not a lived farmstead.

## 4. Lighting

- The sun disc in 02-mill-pond-standing is a hard-edged, perfectly circular
  white shape with no bloom falloff or glow gradient — it reads as a flat
  decal pasted into the sky rather than a light source, and it sits close
  behind the character without producing any matching rim light or lens
  flare on him.
- Shadows are weak-to-absent through the whole set. In 01-route-out the
  trainer stands directly beside a stone well under a clear sky and casts
  no visible shadow on the ground; the well itself casts none either. In
  01-approach the houses don't shadow the grass in front of them. Buildings
  show almost no self-shadowing between sunlit and shaded wall faces
  (01-twins, 01-route-out) despite having enough geometric relief (eaves,
  recessed windows, timber framing) to hold real shadow.
- Net effect: the sky says "clear midday sun," but the ground and props say
  "overcast" — the two don't agree, and time of day doesn't actually read
  from the lighting, only from the sky colour.

## 5. Horizon and depth

- The mountain in 01-approach and the one in 01-tournament sit at a flat,
  saturated olive/grey value with no atmospheric desaturation or blue-shift.
  Compare the keyart's mountain panels, where distant peaks go pale
  blue-lavender specifically to sell distance — here the far mountain reads
  almost the same value as the midground grass, so it looks pasted onto the
  horizon rather than sitting kilometres back.
- No haze gradient is visible between near trees and the rolling hills behind
  them in any frame — depth is being carried entirely by object scale and
  overlap, not by any atmospheric cue, so the world reads shallower than the
  geometry actually is.
- 02-mill-pond-approach is essentially unreadable as a location: it's wall of
  bush/tree canopy filling 80%+ of the frame, with the pond and a roof only
  visible as a sliver between branches. If this is meant to establish "you're
  approaching the pond," it fails — there's no depth or sightline to the
  water itself.

## 6. Interface

- No HUD in any of the nine frames — nothing to judge on hierarchy/legibility
  here. The in-world signpost text in 01-standing ("Grandpa's House", "The
  Inn", "Practice Meadow", "The Pond") is legible and a genuine piece of
  environmental wayfinding, though "Grandpa's House" is clipped to "andpa's
  House" by the left frame edge — worth a camera/placement nudge.

## 7. Artefacts

- The tan cloud streaking (see §2) is the clearest thing that reads as a bug
  rather than a choice, and it appears in seven of the nine frames.
- The sun disc in 02-mill-pond-standing (see §4) reads as a rendering
  artifact/placeholder, not an integrated light.
- Filename/content mismatches: `01-village-tournament-day.png` shows a plain
  open meadow with two background NPCs and a fence — no arena, ring, stands,
  or banner of any kind identifies this as a tournament space. Similarly
  `02-mill-pond-wheel-day.png` shows the mill/tower building with no
  waterwheel anywhere in frame. Either the capture camera missed the feature
  that gives each frame its name, or the feature isn't built yet — both are
  worth checking, since right now these two frames don't show what they
  claim to.
- Up close (02-mill-pond-approach), the foliage resolves into flat,
  hard-edged alpha-cutout leaf cards with a uniform plastic-looking green
  fill — fine at a distance, but this frame puts the camera close enough that
  the card geometry itself becomes the subject.

## 8. Scale agreement (trainer = 1.80 m)

- Doors and windows read plausibly against the trainer in 01-route-out and
  01-standing — the door frame is roughly 1.3× his height, consistent with a
  real cottage door.
- The well in 01-route-out reads at roughly hip/chest height on the trainer —
  correct for a well wall.
- Foreground grass reaches knee-to-thigh height on the trainer (01-approach,
  01-grandpa-yard, 01-tournament) — correct for tall meadow grass, and it
  matches the "wildflower meadow" description.
- The purple flower clump in 01-grandpa-yard sits at roughly knee height —
  plausible for a flowering shrub.
- The boulder in 01-approach (right foreground) reads at chest-to-head height
  next to the NPC beside it — a plausible boulder, not oversized or
  undersized.
- The one figure whose proportions don't sit right is the mill/tower building
  itself (02-mill-pond-standing, 02-mill-pond-wheel): height-to-trainer looks
  fine, but the footprint is far too narrow for that many storeys — it reads
  as a stretched asset rather than a building someone could put stairs and
  rooms inside.
- No creature appears in any of the nine frames, so the rubric's core scale
  check — "is the one you fight alongside bigger than the one you practise
  on" — cannot be run at all from this set. That absence is itself notable
  (see verdict).

## Is the village inhabited?

Partially. Population presence is real: most frames carry one to three
background NPCs (01-approach, 01-twins, 01-tournament, 01-route-out,
02-mill-pond-standing), and 01-standing pairs the trainer with a second named
character up close. But nothing in frame suggests daily life: every NPC
stands in a static idle pose, no chimney carries smoke, no yard has an
animal, no fenced paddock has anything in it, and there's no market stall,
laundry line, or worked garden plot anywhere in the set. The keyart's own
"STARTING SETTLEMENT" panel sells inhabitation with a well, a cart, and a
banner — those specific props exist here too (well and cart-wheel parts in
01-route-out) — but without any activity or animal life around them, the
village reads as populated rather than lived-in.

## Verdict

### Three biggest gaps, ranked

1. **The sky.** Tan/brown-streaked, heavily smeared clouds appear in seven of
   nine frames and cover roughly a third of every wide shot. The keyart and
   every Palworld reference show clean white cumulus against saturated blue;
   this sky looks like a broken shader, not a stylistic choice, and it's the
   first thing a viewer's eye lands on in nearly every frame (worst in
   01-approach, 01-standing, 02-mill-pond-standing).
2. **No creature anywhere in the set, on a creature-bonding game's own
   survey.** Every Palworld reference frame has a Pal in it — fighting,
   riding, or working. The keyart's own DAY/NIGHT panel and the approved
   website hero (`page-board.jpg`) both pair the trainer with a companion
   creature in the exact "walking toward the world" framing this survey uses
   for 01-approach and 01-route-out. Shown these nine frames cold, nothing
   signals this is the game it claims to be.
3. **Lighting doesn't agree with itself.** A clear midday sky produces no
   matching ground shadow anywhere in the set (01-route-out's well and
   trainer cast nothing; building walls barely darken face-to-face), and the
   one explicit sun (02-mill-pond-standing) is a hard flat disc with no
   bloom or rim light on the character standing in front of it. Distance also
   doesn't read: the mountains in 01-approach and 01-tournament sit at the
   same flat value as the midground grass instead of hazing toward blue.

### Bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?** **No.** The architectural language is a
genuine match — stone-and-timber cottages, orange tile roofs, a well, a
wildflower meadow, named destinations — and that shape-language hit should be
kept. But the keyart sells its world through atmosphere: hazed distant peaks,
warm directional light with real shadow, a lush and varied sky. None of that
survives here; the sky artifact and flat, shadowless lighting make these
frames read as a generic village asset kit under default engine lighting,
not the specific, atmospheric place the board depicts.

**B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be
the same kind of game?** **No.** Ground cover density is actually comparable
— the tall grass in 01-tournament and 01-approach isn't far off
`palworld-02-open-field-path.jpg`'s field — but that's the only category
where this set holds up. There is no HUD, no combat framing, and critically
no creature in any of the nine frames, against a reference set where every
single frame centers one. Without a Pal-equivalent in view, a viewer has no
reason to connect these shots to a creature-catching game at all.

### Fixable-by-scene-change vs needs-new-art

**Fixable by changing the scene (lighting, palette, scatter, composition —
no new art required):**
- The cloud/sky artifact (shader or skybox texture fix, or at minimum turn
  down whatever blur/streak pass is smearing tan into the clouds).
- Shadow/lighting mismatch — enable or strengthen contact shadows and
  directional shading so midday sun actually darkens shaded wall faces and
  puts a shadow under the trainer and props.
- Atmospheric haze/blue-shift on distant terrain (a fog/depth-fade pass would
  fix the flat, pasted-looking mountains in 01-approach and 01-tournament
  without touching any mesh).
2. The sun-disc artifact in 02-mill-pond-standing (bloom/glow parameters on
   whatever draws the sun).
3. Vegetation repetition (dead tree, boulder, purple-flower-clump reused at
   identical scale/pose) — a scatter-tool variance pass (rotation, scale
   jitter, a second flower colour) fixes this without new assets, since the
   keyart's own palette strip already includes yellow and white alongside
   purple.
4. Empty paddocks — dressing them with existing livestock/prop assets (if
   any exist) or removing the fence is a scene decision, not new art.
5. The tournament/wheel frame mismatches are a capture or scene-dressing
   problem — verify the camera is actually aimed at the tournament ground /
   mill wheel, or that those features exist in the build at all.

**Needs new art (not fixable by scene changes alone):**
1. No creature in the survey at all — if the intent was to show the village
   uninhabited by pals for some narrative reason, that's a framing choice
   and not a defect; but if this is meant to represent the game's normal
   state, closing this gap needs a companion creature placed in these shots,
   which is a content/scene decision but depends on creature assets already
   existing and being riggable into these scenes — flagging it here since it
   dominates bar question B.
2. Tree canopy variety — the single spherical "broccoli" tree silhouette
   repeated everywhere is a mesh/material limitation, not something a scatter
   tool alone fixes; distinguishing an oak grove from generic trees needs
   either a second tree silhouette or per-tree canopy variation baked into
   the asset.
3. The mill building's stretched, wheel-less proportions — giving it a
   silhouette that actually reads as "mill" (wheel, chute, water-adjacent
   massing) requires new geometry, not a lighting or scatter fix.

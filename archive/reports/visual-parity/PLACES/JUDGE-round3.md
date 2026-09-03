# Visual Judge — PLACES, Round 3

Blind pass. No code, config, diffs, or history read — frames only, plus the
named references. Frames judged: `places_r3/locations/04-*`, `10-*`, `11-*`,
`places_r3/ground/ground-00-village-*`, `places_r3/sheet.png`, and the
equivalent `places_r2/locations/` frames for comparison.

---

## 1. Burrow Warrens exterior/den

**04-warrens-approach-day.png** — This is a grey rock pile on lawn. It is
essentially the same frame as `places_r2/locations/04-warrens-approach-day.png`
pixel-for-pixel in composition: the same boulder cluster, same camera angle,
same flat mid-grey value across every rock. Specific defects:

- Every boulder is the same light grey value — no darker weathered stone, no
  moss, no lichen, no dirt-staining at the base where rock meets ground. The
  rubric asks for "boulders with value variation sunk into soil"; these
  boulders all read as one material and sit *on top of* the grass rather than
  being embedded in it — there is no visible soil skirt, no compressed/worn
  dirt where the rock meets the meadow.
- The entrance is a thin dark vertical sliver left-of-center, easy to miss at
  a glance. It does not read as a focal point the way a den mouth should — no
  framing rocks, no darkened approach, no widened worn path leading into it.
  The player's own path (visible foreground trail) walks *past* the
  formation rather than toward the opening.
- The "apron" in front of the entrance is identical wildflower meadow grass
  to every other frame in this survey (see `ground-01` through `ground-05`
  for direct comparison) — no scrub, no packed dirt, nothing that says
  "something lives here and has worn this ground down."
- No scale tell: the boulder pile is a single uniform hump with no larger
  anchor stone or smaller scatter stones around it, so despite being large it
  reads as one blobby prop rather than an authored rock formation.

**04-warrens-standing-day.png / 04-warrens-den-day.png** (interior) — these
read fine as cave/den interior: reasonable value range between the lit
foreground and the dark side-passage, a carved pale stone slab with visible
tool-shadow, plant clumps for color accent. Not the frames the rubric's
"grey rock pile on lawn" language is aimed at — the exterior shot is.

**Verdict: WORSE THAN NO CHANGE — this location was not touched.** Comparing
`places_r2/locations/04-warrens-approach-day.png` to the round 3 version
side by side, the two are indistinguishable: same rock silhouette, same
uniform grey, same thin entrance slit, same clean-lawn apron. Round 2's
"grey rock pile on lawn" verdict still applies verbatim to round 3. This is
the single biggest miss of this round relative to what the brief asked for.

---

## 2. Meadows Hall / Team Tether stronghold

### Gate (10-stronghold-gate-day / -night)

Dark, weathered stone towers with visible moss patches on the upper
crenellations, ivy trailing down the left tower, red Team Tether banners
either side of the arch, a small corner turret with a conical roof visible
behind. This is a real castle silhouette, not a cream box, and separates
cleanly from the blue sky. Night version keeps a legible black silhouette
against a lit night sky with one lantern glow at the gate mouth.

Compared to `places_r2/locations/10-stronghold-gate-day.png`: **essentially
unchanged, and that's fine** — round 2's gate was already close to this bar
(same dark stone, same moss, same banners). No regression, no meaningful
gain either; this frame was already carrying its weight.

Defect that persists in both rounds: no visible collapse or breakage in the
silhouette — no missing merlon, no crumbled corner, no exposed rubble. It
reads as a well-maintained fortress gate, not a ruin that nature reclaimed
and Team Tether occupied afterward. The ivy is the only "nature reclaiming"
cue; there's no equivalent industrial cue at the gate itself (the
pylons/relay gear are elsewhere in the field, not bolted onto the gate
structure the way the key art's stronghold panel does it).

### Courtyard (10-stronghold-courtyard-day / -night)

Day frame: good density of "industry bolted on" detail — anvil, crate
stack, a wooden scaffold/ladder frame on the left, coiled rope/sacks on the
right, mossy stone walls, ivy hanging from the left corner, two big red
Team Tether banners flanking a dark inner doorway. This is the strongest
single frame in the set for the "ruin reclaimed by nature with industry
bolted on" brief — it has both halves of the ask in one shot.

One fixed defect vs. round 2: `places_r2/locations/10-stronghold-courtyard-day.png`
had a glowing cyan diagonal beam/wire floating across the yard at chest
height with no visible source or anchor — a clear rendering artifact. It is
gone in round 3. **Genuine improvement.**

Night frame (`10-stronghold-courtyard-night.png`): this is a regression in
usefulness, if not necessarily a new defect — the frame is almost entirely
black. The sky strip at the top is legible, the two banner icons are barely
visible as pale discs, and the player/NPC are near-silhouettes, but the
courtyard floor, banners' red color, and every prop from the day shot are
gone into pure black. There's no rim light, no window glow from the
surrounding walls, no brazier/torch light one would expect from an occupied
stronghold at night. Compare to the gate-night frame in the same set, which
keeps a legible silhouette against sky — the courtyard has no sky to bounce
off of and nothing fills the gap.

### Approach + 100m/200m/400m landmark frames (10-stronghold-approach-day, 11-castle-landmark-hall-*)

Two consistent defects across all four day long-shots:

1. **A flat-edged dark grey band sits directly behind/above the Hall in
   every one of them** (approach-day, 100m, 200m, 400m) — a rectangular haze
   or rain-cell shape with a hard horizontal top edge, distinct from the
   cloud texture around it. It reads as a weather-effect quad clipped at a
   fixed height rather than atmospheric depth fog, because its edge doesn't
   soften or follow the cloud silhouette the way the rest of the sky does.
   This was already present in round 2 (`places_r2/locations/11-castle-landmark-hall-400m-day.png`
   shows the identical band) — **unchanged defect**, not new, but still
   unaddressed.
2. **At 400m the Hall does not separate from the ground.** It is a small
   pale-grey rectangle sitting on the horizon line, low value contrast
   against the hazy grey-green hills behind it, and easy to lose entirely at
   the "30% size" readability test the rubric asks for. The rubric's
   explicit requirement — "a silhouette that separates from the ground at
   400 m" — is not met here. This matches Palworld's own landmark reference
   (`docs/reference/palworld-04-plateau-landmark.jpg`), where the distant
   tower structure reads as a strong dark silhouette against a lighter sky
   even at a comparable or further apparent distance — the Hall in these
   frames is lower-contrast than its own target than the exact case the bar
   was set against.

What did genuinely improve at 100m/200m: in round 2
(`places_r2/locations/11-castle-landmark-hall-100m-day.png` and the 200m
equivalent) the foreground/midground tree canopies were rendering as a
broken white/mint texture — a clear visual bug that ate a third of each
frame. In round 3 those same trees render as normal green canopy. This is a
genuine, visible fix and it materially improves both the 100m and 200m
frames' readability — the Hall's dark towers now read clearly through gaps
in correctly-colored foliage instead of fighting a white texture-glitch
foreground. The 200m frame additionally now shows a row of glowing
blue-white Team Tether pylons/relay apparatus leading up to the Hall along
the path — a good "industry bolted on to a natural approach" beat that
wasn't legible in round 2's version of the same shot (obscured by the
white-foliage bug).

At 100m the Hall itself (towers, red door, corner turret) is clear and
reads as intended — dark stone, red accents, moss. This frame is close to
carrying the brief on its own if not for the flat storm-band sitting
directly behind it, which undercuts the "grows out of the terrain"
naturalism the rest of the frame earns.

**Verdict: partial, uneven improvement.** The Hall's close-range read (gate,
courtyard, 100m) is good and mostly unchanged from round 2 apart from one
fixed floating-wire artifact. The mid-distance frames (100m/200m) improved
meaningfully because a foliage rendering bug was fixed, incidentally
un-blocking the Hall silhouette. The far frame (400m) — the one the rubric
specifically calls out — did not improve and still fails the "separates
from the ground" bar, and the flat storm-band artifact behind the Hall is
unchanged across both rounds.

---

## 3. Village / ground context frames

Included for completeness since they're present in this set.
`ground-00-village-day.png` reads well — half-timbered and stone cottages
with warm terracotta roofs, a clear value range between lit walls and shadow
side, believable prop scatter (fence, crate, gate) at the player's scale.
`ground-00-village-night.png` keeps lit windows and a readable moonlit
silhouette against a dark-blue sky — this is the model the stronghold
courtyard-night frame should be following and currently isn't (the village
has practical light sources doing work at night; the courtyard has none).

---

## Three biggest gaps, ranked

1. **The Warrens exterior is unaddressed.** Round 3's
   `04-warrens-approach-day.png` is not distinguishably different from round
   2's — same uniform-grey boulder pile with no soil embedding, no worn
   apron, no focal dark entrance. Every other reference in this brief
   (Palworld's landmark rock work, the key art's mossy/weathered treatment
   applied to the Hall) shows what value variation and grounding looks like;
   none of that has reached this location yet.
2. **The Hall does not separate from the ground at 400m**, the exact
   distance the rubric names. It's a low-contrast pale shape against equally
   pale haze, and a flat-edged grey weather band sits behind it in every
   long-range frame in a way that reads as a clipped effect quad rather than
   real atmosphere — unchanged from round 2.
3. **Stronghold courtyard-night is close to unreadable** — no torch/brazier
   light, no window glow, almost the entire frame at or near black, in
   contrast to the village night frame in the same set which manages
   legibility at night with practical lighting.

## Bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?** — **Partial yes for the
Hall, no for the Warrens.** The Hall's gate and courtyard genuinely echo the
key art's "STARTING SETTLEMENT" / "TEAM TETHER STRONGHOLD" panels — mossy
dark stone, ivy, red banners, industrial clutter (anvil, crates, scaffold).
The Warrens has no equivalent authored treatment and reads as placeholder
terrain geometry, not art-directed to any reference in this set.

**B. Shown beside `docs/reference/palworld-0*.jpg`, would someone say these
are trying to be the same kind of game?** — **No, on landmark readability
specifically.** Palworld's plateau-landmark reference holds a strong,
high-contrast silhouette at distance; the Hall's 400m frame does not. The
close-range Hall frames (gate, courtyard, 100m) are closer to that bar than
the Warrens are, but the Warrens exterior alone would not pass this
comparison — it looks like an unfinished grey-box next to Palworld's rock
and ruin work.

## Fixable-by-scene vs. needs-new-art

**Fixable by scene** (no new meshes needed):
- Warrens exterior: material/vertex-color pass on the existing boulder
  meshes for value variation and moss/dirt staining; a dirt-patch decal or
  terrain paint for the entrance apron; darkening/widening the entrance
  opening or adding small foreground rocks to frame it; scattering 2-3
  smaller rock props around the base to break up the single-blob silhouette.
- Hall 400m/200m/100m storm band: whatever is producing the flat-topped
  grey band behind the Hall (fog volume, weather-cell placement, or a
  billboard) needs its placement/falloff adjusted so its edge softens like
  the rest of the sky instead of clipping hard.
- Hall 400m contrast: darkening the Hall's far-LOD material or adjusting
  fog/haze density specifically in that silhouette band would raise contrast
  against the pale horizon without new geometry.
- Courtyard-night: add practical light sources (brazier, torch, window glow
  from the surrounding walls) — a lighting/prop-placement fix, not new art.

**Needs new art / geometry:**
- A genuinely broken/ruined silhouette element on the Hall itself (missing
  merlon, collapsed section, exposed rubble) if the brief wants the gate to
  read as reclaimed ruin rather than maintained fortress — the current gate
  mesh reads intact.
- If the Warrens needs an authored "den" silhouette rather than a rock-pile
  primitive (distinct entrance archway, root/burrow detailing), that is new
  geometry, not a material pass.

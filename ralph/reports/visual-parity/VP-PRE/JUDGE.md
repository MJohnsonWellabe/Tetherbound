# Visual Judge — VP-PRE

Four in-game captures (Compatibility renderer, 1280x720): `01-spawn-outward.png`,
`02-valley-floor.png`, `03-rise-overlook.png`, `04-three-quarter.png`. No
creatures appear in any of the four frames — only the player character and,
in frame 01, two other human figures. That is an honest limit up front: the
rubric says creature and character art is the point, and creatures cannot be
judged from this set at all. What follows is limited to terrain, foliage,
lighting, composition, and the human figures actually on screen.

## Defects, by frame

**01-spawn-outward.png**
- The ground from about mid-frame down is not readable as grass. It has
  collapsed into a smeared yellow-green blur with no individual blades, no
  dirt/turf transition, no texture grain — it reads as an out-of-focus
  photograph of grass, not grass. At 30% size this entire lower half is a
  green smudge.
- A large, hard-edged, diagonal dark patch crosses the ground from lower-left
  to upper-right. No object in frame is positioned or shaped to cast a
  shadow like that — the boulder and both figures are the wrong shape and in
  the wrong place for it. This reads as a rendering bug (a stray shadow
  caster, a doubled shadow map, or clipped geometry) rather than a lighting
  choice.
- The boulder is a single flat dark-green-gray mass with almost no shading
  gradient across its faces and no contact shadow where it meets the grass —
  it looks pasted onto the terrain rather than resting on it.
- The figure in the extreme bottom-left corner (orange/tan sleeve, arm
  holding a dark object) is cropped by the frame edge in a way that reads as
  broken framing — it's unclear whether this is a third NPC standing
  unnaturally close to the camera or a UI/dialogue element bleeding into the
  world shot. Either way it is not legible as a person in the scene.
- The sky is a flat grayish blue with clouds that look gaussian-blurred —
  soft-edged streaks rather than clouds with any internal form. Compare to
  the crisp, articulated cumulus in the key art and in every Palworld
  reference.

**02-valley-floor.png**
- Trees are identical ball-on-a-stick shapes at regular intervals along the
  ridge — same canopy size, same trunk, same color, no scale or silhouette
  variety. This is the textbook "reads as procedural" case the rubric warns
  about: a designed grove clusters and leaves gaps; this one is a row.
- The boulder again sits with no contact shadow or grounding — same flat,
  faceted, undifferentiated dark mass as frame 01, just larger.
- The lower third of the frame is the same grass-to-blur problem as frame
  01: individual blades are legible for about two rows near the player, then
  the rest of the foreground dissolves into soft green mush.
- The player figure is correctly small against the boulder and trees (see
  Scale below), but is rendered at low enough resolution/detail that no
  clothing or silhouette detail reads even at full frame size — a flat
  dark-on-green blob with a backpack shape.
- Village rooftops in the background (red roofs) are the only warm-color
  accent in the whole set, and they are tiny and hazy — nothing else in any
  frame uses the warm/red/gold register the key art leans on constantly
  (dirt paths, windmill, sunset stone, wildflowers).

**03-rise-overlook.png**
- The horizon is a hard flat line where pale terrain meets pale sky, with
  no haze gradient, no color shift, no softening. Distant terrain is the
  same value and saturation as the terrain ten meters from the camera. For a
  vista shot meant to sell scale and distance, nothing in the frame tells
  you the village near the middle of the frame is far away except its small
  size — there is no atmospheric depth cue at all. It reads less like "rolling
  hills to the horizon" and more like a flat plane with a wall at the edge.
- The terrain itself, at this scale, is nearly featureless: a uniform pale
  yellow-green with faint mottled noise and no visible large-scale relief —
  no ridgelines, no valleys, no tree cover breaking up the mass, despite the
  key art's whole point being layered hills receding into blue-hazed
  mountains.
- Foreground rocks are the same flat-shaded, hard-edged, textureless mass
  as the boulders in frames 01–02 — an established, repeated look rather
  than a one-off.
- This is the widest, most "landmark" shot in the set and it is also the
  least composed: the village is small and off-center with nothing (a path,
  a light break, a framing tree) directing the eye to it. Compare to the key
  art's DAY/NIGHT overlook panel, which frames the valley and its stronghold
  as the clear subject.

**04-three-quarter.png**
- The mid-frame grass clump reads as a copy-pasted scatter blob: a dense,
  roughly circular cluster of identical small plants dropped in one spot
  with a hard density falloff at its edges, sitting in otherwise-empty
  grass. It looks like a scatter-tool preview, not a naturally thickened
  patch of undergrowth.
- Foreground (bottom third) has the same blur-to-mush problem as frames 01
  and 02, worse here because it is the largest fraction of any frame in the
  set — nearly 40% of the image is illegible green smear.
- The house is the best-composed element in the whole set — plausible
  scale, a visible door, window trim, a fence, a sign — but it sits behind
  the blurry grass and the scatter-blob, both of which compete for attention
  in the lower two-thirds instead of leading the eye toward it.
- Same smeared-cloud sky as every other frame.
- A dark rock shape is cropped at the bottom-left edge with no clear
  purpose — it isn't establishing foreground framing (too flat and dark to
  read as anything but a shadow) and just eats corner space.

## Cross-frame patterns

- **The blurred foreground ground is not a one-off.** It appears in three of
  four frames (01, 02, 04) and is the single biggest reason these do not
  read as a real place: grass is the material the camera is closest to in
  nearly every shot, and in every one of those shots it fails to resolve
  into anything with edges.
- **The sky is identical across all four frames** — same flat blue-gray,
  same smeared cloud streaks — which is consistent (frames "read as one
  place" per rubric item 2) but consistently wrong: it never varies with
  time of day or location the way the key art's DAY/NIGHT panel or its
  sunset-standing-stone panel do, and it never has the crisp puffy-cloud
  read of any reference image.
- **Value range is narrow everywhere.** Every frame sits between a
  desaturated blue-gray sky and a mid-tone yellow-green ground. There is no
  frame with a true dark (deep tree-canopy shadow, a shaded valley) or a
  true bright warm highlight (sunlit stone, a wildflower patch, a red roof
  in full light) doing real work. The one warm accent — the village
  rooftops in frame 02 — is small and hazy, not a compositional anchor.
- **Nothing in these four frames is grounded.** Every boulder and rock
  across 01/02/03 sits on the terrain without a contact shadow or any
  gradient suggesting weight — a defect the rubric calls out by name
  ("are shadows floating objects").

## Scale check (trainer = 1.80m)

Relative scale mostly holds up where it can be checked: the boulder in
frame 02 reads roughly 2.5–3x the player's height, which is plausible for a
large trail boulder; the trees read 4–5x player height, plausible for mature
oaks; the fence rail in frame 01 sits at roughly waist height on the player,
plausible for a field fence; the elder NPC in frame 01 is close to the
player's own height, as expected for two adult humans. No violation on the
order of the "creature smaller than a frog" failure this criterion exists to
catch. The one figure I could not confidently scale-check is the cropped
bottom-left figure in frame 01 — its proportions look off (a large hand
relative to visible torso) but the crop makes this unreliable rather than a
confirmed defect; flagged as a framing artifact above instead.

## Ranked: the three biggest gaps

1. **The ground does not resolve.** In three of four frames the grass
   dissolves into a soft, textureless blur the moment it's more than a few
   meters into midground. Palworld's field shots (`palworld-02`,
   `palworld-04`) hold crisp individual grass blades and a worn dirt path
   at the same kind of camera distance; the key art holds per-leaf and
   per-blade detail even further out. These frames hold neither — they lose
   the ground precisely where a real-time game or a painted board both
   choose to keep it legible.
2. **Nothing casts a believable shadow.** Every rock in the set floats on
   the grass with no contact shadow, and frame 01 has a large hard-edged
   shadow with no matching caster anywhere in view. Both Palworld and the
   key art use strong, direction-consistent shadows to place every object
   in the world and establish time of day; these frames do the opposite —
   objects look pasted on, and the one shadow present looks like a bug.
3. **The palette never leaves a narrow mid-tone band.** Sky, ground, rock,
   and the one visible village are all close to the same desaturated
   value range, with the smeared cloud texture repeated identically across
   every frame regardless of location. The key art's own art notes say
   "vibrant, readable colours on a natural palette" with day/night creating
   different moods; nothing here is vibrant and nothing distinguishes one
   frame's mood from another's.

## Bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?**
**No.** The key art's identity is warm, saturated, layered — golden light,
blue-hazed distant mountains, dirt paths that lead the eye, wildflowers and
red roofs as color accents, hills that recede in believable depth. These
four frames share none of that: flat gray-blue sky, a single mid-green
ground value, no atmospheric haze at any distance shown (frame 03 is the
test case and fails it outright), and a foreground that goes soft rather
than detailed. The house in frame 04 and the fence/village silhouettes in
frames 01–03 are the only elements that gesture at the key art's cozy
village language; everything else in the frame works against that mood.

**B. Beside the Palworld screenshots, would someone say these are trying to
be the same kind of game?**
**No.** Even holding UI and frame-rate out of the comparison as instructed,
the Palworld shots have grounded objects with real shadows, grass and dirt
that stay legible at every distance shown, a wider value range with genuine
highlights, and trees/rocks with individual character. None of that is
present here, and there are no creatures in this frame set to even begin
the comparison the rubric says matters most — a real gap in what this
capture set can show, not evidence either way about creature quality.

## Fixable by scene change vs. needs new art

**Fixable by scene/config change:**
- Foreground grass blur — almost certainly a depth-of-field or texture
  filtering/mip setting rather than a missing asset; the same grass tuft
  props are visible and sharp closer to camera in frame 04's midground, so
  the mesh/texture exists and resolves, it just isn't held onto at range.
- Missing contact shadows / floating boulders — shadow bias, AO, or ground
  darkening under static props is a lighting/material config fix, not new
  geometry.
- The unexplained hard-edged shadow in frame 01 — a bug to root-cause and
  fix (stray light, bad shadow caster, or a leftover debug decal), not an
  art gap.
- Flat horizon with no depth haze in frame 03 — fog/atmospheric-perspective
  tuning; the terrain and objects that would benefit from it already exist.
- Narrow value range / desaturated palette — grading, lighting color
  temperature, and time-of-day tuning; the palette.json target already
  exists per `docs/reference/README.md`, so this is a matter of applying it
  more assertively than these frames show.
- Regular-interval "lollipop" tree placement (frame 02) — scatter-tool
  jitter on scale, rotation, and clustering, using the trees already
  installed; no new tree mesh is required to fix the *pattern*.
- The scatter-blob grass clump in frame 04 — same fix, a placement/density
  falloff tuning problem rather than an asset problem.

**Likely needs new/upgraded art:**
- The smeared, blurred cloud sky repeats identically across all four frames
  regardless of location — if this is the actual sky texture/material
  rather than a DOF setting catching the skybox, it needs a sharper cloud
  texture or a proper volumetric/procedural sky, not just a config change.
- The boulders' flat, textureless, single-tone shading, consistent across
  three separate frames — if the rock material has no normal map or albedo
  variation applied, closing that gap is a texture/material asset task.
- The cropped figure in frame 01's bottom-left corner needs a framing fix
  at minimum; if it turns out to be a genuine third character rather than a
  UI artifact, its proportions should be re-examined directly rather than
  inferred from a bad crop.

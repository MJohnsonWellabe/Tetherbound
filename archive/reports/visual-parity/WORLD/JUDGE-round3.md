# World Visual Judge — Round 3

Blind pass over `world_r3/` (stands, locations, survey, ground) against
`docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`,
per `visual-judge` rubric. No code, config, diffs, or prior reports were read.

Note on inputs: the task description mentions a `bisect/` folder of "dawn
diagnostics." No such folder exists under `world_r3/` and no bisect-labelled
frame appears in `sheet_stands_bisect.png` — that sheet contains only the two
stands (`01-spawn-outward`, `03-rise-overlook`) across dawn/day/golden/night
plus `06-moon-stand-night`. Dawn is judged from those five frames only.

## Axis-by-axis (round 3 vs round 2)

**Sky / clouds — same.** The stylised swirl-brushstroke cloud pattern and
blue gradient sky are unchanged between rounds (`02-mill-pond-standing-day`
in both rounds is near-identical). Not re-litigated further here.

**Sun at day — same, and it's good.** When the sun sits high and off to the
side, it renders as a genuinely crisp round white disc with a soft, modest
halo (`locations/02-mill-pond-standing-day`). This matches the "crisp modest
disc" ask.

**Sun at golden — worse, and a real defect.** The moment the sun sits low and
is framed near-center, it stops being a disc at all: it becomes an oversized,
vertically-stretched, blown-out white/pale-blue oval with a soft edge that
eats a large fraction of the sky, in `stands/01-spawn-outward-golden`,
`stands/03-rise-overlook-golden`, and `survey/05-spawn-low-sun`. Two problems
compound: (1) scale — the halo bloom is roughly 15–20% of frame width, not
modest; (2) colour — it reads pale ice-white/blue rather than warm gold, so
"golden hour" doesn't look golden where the sun itself is in frame. Elsewhere
in the same lighting condition, where the sun is out of frame (e.g.
`ground/ground-05-band5-approach-golden`), the amber cast on the world itself
is genuinely warm and pleasant — the light colour is fine, only the visible
disc is broken. This is a location/angle-dependent bug, not a global
mis-tune, which should make it easier to isolate.

One reliability note in the same family: round 2's `survey/05-spawn-low-sun`
was a completely black frame (total render failure). Round 3 renders content
there — that crash/black-frame bug is fixed, even though the sun disc itself
is now a visible defect rather than an invisible one. Net progress, but not
yet a pass.

**Moon at night — mostly better, one broken outlier.** In the great majority
of night frames the moon is excellent: a clean, sharp-edged white disc with a
soft glow, sitting in a proper deep-blue night sky
(`locations/01-village-twins-night`, `ground/ground-04-band4-ironwood-night`,
`locations/01-village-standing-night`). This is on par with round 2's already
-good moon (`world_r2/locations/01-village-twins-night` is nearly identical)
and arguably a hair better for cloud texture around the disc. But
`stands/06-moon-stand-night` is a serious outlier: the entire frame, sky and
ground alike, is a flat, deep magenta/crimson wash with almost no value
separation — the moon disc is present as a paler pink circle but the whole
scene reads as "broken red filter," not night. This is the same failure mode
as the dawn defect below, and it appears in the same class of shot (a
high-sky, fog-plane-heavy overlook composition), which suggests one shared
bug rather than two.

**Dawn — split result, and the split matters.** `stands/01-spawn-outward-dawn`
reads correctly as dawn: cool lavender-grey sky, warm low-angle rim light
catching the fence and tree canopies, dark grounded foreground — this is a
legitimate dawn, not a red wash. But `stands/03-rise-overlook-dawn` is a
uniform, saturated brick-red tint laid over the entire frame — sky, distant
haze, and foreground rock all read the identical red, with no lighter sky
band, no gradient, no separation between ground and air. It does not read as
dawn; it reads as a stuck colour-grade layer. Given it shares its symptom and
its camera type (open-sky, fog-heavy overlook) with the moon-stand failure
above, both frames likely share a root cause tied to that specific
camera/fog combination rather than being two independent lighting bugs.

**Distance / haze at the overlook — mixed, one soft regression.** The
atmospheric gradient itself works: `stands/03-rise-overlook-day` shows a
believable haze falloff from clear near-ground detail to a pale, softened
horizon, and the village reads as a small, legible landmark cluster at
distance. Foreground rock and moss patches keep real micro-texture even
under the haze. Compared to round 2's `world_r2/survey/03-rise-overlook.png`,
though, the valley floor in round 3 shows noticeably fewer discrete tree
clumps scattered across the mid-distance — round 2's version had multiple
separate groves dotted across the whole basin; round 3's reads sparser
beyond the near foreground and the village. Haze quality: same. Vegetation
richness at range: worse.

**Ground close-ups — the strongest part of this round, clearly better.**
This is where the round earns its keep. Dirt paths consistently show real
tonal grain and scattered pebbles rather than a flat brown fill
(`ground/ground-01-band1-opening-day`, `ground/ground-02-band2-stone-root-day`,
`ground/ground-02-band2-stone-root-fog`, `ground/ground-05-band5-approach-day`).
Path edges are not hard-cut — grass tufts of varying height genuinely
encroach onto the dirt rather than butting against a clean texture seam.
Water banks show a distinct darker, damp band of ground before the water
line, populated with reed clusters, at both the pond
(`ground/water-01-pond-eye`) and the stream (`ground/water-03-stream-grazing`).
No fluorescent-lime ground or foliage was found anywhere in this set; the
brightest green ground-level asset (a broad blade in
`water-03-stream-grazing`, bottom right) has warm orange tip shading that
keeps it from reading as neon. No exposed flat/uniform terrain turned up —
every ground shot, including the stark Team Tether approach band
(`ground-05-band5-approach-day`), keeps grass cover and shadow-mottling over
the terrain surface. This axis is a real, visible improvement and should be
treated as the template for the rest of the world.

**Vegetation layering in the wides — good, with one recurring "planted-grid"
tell.** `survey/02-valley-floor` and `locations/02-mill-pond-approach-day`
both layer well: open grass between grove clumps, a dense tree wall used
deliberately to frame the mill/pond as a discovery, understory scrub visible
at grove edges. `survey/04-three-quarter` has a clear lone hero tree — taller
and differently silhouetted than everything around it — reading well against
the mill roofline, plus real scale variety between it, the ridge-line trees,
and background hills. Reeds/scrub at the pond bank are present and read as
intentional (`ground/water-01-pond-eye`, `water-03-stream-grazing`). The
recurring problem: in several forest-band shots
(`ground/ground-02-band2-stone-root-day`, `-fog`, `-rain`, and the far
shoreline in `ground/water-01-pond-eye`) the tree line on the right side of
frame is arranged in an almost perfectly even, ruler-straight row of
identical height and identical canopy silhouette — it reads as an orchard row
or an un-varied scatter grid, not a natural grove edge, and it sits directly
beside a more naturally clustered stand of trees on the left of the same
frame, so the contrast between "authored" and "generated" is visible within
a single image.

**Night value range — a genuine highlight, with the same one outlier.**
`locations/01-village-twins-night`, `locations/01-village-standing-night`,
and `ground/ground-04-band4-ironwood-night` all have real value structure:
near-black grass silhouettes in the foreground, warm lit-window glow at
midground, a bright moon accent, and small blue-white flowers picking up
rim light in the dark — this is a full range, not a flat dark mid-tone.
`ground/ground-06-stronghold-night` adds a moody infiltration read with glowing
cyan cable lines and a distant campfire glow against near-black silhouettes,
also a full range. The exception is again `stands/06-moon-stand-night`,
which collapses all of that into the flat magenta wash described above —
one broken shot inside an otherwise strong category.

## Other things worth flagging while looking at this set

- Scale reads consistently where checkable: the trainer, the two other
  humanoid NPCs, and the armored NPC beside the player in
  `ground/ground-05-band5-approach-night` / `-golden` all agree on
  roughly the same human scale, and buildings, fences, and rocks sit at
  plausible sizes beside the trainer throughout the location set.
- Creatures are essentially absent from this frame set — it is an
  environment survey. The bar questions below are answered on the world
  only; they cannot speak to whether the game's creatures hold up, because
  none appear in these frames in a way that permits judgement.
- No z-fighting, texture stretching, or LOD/chunk seams were visible in any
  frame reviewed at full resolution.

## Three biggest gaps, ranked

1. **The sun and moon break identically, in the same camera situation, and
   it is the single worst thing in the set.** `03-rise-overlook-dawn` and
   `06-moon-stand-night` are both full-frame red/magenta washes with no sky
   -to-ground value separation — not "dawn" or "night" by any reading, just
   a stuck colour layer. The keyart and the Palworld bar both show skies
   with real gradient and value structure at every time of day; a flat wash
   is the opposite of that, and it happens to appear specifically in the
   open-sky, fog-plane-heavy overlook composition.
2. **The sun disc is not modest or crisp whenever it is actually in frame at
   a low angle.** `01-spawn-outward-golden`, `03-rise-overlook-golden`, and
   `05-spawn-low-sun` all show an oversized, oval, pale-white bloom eating
   roughly a fifth of the sky — nothing like the clean disc the same sun
   produces higher in the sky in `02-mill-pond-standing-day`.
3. **Distant vegetation scatter at the overlook is thinner than round 2's.**
   The valley floor in `03-rise-overlook-day` shows fewer distinct tree
   clumps across the mid-ground than the same shot in round 2, which used to
   read as a forested basin and now reads more as open moss/grass with a
   handful of clusters near the village.

## Bar questions

**A. Do these frames read as belonging to the world in the key art?**
**Partial — call it a qualified yes for the ground and vegetation work, no
for the sky states.** The ground close-ups, path treatment, water banks, and
grove framing in the mill-pond approach genuinely have the key art's
lived-in, textured, layered quality. But the key art's sky is warm, painterly,
and has full value range at every implied time of day — nothing in it looks
like the flat red/magenta wash this round produces at the overlook, and the
key art's sun (where suggested) is soft but never a blown oval eating a fifth
of the frame. The world's surfaces have closed distance with the reference;
its skies have not.

**B. Shown beside the Palworld shots, would someone say these are trying to
be the same kind of game?** **Yes.** Ground density, path/grass blending, and
water-bank treatment are now doing real work toward Palworld's "lived-in
world" bar, and the day-time framing shots (mill pond, valley floor) hold up
reasonably well on ground and foliage density and colour saturation. The sky
failures pull against this — Palworld does not have washed-out red frames or
oval suns — but they read as a bug in an otherwise game-appropriate world,
not as a difference in ambition or genre.

## Fixable-by-scene vs needs-new-art

**Fixable by changing the scene (all three ranked gaps are in this
bucket):**
- The dawn/night colour-wash bug (gap 1) is a lighting/environment/fog
  configuration issue tied to a specific camera composition (open sky + fog
  plane) — not a missing asset. It needs the atmosphere/fog colour or
  exposure logic corrected for that condition, not new art.
- The oversized sun halo (gap 2) is a bloom/glare or sun-disc-size/colour
  tuning issue at low sun angles — again a scene/shader parameter, not a
  new asset.
- The thinner distant tree scatter at the overlook (gap 3) is a placement
  /density setting for that specific vantage — the tree assets used
  elsewhere in the set are already good enough (see the valley floor and
  mill-pond shots); this is a scatter-density regression to restore, not new
  art.
- The evenly-spaced "orchard row" tree lines at several forest-band edges
  are also a scatter/placement fix (break the regular spacing, vary height
  and canopy shape per instance), using assets already in the build.

**Nothing observed in this round required new art to fix.** Every specific
defect found here — the two colour-wash frames, the oversized sun, the
sparser distant scatter, the regular tree rows — is a placement, density, or
lighting/atmosphere parameter, not a missing or inadequate mesh, texture, or
character asset. That is consistent with the ground-level work in this same
round, which shows the underlying assets (grass, path materials, water,
trees, buildings) are already capable of the target look when the scene
around them is tuned correctly.

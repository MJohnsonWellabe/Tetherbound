# Blind visual-judge pass — Meadows Hall, AUDIT-E

**Judged by:** an independent sub-agent spawned by AUDIT-E, given only the 11
frames in this directory plus `docs/reference/tetherbound-meadows-keyart.png`
and `docs/reference/palworld-0*.jpg`. No handover, prior judge report, design
document, or knowledge of what changed was provided — this is a blind pass per
`ralph/conventions.md` and `.claude/skills/visual-judge`.

**Frames judged:** `H-01-approach-400`, `H-02-sigil-gate`,
`H-02b-sigil-gate-raised`, `H-03-ramp-foot` (day/golden/night),
`H-04-gate-mouth`, `H-05-east-flank`, `H-06-west-keep`, `H-07-courtyard`,
`H-08-wall-close` — captured 2026-08-30/31 against `main` @ `453107fb` with
`tools/_judge_capture_hall.gd`.

The verdict is reproduced verbatim below (only the transport wrapper is
removed). See `../E-2026-08-31.md` §E2 for this lane's own reconciliation of
this verdict against the T1-HALL chain's own claims.

---

## Capture validity

All 11 frames show real, populated scenes — no buried camera, no blank sky,
no black frame. `H-03-ramp-foot-night` is very dark but that's an intentional
low-light exposure with content still present (moon, silhouetted towers, lit
torches, foreground plants), not a broken capture. All 11 are usable for
review.

## Defects, ranked by cost to the player's first impression

**1. The hall does not read as a landmark from distance — it disappears.
(H-01-approach-400, H-02-sigil-gate)**
In H-01, the supposed landmark is a faint grey smudge at roughly x600–650,
y370–390 — indistinguishable from the flat grey horizon band behind it, and
easy to miss entirely on a first look. In H-02, closer, it registers as a
small grey rectangle (x630–760, y350–430) with almost no value or hue
separation from the equally flat, dark backdrop behind it. This is the single
biggest failure against the brief's own core promise ("silhouettes and
landmarks visible from distance") and against the keyart's dedicated landmark
panel, where a spire reads instantly, warmly lit, against open sky at
thumbnail size.

**2. The horizon has no mountain form anywhere in the outdoor frames — it's a
flat curtain, not terrain.**
Every outdoor shot (H-01, H-02, H-02b, all three H-03 variants, H-05, H-06)
has the same dark blue-grey band sitting across the horizon with zero
ridgeline, zero peaks, zero value gradation — it reads as fog or a skybox
seam, not land. Compare every single keyart panel, all of which have crisp,
sometimes snow-capped mountain silhouettes doing real depth work. This is
what makes distance fail to read in nearly the whole set, not just H-01/H-02.

**3. The stronghold reads as a generic fantasy castle-kit, not this game's
specific antagonist stronghold.** (H-03-ramp-foot, H-04-gate-mouth)
The keyart's stronghold panel is a broken, ivy-swallowed ruin with visible
industrial/tech intrusion (cabling, scaffolding, pylon-like framework)
grafted onto crumbling stone, plus a glowing occupied-looking doorway. What's
in-engine (H-03, H-04) is four clean crenellated corner towers, a smooth flat
pale wall (x480–820, y70–180 in H-03) with a uniform "wallpaper" patch of
ivy, and no visible tech/mechanical element anywhere near the building except
an ambiguous stray cyan line (see #4). Nothing in these frames signals
"occupied by a hostile industrial faction" — it signals "stock castle asset."

**4. An unexplained thin cyan line/beam recurs across multiple frames with no
visible source or anchor.**
Visible in H-03 (day, golden, and night variants) arcing off-frame at upper
right, and again as a vertical beam through the gate gap in H-06 (x290–330,
y360–460). It's perfectly straight, uniformly bright, and connects to nothing
in any of the four frames it appears in. This reads as a rendering artifact
(stray debug geometry, or an unattached VFX/cable emitter) rather than an
intentional effect, and needs to be checked regardless of what it's meant to
be.

**5. Antagonist red has drifted soft/pink, losing its danger signal.**
(H-08-wall-close, banners throughout)
The grunt's uniform and the gate banners (H-02, H-07, H-08) use the same red
as each other — good color discipline, faction-consistent — but the actual
hue is a desaturated rose-pink rather than the deep oxblood in the keyart's
stronghold banners. On the character in H-08 especially, it reads soft and
unthreatening, undercutting "occupying hostile faction" tone.

**6. Sky/cloud rendering is inconsistent with the ground below it.**
Every daytime frame (H-01, H-02, H-02b, H-03 day/golden) has heavily smeared,
motion-blurred cloud shapes at the top of frame that look like a DOF or blur
setting applied only to sky, sitting above crisply detailed ground and trees.
It reads as broken, not stylized, and doesn't match the keyart's crisp
painterly clouds.

**7. Procedural-looking placement in several spots.**
- H-02b: two tree clusters flanking the path are near-mirror-symmetric round
  "pom-poms" (x0–400 and x850–1280, y450–780) — reads as placed-to-frame-the-
  path rather than a naturally irregular grove.
- H-06: small flat grey rectangular objects scatter across the foreground
  lawn (x0–350, y620–720) at near-regular intervals — unclear what they
  represent, and the even spacing is a classic scatter-tool tell.
- H-05: two thin isolated trees (x830–980, y420–580) stand alone with nothing
  else nearby, breaking the clustering the rest of the scene otherwise does
  reasonably.

**8. Material/lighting mismatch on the west tower.** (H-06-west-keep)
The tower face occupying the right two-thirds of the frame is almost pure
flat dark grey-brown with no directional highlight, while the wall and roof
to its left in the same shot, same light, show clear grazing highlights and
form. Neighboring geometry lit inconsistently under identical lighting reads
as a shading bug, not a shadow choice.

**9. The moon is a flat, unshaded disc.** (H-03-ramp-foot-night)
x300–430, y140–260: a perfectly flat pale circle with no crater detail, no
phase shading, no soft glow/halo. Reads as a placeholder sphere rather than a
rendered moon, in an otherwise reasonably atmospheric night shot.

**10. Ivy reads as uniform wallpaper, not growth.** (H-04, H-05, H-07)
Same leaf density top to bottom across the whole covered area, no thinning,
no clumping, no bare patches — an organic-growth surface that looks tiled
rather than authored.

**11. Set-dressing props (bench, crates) look factory-new against aged
stone.** (H-07-courtyard, H-08-wall-close)
The wooden bench in both frames is pale, clean, unweathered — no dirt, no
wear — sitting inside what's meant to read as an old occupied ruin.

**12. Brazier smoke is a low-res blob sprite.** (H-04-gate-mouth, x120–160/
y255–290 and mirrored right side)
Small cauliflower-shaped puffs that don't integrate with the fire below them
— reads more like an unfinished particle placeholder than smoke.

## What's actually working (worth naming, not just defects)

- **Scale agreement is good.** H-08 gives a genuine ruler: the trainer
  against the archway and stone coursing produces a plausible ~2.5m doorway
  and human-scale block sizing — this is one part of the rubric that passes
  cleanly.
- **Faction color consistency** (wrong hue aside) is correct: banners and
  grunt uniform share one palette, sigil is identical on both.
- **H-05's terrain form** is the best ground read in the set — visible hill
  roll, soft directional shadow gradient across the slope, actual undulation
  rather than a flat green plane.
- **H-07's stonework** (cobble walls and floor, individual blocks with
  mortar/AO) is the best material read in the set, and the dark
  archway-with-blue-glow-at-the-end in that same frame is a genuinely
  effective "mystery" beat.
- **Grass/foliage density in the near-ground** (H-02, H-03) is competitive
  with, arguably denser than, the Palworld references' own ground cover —
  this part of the brief is not the weak link.

## Verdict

**Three things that most separate these frames from the references, ranked:**

1. **Landmark readability at distance is simply absent** (H-01, H-02) — the
   keyart's own landmark panel and Palworld-04's plateau shot both deliver an
   instantly legible silhouette against sky/mountains; here the hall blends
   into a flat grey nothing until the player is nearly on top of it.
2. **No mountain silhouette anywhere** (all outdoor frames) — every keyart
   panel uses layered, sometimes snow-capped peaks to build depth; here the
   horizon is a flat color band doing no work at all.
3. **The stronghold is a generic castle-kit, not the industrial-ruin hybrid
   the keyart specifically designs for this location** (H-03, H-04) — the
   keyart's stronghold panel shows cabling/scaffolding grafted onto broken
   stone; nothing in the build shows any mechanical intrusion, only an
   unexplained stray cyan line that reads as a bug.

**Bar question A — Do these frames read as belonging to the keyart's world?**
**No.** The pastoral pieces (grass, oak-style trees, wooden fences,
wildflowers) are a reasonable match to the "Starting Settlement" panel's
palette and mood. But the location this survey is actually about — the
stronghold — misses its own specific keyart panel on three separate axes at
once: no mountain backdrop depth, no industrial-tech intrusion on the ruin,
and a softened rather than dangerous antagonist red. A player shown H-03/H-04
next to the keyart's stronghold panel would not connect them as the same
building concept.

**Bar question B — Beside the Palworld screenshots, would this look like the
same kind of game?**
**No**, on balance. Ground density and general third-person-fantasy-with-
creatures staging are in the right neighborhood, so it's not a total miss.
But every single Palworld reference frame has a creature, a character in
motion, UI, or lived-in base clutter — none of that appears anywhere in these
11 frames, so there's no basis to compare "does a fight look like an event"
or "silhouette clarity of creatures against terrain" at all. And the
architecture that is on screen — flat pale castle wall, uniform ivy
wallpaper, unweathered furniture — reads as a lower level of finish than
Palworld's weathered cliffs and lived-in base in 04/05.

**The split — fixable by tuning the scene vs. needs art that doesn't exist
yet:**

*Fixable without new assets:*
- Antagonist red hue (pink → oxblood) — likely a material color parameter.
- Tree cluster symmetry and the grid-like flat props on the H-06 lawn —
  re-scatter with jitter/irregularity.
- The stray cyan line — delete or properly anchor whatever emitter/geometry
  is producing it.
- West-tower shading mismatch (H-06) — check the light bake/normals on that
  mesh instance.
- Cloud/sky blur inconsistency — a post-process or DOF setting, tunable.
- Ivy density variation, if the ivy is a maskable decal rather than a fixed
  mesh card — adjust the mask.
- Prop weathering on bench/crates, if a weathered material variant already
  exists elsewhere — swap it in.

*Needs art that isn't in the build:*
- Any pylon/scaffolding/cabling element actually grafted onto the stronghold
  — nothing resembling this exists on the building in any frame; this is the
  single largest gap versus the keyart's specific stronghold panel and needs
  a new prop family, not a retint.
- Real mountain geometry with a legible ridgeline, if the current horizon is
  genuinely just a flat backdrop plane/fog color rather than terrain mesh
  sitting behind heavy atmosphere — this is likely the root cause of defect
  #2 and is a terrain-authoring task, not a tuning pass.
- A textured moon (craters/glow), if the current asset is truly a flat-shaded
  sphere.
- A distinct broken/rubble stone material for the ruin, if the intent is for
  this hall to look damaged rather than intact — the current stone is a
  clean, undamaged castle-kit texture with no cracking or rubble variant
  visible anywhere in the set.

# 02 — Art Bible

## Direction, in one line

Palworld-adjacent stylized. Rounded low-poly forms, thick readable
silhouettes, saturated color, soft cel shading, warm directional light.
**Not photoreal, not toy-flat either.** The world should feel touchable, the
way a good animated film's environments do.

## Reference set

Build a `docs/reference/` folder before any art system work starts. Pull 8-12
images across these buckets and keep them in the repo, not just in a
conversation:

- Palworld: open meadow shots, base-building shots, a wild pal in its
  environment.
- Genshin Impact: Mondstadt grassland, for saturated painterly ground color.
- Breath of the Wild: the Great Plateau, for patchy, non-uniform ground
  color and readable silhouette-driven trees.
- Your own best in-game screenshot once one exists. It becomes a reference
  the moment it's good, which raises the bar for everything after it.

Every visual critique in this project scores against this folder. Never
against real photography. A stylized meadow judged against a real photo will
always read as "flat" or "fake," because that's the wrong test.

## Palette

| Role | Color | Use |
|---|---|---|
| Meadow green (base) | Warm mid green | Grass base tone |
| Meadow green (dry patch) | Golden olive | FBM-driven patchiness, never uniform |
| Stone grey | Desaturated cool grey | Rock, cliff, building stone tier |
| Bark brown | Warm mid brown | Trees, wood tier building |
| Sky | Soft warm blue, golden near horizon | Sky dome, feeds ambient light |
| Danger accent | Hot iron-orange | **Reserved for Team Tether only** — collars, banners, grunt uniforms. Never used elsewhere, so it always reads as "this is the enemy" |
| Verdant type | Leaf green | Type ring color coding |
| Ember type | Warm red-orange | Type ring color coding |
| Tide type | Teal-blue | Type ring color coding |
| Stone type | Warm grey-tan | Type ring color coding |
| Spark type | Bright yellow | Type ring color coding |

No pure black anywhere, including shadows. Shadow color should be a darkened,
desaturated version of the ambient sky color, never `#000000`.

## Lighting model

One warm directional key light (the sun), soft shadows, capped resolution
(1024 desktop / 512 mobile). One sky `CubeTexture`, built once, feeding both
the visible sky dome and the PBR environment/IBL reflection on every
surface — this is the single most important discipline in the whole art
bible. If the sky and the ambient light are two separately tuned things,
they will drift apart and the world will look subtly wrong in a way that's
hard to name. One function, sampled twice, cannot drift.

Fog is present but light, tinted to match the sky color at the horizon, used
for depth cueing on the meadow's open sightlines, not to hide draw distance
problems.

## Material rules by category

**Terrain and structures — standard PBR.** Ground, rock, and building
pieces use `PBRMaterial` fed by procedural, GPU-baked textures
(`CustomProceduralTexture`) built from layered FBM/simplex noise, not flat
downloaded tiles. Derive the normal map by Sobel-sampling the same function
used for albedo, so the lighting response can never visually disagree with
the color pattern painted on top of it.

**Pals and characters — stepped cel shading.** A 2-3 band toon gradient via
Node Material or a hand-written `ShaderMaterial` with a stepped `NdotL`
term. This is a deliberate visual split: the world is grounded and PBR, the
living things are graphic and toon-shaded, which is exactly how Palworld and
its genre-mates separate "the collectible layer" from "the world layer" so
creatures always pop against their environment.

**Vegetation — instanced, unshadowed.** `ThinInstance` for grass, bushes,
and tree canopy at density. Keep foliage out of the real-time shadow map
entirely; fake the occlusion with a cheap analytic AO term (darker toward
the base of a clump, lighter toward the tip) rather than resolving thousands
of instanced blades in a shadow pass. Cheaper and better-behaved.

## Pal visual identity

Fifteen species from six rigged CC0 base models (Quaternius Animated
Animals), differentiated by tint, scale, and one attached accessory prop
(horn, crest, plume, moss patch, spark ring) per `docs/reference/species.json`
mapping. This gets a full visible roster fast and lets any individual
species be replaced with a unique model later without touching gameplay
code, because the mapping is data, not hardcoded geometry.

Every pal needs an unmistakable silhouette at combat distance on a phone
screen. If two species read as the same blob from 15 feet away in-game,
that's an art bug, flag it in the critique log.

## The critic-loop process

This is the mechanism and the style target. For the literal system-by-system
order, the per-system procedure, and live status, see
`docs/06_VISUAL_SYSTEM_PHASING.md` — that doc is the checklist, this section
is why it works.

This is the actual mechanism, not a metaphor. It comes from a documented
real-world case (a Three.js procedural-jungle project) whose brief specified
exactly this loop and whose README lists the bugs it caught. Quoting the
mechanism precisely because the precision is what makes it work:

1. **One visual system at a time, in a fixed order, not parallel.** Fan-out
   across unrelated systems dilutes the loop. The exact order and live
   status live in `docs/06_VISUAL_SYSTEM_PHASING.md`, not here, so there's
   one place this can't drift out of sync.
2. **Build it, then spawn a literal separate sub-agent as the critic.** That
   sub-agent receives only rendered screenshots and the `docs/reference/`
   images for that system. It never sees source code or the conversation
   that built the thing. It returns a score and a **named, specific** fix
   list, not a vibe. "Grass reads uniform, needs FBM patchiness like the
   BOTW reference" is usable. "Looks kind of flat" is not.
3. **Loop on that one system until the critic signs off, or until
   improvement genuinely plateaus.** Plateauing at a real number after
   several honest rounds is a legitimate outcome, log it and move on rather
   than churning.
4. **Log every round** to `docs/archive/VISUAL_CRITIQUE_LOG.md`: system,
   score, round count, what was fixed, what was left. This is the project's
   honest scorecard, the same way a real dev log would read.

What this catches that reading code never would: inverted mesh winding
rendering a surface black, alpha-blending bugs producing dark outlines
around instanced foliage, a shadow or light direction that's only wrong at
a specific time of day, a reflection sampling the wrong source and painting
a patch the wrong color. All of these are invisible in a diff and obvious
in a screenshot. That gap is the entire value of spawning a critic that
only ever looks.

This is a mandatory gate, not a milestone-end sweep. Per `CLAUDE.md`'s
development philosophy, quality wins over pace: a system is not marked done
in `docs/05_ROADMAP.md` until it has cleared this loop, whatever that costs
in time. If a deadline is at risk, the response is to cut a different system
out of the milestone, never to wave a system through under-baked. Run the
whole-scene version of this pass again at M5 to check individually-passing
systems still agree with each other on light, palette, and scale once
they're all on screen together.

## What this bible explicitly rejects

- Photorealism, or any critique scored against real photography.
- A single "make it look better" pass with no reference set and no critic —
  this produces generic defaults, which is the exact problem this bible
  exists to prevent.
- Fully procedural, zero-asset purity for creatures. Sourced CC0 rigged
  models are the right tool for pals; procedural generation is the right
  tool for terrain surfaces and lighting. Use each where it's strong.

# Handover — T1-VARIANTS (Aspect-variant marking fix), 2026-08-30

**Branch:** `ralph/T1-VARIANTS`, off `origin/main` (`bf815014`). Working tree
clean at the time of writing except this handover and the `ASSET_LEDGER.md`
row, both about to be committed.

## What I was asked to do

`ralph/MEADOWS_EXIT_CRITERION.md` B1 requires every creature to read as "a
distinct designed animal, not a retint of another". JUDGE-3's blind pass
(`ralph/reports/JUDGE-3-2026-08-30.md` section 5) found the four Aspect
variants (Nightburrow, Stormtrail, Riftfrill, Ashtusk) failed it: "they read
as a retint... one shared decal mask, hue-swapped four times", plus four
named defects — hard pixel-staircase aliasing, mechanical mirroring, bleed
over the eyes, and a flat/unlit look. T3-INSTALL had already correctly
declined to paper over this with a blur/hue-nudge. My scope: materials and
textures only — no new meshes, no Meshy spend, no touching species.json,
spawn placement, terrain/scatter, or UI.

## Root cause, not just symptoms

I opened `tools/generate_aspect_variant_textures.py` (the generator all four
variants' glow maps go through) before touching anything, and traced each of
JUDGE-3's four named defects to a real, specific bug rather than "the mask
needs to look nicer":

1. **Aliasing.** `build_glow_map()`'s selection was a boolean threshold
   (`v <= cut`) grown by a binary `ImageFilter.MaxFilter`. Neither has any
   concept of a soft edge at any radius — a threshold is always a hard step,
   and `MaxFilter` grows a hard step into a bigger hard step. That is the
   "tetris chunk" read JUDGE-3 described exactly.
2. **Eye-bleed.** `select: feature` finds the darkest N% of the
   *already-repainted* albedo. But `repaint_creature_textures.py`'s own
   `finish_pass` (upstream in the same pipeline) forcibly re-stamps the
   source's own darkest pixels — eyes, nostrils, outlines — down to a fixed
   near-black value *specifically so they survive the recolour*. So by the
   time the glow generator asks "what are the darkest pixels here", the
   eyes/nostrils are, by construction, very often the darkest thing in the
   frame. The armor-crack search was regularly finding the face.
3. **Mirroring.** Nothing in the old selection broke left/right symmetry.
   Two different fixes needed to combine here: the eye-bleed above is
   itself markedly bilaterally symmetric (two eyes, symmetric nostrils), and
   a percentile threshold with no breakup reads as a smooth "airbrush
   stencil" rather than a natural, asymmetric marking.
4. **Unlit/flat.** Every selected pixel got the same flat `intensity`, so a
   crack looked like solid paint with a hard edge rather than something
   with a bright core and a falloff — which is what a real glowing crack or
   ember actually looks like even under additive-only emission.

## What I changed

**`tools/generate_aspect_variant_textures.py` — `build_glow_map()` rewritten:**

- Every selection (`select: feature` and `select: match`) is now a
  **continuous 0..1 smoothstep score**, not a boolean, with a final Gaussian
  blur pass. No more hard edges anywhere in this file.
- A **tight pupil/nostril exclusion**, independent of `finish_pass`'s own
  broader feature mask: the darkest 0.15th percentile of the *source*
  (pre-recolour) value channel, dilated a few pixels. Deliberately tighter
  than `finish_pass`'s own percentile (3% on Burrowback, whose natural black
  fur/mask/legs would make a broader cut strip real seam candidates too) —
  true near-black *pinpoints* are pupils and nostril holes on every one of
  the four species, measured directly, and nothing else.
- A **model-space value-noise clump** (`tools/creature_overlays.py`'s own
  `_value_noise_3d`, reused rather than reinvented — it already exists for
  exactly this "break a smooth predicate into an organic clump, in 3D so a
  mirrored UV pair does not have to look mirrored" job, for the moss/leaf
  overlays). Turns a flat percentile blob into a vein/crack network.
- `select: match` gained an optional `hue` band, used to tighten Ashtusk's
  tusk selection off the model's own grey stone armour (see below).
- Fixed a real determinism bug I found while checking my own work: both this
  file and `tools/creature_overlays.py` seeded their clump noise with
  Python's builtin `hash()` on a string tuple, which is salted per-process
  (`PYTHONHASHSEED`) and not stable across runs — silently violating this
  file's own "idempotent... pure function of its inputs" docstring claim.
  Confirmed by running the generator twice in a row with no input changed
  and getting different coverage numbers each time. Replaced with
  `zlib.crc32`; verified two consecutive runs now produce byte-identical
  PNGs (`sha256sum`).

**`data/creatures/aspect_variants.json` — per-variant tuning, each checked by
rendering, not guessed:**

- **Nightburrow.** Glow colour moved from `#a855f7` (read as bubblegum
  magenta, off the board's own Violet Glow/Amethyst Flame swatches) to
  `#8f6bf0`, intensity eased from 1.8 to 1.45 so the additive emission does
  not clip toward hot pink. Clump params added.
- **Stormtrail.** The board's own close-up shows a lightning network
  covering most of the head/spine/legs; the shipped render measured "~3% of
  the silhouette". Coverage/percentile raised twice (checked by rendering
  both times — the first pass was still measured too faint at night). Colour
  moved from a plain sky-cyan to the board's own more indigo "Static Blue". A
  `z_max` bound, measured directly off this species' own anatomy map (its
  darkest 0.3% of source pixels cluster at unit z 0.84–0.99), keeps both the
  glow and the lightning-marks tint off the muzzle/eye region on top of the
  generator's own pupil exclusion.
- **Riftfrill.** Same `z_max` treatment (measured z 0.84–0.89 for this
  species specifically), coarser clump grain for a "soft rift blob" read
  distinct from the other three's finer seams.
- **Ashtusk.** `armor_cracks` percentile tightened (fewer, deeper, more
  concentrated cracks — the board explicitly asks for "the valleys between
  plates and at the joints", not an even wash). `tusks` narrowed with a
  `sat_min` floor and a warm hue band, because the old bounds (`sat_max`
  only) also matched the model's own grey basalt/stone armour patches,
  which cover far more surface than the two tusks and diluted the read.

**`scripts/creatures/creature_body.gd` — one new lever, code not texture:**
`ASPECT_EMISSION_BOOST`. The ordinary vivid/shiny/alpha colourways wire a
*full-body copy* of the albedo into the emission slot, and the shared
`creatures_visual.json::emission_scale` (0.5) exists specifically to tame
that so a creature does not wash out pale in daylight. An Aspect variant's
synthesised glow map is the opposite shape — a mostly-black canvas with a
sparse network of cracks — and taming it by the same shared multiplier
crushed the one thing meant to read as supernatural glow. Measured directly:
at the shared scale alone, Stormtrail's veins were essentially invisible in
a night render with only the VFX billboards showing. This multiplies on top
of the shared scale, only for an aspect-variant suffix; every ordinary
colourway's rendered material is byte-for-byte unaffected (checked: the
lookup defaults to 1.0 for any suffix not in the table).

**`scripts/creatures/vfx/aspect_vfx.gd` — one new billboard, Ashtusk only:**
`_draw_tusks()`, a small warm-glow disc pair anchored at mouth height, same
convention the existing shared eye-glow billboard already uses
(`Vector3(0, height*0.83, radius*0.85)` for eyes; mine sits a little lower
and further forward). JUDGE-3 named this specifically: "Ashtusk's
'ember-glowing tusks' specifically did not read at all... make them read."
There is no per-vertex tusk mask without new geometry, only a colour/anatomy
heuristic on the texture side (tightened above, but still imperfect — see
"Known limits"), so this billboard is the guaranteed-visible half of the
fix and the texture layer is the ambient half. Gated by a `tusk_colour` key
in the variant's VFX preset; absent for the other three, so nothing else
changed.

## Evidence

New capture tool, `tools/_capture_t1_variants_lineup.gd` (this lane's own,
modelled on the existing `tools/_capture_aspect_variants.gd`): each variant
rendered on a small neutral stage **beside its own base species**, same
light, wide (full body + trainer for scale) and close (both heads/busts),
under a plain day light rig and a plain night light rig — not per-variant
mood lighting, since this pass exists to compare base vs. variant fairly
under the same conditions. 16 frames, `ralph/reports/T1-VARIANTS/shots/`.

A synthetic stage rather than the real terrain — same choice and the same
reasoning the existing aspect-vfx capture tool already documents (a
comparable rig+creature scene renders in well under a minute; the full
world's own known capture defect, silently missing grass geometry with a
haze the build lacks, cannot happen on a stage that never loads
terrain/scatter). Every day-wide frame's ground plane is a real green
`PlaneMesh` with an explicit albedo, checked by eye in every frame before
using it as evidence — no missing-grass risk on this stage in the first
place. A real Burrow Warrens placement check (this lane's own predecessor
already flagged this as untested for Nightburrow specifically) stays
untested here too — out of scope, terrain/spawn are other lanes'.

What the renders show, checked by eye against the reference boards
(`docs/art/reference/creature-expansion-2026-08-30/{01,02,07,08}_*.png`):

- **Nightburrow.** Visible violet crack network on the back/shoulders next
  to the base badger's moss patches; both eyes clean in every close-up, no
  bleed. Purple flame VFX and eye-glow both fire.
- **Stormtrail.** Indigo vein network plus gold lightning-tint visible at
  both lineup and close distance, day and night; clearly reads as
  "storm-touched" beside the plain base wolf. Still the most understated of
  the four at pure lineup distance, honestly — see "Known limits".
- **Riftfrill.** Strong, clearly distinct lilac/violet frill and marking
  network next to the base's plain teal, day and night; eyes clean.
- **Ashtusk.** The tusk itself visibly glows warm orange in the close crop
  (both the tightened texture match and the new billboard contribute); ember
  cracks visible on the face/back; unambiguously distinct from the plain tan
  base boar.

All four pass the basic bar the judge's own question sets: put the variant
beside its base and it reads as a different, deliberately marked animal, not
a hue-shifted copy.

## Tests run

- `tools/generate_aspect_variant_textures.py` (all four) — clean, and
  verified idempotent (two consecutive runs, byte-identical PNGs via
  `sha256sum`, after the seed fix).
- `godot --headless --path . --script tests/smoke_art.gd` — **art: OK**
  (models load, sized to their colliders; alpha/shiny presence checks pass;
  vegetation/rank checks unaffected).
- `godot --headless --path . --script tests/run_tests.gd -- --only=test_creature,test_wild_alphas`
  — **45 tests, 173 assertions, 0 failed.**
- Rendered evidence above, checked by eye against the reference boards
  before calling anything done (per this lane's own instruction: judge
  against "would someone say these are four distinct creatures, or one
  creature recoloured").

I did not invoke a blind judge myself — that is the coordinator's next step,
per this project's own "do not grade your own visual work" rule.

## Known limits / honest gaps

- **Ashtusk's tusk texture match is still not a perfect per-vertex mask.**
  Tightening the hue/saturation band reduced but did not eliminate overlap
  with the model's own pale grey stone-armour patches (measured by k-means
  clustering the old selection in anatomy space before touching the code —
  the "ivory" match was landing on stone as often as tusk). The billboard
  fallback is what actually guarantees the read; the texture layer is
  best-effort ambient glow on top of it.
- **Stormtrail is still the least assertive of the four at pure lineup
  (wide, both-creatures-in-frame) distance**, even after two coverage/energy
  passes, each checked by rendering. Close-up and night reads are solid. If
  a future blind pass calls this out again, the next lever is
  `data/creatures/aspect_variants.json`'s `lightning_marks.coverage` /
  `storm_veins.percentile` and `creature_body.gd`'s
  `ASPECT_EMISSION_BOOST["stormtrail"]` — no code restructuring needed, just
  retuning already-exposed numbers.
- **The cast/creature art-style mismatch JUDGE-3 named** (stylised trainer
  next to naturalistic wildlife) is real in every wide frame here too, and
  is explicitly out of this lane's scope — a whole-roster art-direction
  decision, not a materials fix for four variants.
- **No real-terrain placement render** (the actual Burrow Warrens at night
  for Nightburrow, specifically) — out of scope per this lane's brief
  (terrain/scatter is other lanes' territory), and flagged again rather than
  silently dropped since it was already flagged once before.
- I did not touch `data/creatures/shiny_colourways.json`'s own overlay
  system beyond the one-line determinism fix in `creature_overlays.py` — that
  fix changes noise SEEDING only (same technique, now reproducible), not
  which species get which overlay or how they look; the whole roster's
  shipped moss/leaf/antler overlays are visually unchanged by it (the seed
  changed from "random per process" to "one fixed value", and the actual
  authored `where`/`color`/`coverage` numbers for every other species'
  overlay are untouched).

## Full file footprint

**Code (mine — the material/VFX code path):**
- `tools/generate_aspect_variant_textures.py` — `build_glow_map()` rewritten
  (continuous scoring, pupil exclusion, clump breakup, blur), new
  `_stable_seed()`/`_hue_band_score()`/`_blur()`/`_clump()`/`_eye_exclusion()`
  helpers.
- `tools/creature_overlays.py` — one-line determinism fix
  (`zlib.crc32` instead of builtin `hash()` for the clump seed). Shared by
  the whole roster's overlay system; behaviourally identical except now
  reproducible across runs.
- `scripts/creatures/creature_body.gd` — new `ASPECT_EMISSION_BOOST` const
  and its one call site in `_swapped_material()`.
- `scripts/creatures/vfx/aspect_vfx.gd` — new `_draw_tusks()`, `tusk_colour`
  preset key (Ashtusk only), wired into `_physics_process()`.
- `tools/_capture_t1_variants_lineup.gd` (new) — this lane's evidence
  capture tool.

**Data (mine — presentation only):**
- `data/creatures/aspect_variants.json` — per-variant glow/overlay tuning
  described above (colours, coverage, percentile, new `z_max`/`hue`/`clump_*`
  keys).

**Generated assets (offline tool output, checked in like every other
colourway):**
- `assets/creatures/tetherbound/burrowback/models/*_emissive_nightburrow.png`
- `assets/creatures/tetherbound/trailpup/models/trailpup_extracted_{base_color,emissive}_stormtrail.png`
- `assets/creatures/tetherbound/paddlenewt/models/*_{base_color,emissive}_riftfrill.png`
- `assets/creatures/tetherbound/tuskroot/models/*_emissive_ashtusk.png`
- (Nightburrow's and Ashtusk's `_base_color_*` siblings are unchanged —
  their `rules`/finish were not touched, only their `glow` specs, so only
  the emissive half regenerated differently.)

**Evidence:**
- `ralph/reports/T1-VARIANTS/shots/*.png` — 16 frames, 4 variants × (day,
  night) × (wide, close), each beside its base species.

**Docs:**
- `docs/ASSET_LEDGER.md` — follow-up note under the existing T1-CREATURE-ART
  row (same generated files, no new asset, no Meshy spend).
- This file.

**Nothing else touched.** No changes to `data/creatures/species.json`, spawn
placement, `scripts/world/stronghold.gd`, terrain/scatter configs, or UI.

## What I would do next

1. Route the 16 committed frames to a blind judge — I did not grade my own
   work.
2. If the judge still calls Stormtrail under-scale, retune the already-data
   exposed coverage/percentile/boost numbers named above rather than
   touching code again.
3. Once T3-CREATURES' species entries for the four variants land (dormant
   contract, unchanged by this lane — see the original T1-CREATURE-ART
   handover), a real Burrow Warrens night render for Nightburrow specifically.

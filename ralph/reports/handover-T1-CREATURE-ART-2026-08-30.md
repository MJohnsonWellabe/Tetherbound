# Handover — T1-CREATURE-ART (Aspect-variant creature materials + VFX), 2026-08-30

**Branch:** `ralph/T1-CREATURE-ART`, off `claude/tetherbound-coordinator-onboard-7pz3ah`
(`cb40870`, the commit that vendored the owner's creature-expansion brief and
reference boards). Four commits on top, oldest to newest:

```
8e7660b  Aspect-variant infrastructure + Nightburrow
62c6ab4  Stormtrail (Alpha Trailpup)
e88787e  Riftfrill (Paddlenewt variant)
29d18fa  Ashtusk (Tuskroot variant)
```

Working tree is clean at the time of writing (this handover + the
`ASSET_LEDGER.md` row are the only thing left to commit). All four pushed to
`origin/ralph/T1-CREATURE-ART`.

## What I was asked to do

Track 1 (Aesthetics) lane. Build four **Aspect variants** — Nightburrow
(Alpha Burrowback), Stormtrail (Alpha Trailpup), Riftfrill (Paddlenewt
variant), Ashtusk (Tuskroot variant) — from
`docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` and their
own reference boards at
`docs/art/reference/creature-expansion-2026-08-30/{01,02,07,08}_*.png`.
Recolor + emissive + VFX on the **existing** Burrowback/Trailpup/Paddlenewt/
Tuskroot meshes — no new geometry, no Meshy generation. A concurrent
T3-CREATURES lane owns the data side (species entries, typing, rarity,
habitat/weather/time gating); I was told to start on the material/VFX
technique without waiting for it, and to say if I needed a data field that
does not exist rather than inventing one myself.

## Where I actually got to

### DONE and verified (rendered in-engine, numbers in hand)

All four variants, each with: an HSV recolor pass toward its board's own
4-swatch palette, a synthesised emissive glow map (see "not visible in the
diff" below for why synthesised rather than recoloured), idle VFX, and a
measured gameplay scale.

1. **Nightburrow** (priority 1). Charcoal/obsidian recolor, violet crack glow
   restricted to the back/flank (`up_min`-gated so it stays off the belly),
   purple flame VFX rising well above the back, a matching purple mote ring
   at the paws, shared eye-glow billboard. `body_scale` 1.20 (board: "15-25%
   larger") measured at 2.04m against Burrowback's own 1.7m — exactly
   1.7 × 1.20. Its own board calls the VFX pass/fail ("without emissive/VFX
   treatment, this variant is not successful") and I treated it that way:
   see the "what I nearly shipped wrong" section below for the two real bugs
   that made the VFX invisible on the first two render passes.
2. **Stormtrail** (priority 2). Storm-gray/brown recolor (darkened +
   desaturated off Trailpup's own warm tan), a thin gold lightning-vein tint
   overlay down the spine/flank, static-blue crack glow. VFX: fast
   per-mote sine-hash flicker rather than a smooth rise, so the group reads
   as crackling electricity rather than a candle flame. `body_scale` 1.12
   (board: "10-15% larger") measured at 1.43m against Trailpup's 1.28m.
3. **Riftfrill**. Deeper teal/blue recolor off Paddlenewt's own bright-cyan
   vivid, a lilac tint overlay on the dorsal/up-facing surfaces, violet
   marking glow. VFX: the one variant that **orbits** rather than climbs — a
   slow drifting ring of motes, matching its board's "floating motes" over
   the other three's "rising" language. No claimed size change (this is a
   typing/recolor variant per the brief's own Shiny/Alpha/Aspect-variant
   taxonomy, not an Alpha) — `body_scale` 1.0, measured 1.15m against
   Paddlenewt's own 1.15m.
4. **Ashtusk**. Deepened Tuskroot's own already-dark vivid recolor toward
   basalt/soot, ember-orange crack glow off the belly/legs, **a second glow
   layer specifically for the ivory tusks**, colour-matched rather than
   darkest-pixel (a percentile search can never find a PALE feature). VFX:
   embers rising plus paw smoke, deliberately restrained (board: "should NOT
   be engulfed in flames... a creature that has spent years around volcanic
   heat") — 7 primary motes against Nightburrow's 10, size_scale 0.15
   against 0.2. No claimed size change, `body_scale` 1.0, measured 2.15m
   against Tuskroot's own 2.15m.

**Performance**, measured directly rather than assumed
(`tools/_probe_aspect_vfx_perf.gd`, `RenderingServer.get_rendering_info`,
the structural-counter discipline this repo's own `perf_render_stats.gd`
insists on for llvmpipe): one dressed Nightburrow (swapped materials + full
VFX: 10 primary + 4 paw + 2 eye = 16 billboards) costs **+1 draw call,
+128 primitives** over a plain Burrowback. The whole VFX billboard set is
one `ImmediateMesh` draw call regardless of how many discs it contains (same
technique `alpha_aura.gd` already uses in production), so this number does
not grow per-variant beyond mote count. Four variants on screen
simultaneously — which the brief's own spawn-protection rules say should
never happen — would still be under 10 draw calls and ~500 primitives
total. Not a performance concern at this scale.

**Test suite**: `tests/smoke_art.gd` and the full `test_creature*`/
`test_wild_alphas` groups pass unchanged, both before and after the
`_texture_for()` bugfix below.

### Done but NOT independently verified

- Everything above is my own render judgement, not a blind pass.
  `ralph/conventions.md` requires an independent judge for visual-affecting
  work and this lane was told a JUDGE-2 Fable session is live — I did not
  invoke it myself (that would be grading my own work). Frames are
  committed and ready: `ralph/reports/T1-CREATURE-ART/shots/
  {nightburrow,stormtrail,riftfrill,ashtusk}-{wide,close}.png`.
- Exact hue match to each board's own named swatches is approximate, not
  colour-calibrated. I matched by eye against the rendered frame and the
  board side by side, the same discipline the repo's shiny-colourway work
  already uses, but did not measure e.g. "is this pixel within N degrees of
  #a855f7" the way `shiny_colourways.json`'s own `terrain_share` check
  measures grass-hue contamination. If the judge flags a specific swatch as
  off, `data/creatures/aspect_variants.json`'s `rules`/`glow` blocks are the
  one place to retune it — no code change needed.

### Still open / not attempted

- **Full-world placement.** Every capture here is a small purpose-built
  stage (`tools/_capture_aspect_variants.gd`, modelled directly on
  `tools/_capture_creature_roster.gd`'s own "small stage, not the full
  143,630-prop world" choice) with MOOD lighting approximating each board's
  named habitat (night cave, open storm country, dusk pond, warm stone) —
  not the real Burrow Warrens/pond/Team-Tether-industrial geometry. That is
  an accepted substitution for judging colour/material/VFX/scale, and I say
  so in the tool's own header, but it is **not** the same as the brief's own
  ask to "render it against a dark cave background" using the real Warrens.
  Nightburrow in particular deserves that check once it has a real spawn
  location — a staged near-black backdrop is not proof the real cave scene's
  actual light levels won't crush it further.
- **Stormtrail's "electricity moving over coat/tail"** and **Riftfrill's
  "gentle psychic/rift distortion"** are both described as something
  crawling ON or WARPING the surface. A billboard VFX ring around the body
  cannot deliver either literally — mine gives Stormtrail a flickering spark
  aura near the coat and Riftfrill a floating mote ring, which is a
  reasonable and readable substitute, but is not the same effect as a
  travelling emissive highlight or a screen-space refraction shader. Said
  plainly rather than claimed as done: a genuine "arc crawling over the fur"
  would need an animated UV-offset or vertex-colour-driven shader on the
  creature material itself (a new, more invasive lever than this lane's
  scope), and a real rift distortion needs a `SubViewport`-based screen
  refraction, which is a much bigger technical lift than four creatures'
  worth of recolor work justifies on its own.
- **Ashtusk's tusk glow is real but small** (1.17% of surface, see the "what
  I nearly shipped wrong" section) — visible in the close-up render as warm
  highlights on the tusks, not a dramatic separate glow. Could be pushed
  harder (`intensity` in `aspect_variants.json`) if the judge wants it more
  prominent.
- **The species.json data contract is dormant, on purpose** — see below.
- **No per-species facing-convention audit.** I found empirically that
  camera yaw 0° shows Burrowback's BACK from my stage's own camera position,
  and used that same yaw for all four variants' close-up shot. I did not
  verify this holds for Trailpup/Paddlenewt/Tuskroot independently — their
  close-up frames came out showing what look like reasonable dorsal/head
  views, so it appears to generalise, but I did not measure it the rigorous
  way (reading each species' own `model_yaw` and reasoning from it) the way
  I would if this were gameplay-facing rather than my own capture tool's
  camera framing.

---

## The data contract T3-CREATURES needs (I did not add this myself)

`creature_body.gd::_build_placeholder()` now reads two NEW, currently-unused
placeholder keys:

```jsonc
"placeholder": {
  ...,
  "model": "res://assets/creatures/tetherbound/burrowback/models/creature_burrowback_lod0.glb",
  "aspect_variant": "nightburrow",       // NEW — the colourway/VFX preset id
  "aspect_source_species": "burrowback"  // NEW — whose texture folder the
                                          //   sibling colourway files live in
}
```

When a species entry sets `aspect_variant`, the body wears that variant's
recolor + synthesised glow + VFX **instead of** the ordinary vivid/shiny/
alpha ladder (an Aspect variant is its own identity, not a per-individual
roll on an existing one — see `aspect_variant`'s own doc comment in
`creature_body.gd`). `aspect_source_species` only matters when the variant's
own species id is not the folder its textures live in (true for all four:
Stormtrail's files sit beside Trailpup's, not under a "stormtrail/" folder
that does not exist) — if omitted it defaults to the species' own id, which
is correct for a hypothetical future variant built on its own dedicated
model.

**I did not add these two keys to `data/creatures/species.json`** — that
file is T3-CREATURES' own, and per this lane's brief I was told to say what
I need rather than invent it. The four variants can be proven and rendered
today without any species.json entry at all (my own capture tool calls
`creature_body.set_aspect_variant(variant_id, source_species)` directly,
the same call a species-driven path would make) — once T3-CREATURES lands
`nightburrow`/`stormtrail`/`riftfrill`/`ashtusk` species entries with their
own typing/rarity/habitat data, adding these two placeholder keys is the
entire remaining wire-up on my side. No other code change is needed.

`set_aspect_variant(variant_id, source_species)` is also available as a
direct runtime call (mirrors `set_shiny()`/`set_alpha()`'s own shape) for
anything that wants to apply the dressing without a species-table entry at
all.

---

## What I nearly shipped wrong (worth reading before touching this again)

Two real, silent failures, both caught by rendering and looking rather than
by reasoning about the code — exactly the discipline this project's own
conventions ask for.

1. **The VFX rendered nothing, twice, for reasons that were not obvious from
   the code.** First pass: my mood lighting (`night_cave`) was so dark the
   whole scene — including the 1.80m trainer, the ruler this survey depends
   on — was barely visible, and I could not tell if the VFX was even firing.
   I isolated it (`tools/_probe_aspect_vfx_isolated.gd`, the VFX attached to
   a bare `Node3D` with nothing to occlude it, no creature) and it drew
   fine — a clean rising S-curve of motes plus the eye-glow dots. So the
   billboard technique itself was never the problem. Second finding, after
   fixing the lighting: the motes were still invisible on the real creature.
   Cause: `radius_scale`/`height_bias` kept the ring too close to the
   body's own centreline and too low, so for most of a mote's rise it was
   geometrically INSIDE the creature's own silhouette from the camera's
   point of view and lost the depth test against solid mesh. Fixed by
   pushing `height_bias` above 1.0 (the flame/ember/mote ring now visibly
   climbs PAST the top of the model, not just up to it) and widening
   `radius_scale`. **If a future pass makes any of these creatures bulkier
   or taller, re-render and check — this failure mode has no compiler error
   and no test that would catch it, only a rendered frame.**
2. **A real, pre-existing bug in `creature_body.gd::_texture_for()`'s
   fallback branch** hardcoded `"base_color"` in the constructed filename
   regardless of which texture (albedo or emissive) it was actually asked
   about. For every species using the "extracted" texture convention
   (Trailpup, Mudsnout, Bramblebun, Veridian — anything whose live material
   references a `.jpg` or an embedded glb image rather than a `.png`
   sibling), the EMISSIVE half of a colourway swap could **never** find a
   genuinely different emissive file, only ever the base_color one. This was
   silently harmless before this lane (nothing shipped a colourway-specific
   emissive that differed from its own albedo), which is exactly why nobody
   had found it — but it meant Stormtrail's synthesised glow map (mostly
   black canvas, bright crack lines) was never loading, and the emission
   slot kept re-adding a full copy of the (much brighter) albedo on top,
   which is also why Stormtrail's coat looked barely darkened at first even
   though the generated texture file itself measured a real drop (median
   value 0.60 → 0.35, `tools/generate_aspect_variant_textures.py`'s own
   printed stats). Fixed by threading a `kind` parameter ("base_color" /
   "emissive") through `_texture_for()` so the fallback path asks for the
   right file. Verified backward-compatible: every existing species' fallback
   still resolves to the identical file it did before (none of them have an
   `_extracted_emissive_<suffix>.png` on disk, so the corrected lookup still
   returns null and the caller still falls back to the albedo texture,
   byte-for-byte the pre-fix behaviour) — `tests/smoke_art.gd` passed
   unchanged before and after.

Neither of these would have been caught without rendering the actual
creature and looking at it, which is the whole reason this project's own
conventions insist on it.

## What I considered and deliberately did not do

- **A shared static helper for the billboard-disc primitive**, instead of
  duplicating `alpha_aura.gd`'s own `_disc()` into `aspect_vfx.gd`. Both are
  ~12 lines; `alpha_aura.gd` is proven in production and I did not want to
  risk a refactor of code I do not own the test coverage for, to save one
  short function. Flagged as a live "reuse vs. risk" call, not a silent
  duplication — if a fifth VFX consumer shows up, extracting the shared
  helper stops being a judgement call either way.
- **Retinting Riftfrill/Ashtusk's own established base colourways** (the
  ordinary, non-variant Paddlenewt/Tuskroot). Out of scope — these are
  presentation changes to an EXISTING creature's canon appearance, which is
  a different decision than dressing a new Aspect variant that shares its
  mesh.
- **A texture-based "electricity crawling over the coat" shader** for
  Stormtrail. Named above as a real gap between the board's language and
  what I built; I judged a new animated-material shader system to be outside
  this lane's "recolor + emissive + VFX on existing meshes" scope and a
  billboard spark aura to be the honest, cheaper substitute — flagged rather
  than quietly presented as equivalent.
- **Screen-space rift distortion** for Riftfrill, same reasoning — a real
  shader-level effect, not a billboard, and a bigger technical commitment
  than this pass's four-creature budget.
- **Auto-detecting eye position from the texture/anatomy maps.** I tried
  reasoning about it (UV islands are scattered by the auto-unwrapper and
  carry no spatial locality — confirmed by comparing
  `tools/creature_anatomy_maps.py`'s own false-colour dump against the
  shipped albedo, both saved under this session's scratch directory, not
  committed) and concluded a billboard anchored at the same
  `Vector3(0, height*0.82~0.83, radius*0.85~0.9)` point
  `creature_body._build_capsule()`'s own placeholder snout already uses is
  more reliable than guessing a tight anatomy `where` band — it needs no
  per-species tuning because the BODY's own local +Z is always gameplay
  forward (the same fact `facing()` and `model_yaw` already depend on),
  regardless of which way a given mesh's raw UVs point.

## Camera stands / exact commands, if re-rendering

Godot 4.7-stable was not preinstalled in this container (every prior lane's
handover names the same gap):
```
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot
godot --headless --path . --import   # once, ~6-8 min cold
```

Regenerate the recolor/glow textures (pure Python, no Godot, seconds):
```
pip install pillow numpy   # if not already present
python3 tools/generate_aspect_variant_textures.py [nightburrow|stormtrail|riftfrill|ashtusk ...]
godot --headless --path . --import    # re-import the changed PNGs
```

Render all four stands (small stage, NOT the full world — ran well under a
minute end to end on this box, matching `_capture_creature_roster.gd`'s own
measured cost for a comparable rig+creature scene):
```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_aspect_variants.gd
```
Writes `ralph/reports/T1-CREATURE-ART/shots/<variant>-{wide,close}.png`.
**Never combine `--headless` with `--rendering-driver opengl3`** — hangs
forever, no error. The tool's own final stdout line
(`Aspect variant frames written to ...`) is the completion signal; poll for
it rather than trusting process exit timing.

Performance delta:
```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_probe_aspect_vfx_perf.gd
```

## Full file footprint

**Code (mine to own — creature materials/VFX, creature_body.gd's
per-variant presentation path, my own capture tooling):**
- `scripts/creatures/creature_body.gd` — `aspect_variant`/
  `_aspect_source_species`/`set_aspect_variant()`, the new branch in
  `_refresh_shiny_tint()`, `_apply_aspect_vfx()`, the `_texture_for()`
  `kind` bugfix, `_colourway_species` threaded through the existing swap
  path.
- `scripts/creatures/vfx/aspect_vfx.gd` (new) — the billboard VFX, 4 presets.
- `tools/generate_aspect_variant_textures.py` (new) — offline recolor/glow
  generator, imports `repaint_creature_textures.py`/`creature_overlays.py`/
  `creature_anatomy_maps.py` rather than duplicating them.
- `tools/_capture_aspect_variants.gd` (new) — the 4-stand capture tool.
- `tools/_probe_aspect_source_materials.gd`, `_probe_aspect_vfx_isolated.gd`,
  `_probe_aspect_vfx_perf.gd`, `_probe_stormtrail_swap.gd` (new, dev-only) —
  the investigation tools behind the two bugs above; kept per this repo's
  own convention of keeping investigative probes rather than deleting them.

**Data (mine — presentation only, no typing/rarity/habitat):**
- `data/creatures/aspect_variants.json` (new) — recolor rules, overlays,
  glow specs for all four variants.

**Generated assets (offline tool output, checked in like every other
colourway):**
- `assets/creatures/tetherbound/burrowback/models/
  creature_burrowback_lod0_{base_color,emissive}_nightburrow.png`
- `assets/creatures/tetherbound/trailpup/models/
  trailpup_extracted_{base_color,emissive}_stormtrail.png`
- `assets/creatures/tetherbound/paddlenewt/models/
  creature_paddlenewt_lod0_{base_color,emissive}_riftfrill.png`
- `assets/creatures/tetherbound/tuskroot/models/
  creature_tuskroot_lod0_{base_color,emissive}_ashtusk.png`
- (plus each PNG's `.import` sidecar)

**Evidence:**
- `ralph/reports/T1-CREATURE-ART/shots/*.png` — 8 files, 2 per variant.

**Docs:**
- `docs/ASSET_LEDGER.md` — one new row for the generated textures above.
- This file.

**Nothing else touched.** No changes to `data/creatures/species.json`,
`data/creatures/shiny_colourways.json`, `alpha_aura.gd`, combat, UI, terrain,
or any file this lane's brief names as not mine.

## Disagreeing with the brief, with evidence

Asked to flag this rather than quietly work around it: the four boards'
"Meshy Realism" notes ask for effects that plain colour + a billboard mote
system cannot literally deliver — Stormtrail's electricity "moving over
coat/tail" and Riftfrill's "distortion" both describe something happening
ON or TO the surface itself, not around it. I built the honest closest
substitute for both (a flickering spark aura; an orbiting mote ring) and
said so above rather than presenting either as the described effect
achieved. If the owner's bar for either of these is the literal described
effect rather than a readable substitute, that is a real follow-up scoped
bigger than this lane — an animated-material shader for Stormtrail, a
`SubViewport` screen-refraction pass for Riftfrill — and should be a
deliberate decision, not something a future lane discovers was silently
downgraded.

## What I would do next

1. Get the eight committed frames in front of the live JUDGE-2 Fable
   session — I did not route them myself per "do not grade your own visual
   work".
2. Once T3-CREATURES lands species entries for the four variants, add
   `aspect_variant`/`aspect_source_species` to their `placeholder` blocks —
   that is the entire remaining wire-up, no code change.
3. If the judge or the owner wants Stormtrail's/Riftfrill's literal
   described effects rather than the substitutes I built, scope the
   shader/SubViewport work as its own piece rather than folding it into a
   "just retune the VFX preset" ask — it is not the same size of change.
4. A real-world placement render (actual Burrow Warrens at night for
   Nightburrow especially) once a spawn location exists, rather than my
   staged mood-lit stand.

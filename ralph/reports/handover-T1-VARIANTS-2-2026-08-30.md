# Handover — T1-VARIANTS-2 (Stormtrail/Riftfrill identity + eye-glow fix), 2026-08-30

**Branch:** `ralph/T1-VARIANTS-2`, containing the merged `origin/ralph/T1-GROUND-3`
grass-capture fix (needed for the in-world evidence below). Work commits:
`b17cb3d0` (textures/JSON/VFX + 16 lineup frames), `f35c99ab` (in-world capture
tool), `3f51b308` (ASSET_LEDGER follow-up), `6bacf5bd`/`67873931` (four in-world
frames), `a81f7223` (JUDGE-5 D18/D19 follow-up — see its own section below),
plus this handover commit.

**A blind judge already ran against this branch's evidence mid-round** —
`ralph/reports/JUDGE-5-2026-08-30.md` on `origin/ralph/JUDGE-5`, reading
`ralph/T1-VARIANTS-2` directly without merging. Its verdict and this lane's
response to it are their own section below; read that before the older
JUDGE-4 section if you only have time for one.

## What I was asked to do

JUDGE-4's blind pass (`ralph/reports/JUDGE-4-2026-08-30.md`, Queue 2) re-judged
the four Aspect variants after T1-VARIANTS' round. Its verdict: JUDGE-3's four
named technical defects are fixed, Ashtusk and Nightburrow are distinct, but —

- **Stormtrail "still reads as a recolour"** (Q2-D2). At lineup distance
  variant and base were "not tellable apart": same tan coat (the sheet's
  Stormtrail is "a charcoal storm-grey animal; that value drop alone would
  separate them at any distance"), and the sheet's head-to-tail gold spine
  bolt shipped as "a soft gold patch on the left shoulder" — one-sided, so
  "from the other half of the angles a player fights from, Stormtrail is its
  base species exactly" (Q2-D4).
- **Riftfrill "marginal"** (Q2-D5, as corrected by the judge's own sampling):
  the body recolour is real but is "a **value** move (a darker teal) rather
  than the sheet's **hue** move (River Teal body, *Lilac* frill)"; the lilac
  was "confined to the crown and the frill tips", so at lineup distance the
  pair read "as one axolotl at two brightnesses". The sheet's emissive
  filigree markings were "not present" (Q2-D6).
- **Eye glow absent on all four** (Q2-D3), called "the cheapest, highest-yield
  identity cue in the whole queue": every owner sheet names a glowing eye
  colour, the prior handover claimed the billboard fires, and "the committed
  frames do not show it".
- Also Q2-D12: the prior close-shot framing lost an eye off the frame edge.

Scope unchanged from T1-VARIANTS: materials/textures/emissive/VFX only. No new
meshes, no Meshy spend, no `species.json` (so no scale change — see Known
limits), no spawn/terrain/UI.

## What changed, per file

**`data/creatures/aspect_variants.json`** (regenerating the four checked-in
texture files; only Stormtrail's and Riftfrill's specs were re-tuned):

- **Stormtrail.** The coat rule was pushed from deepening the base tan to a
  real darken+desaturate move toward the sheet's Storm Fur — this is the
  value drop JUDGE-4 said "alone would separate them at any distance". The
  lightning overlay was split into a near-solid `spine_bolt` running the
  spine plus a wide `lightning_branches` layer, so coverage no longer depends
  on clump noise happening to land on both flanks (the direct answer to
  Q2-D4's one-sided patch). A new `lightning_glow` emissive layer makes the
  gold marking glow at night instead of sitting as day-only paint.
- **Riftfrill.** The `lilac_frill` overlay was widened/raised to near-solid
  coverage over the whole frill region — round 1's `up_min` bound only caught
  the crown and tips, which is exactly the confinement Q2-D5 described. A new
  `filigree` emissive layer implements the sheet's glowing swirl markings,
  previously unattempted (Q2-D6).

**`tools/generate_aspect_variant_textures.py`** — `select: match` glow layers
gained an optional `"sample": "albedo"`, letting a layer match against the
recoloured/overlaid albedo instead of only the untouched source. Needed
because Stormtrail's gold lightning paint does not exist pre-recolour, so the
old source-only sampling had nothing gold to find for `lightning_glow`.

**`scripts/creatures/vfx/aspect_vfx.gd`** — the eye-glow root cause. See its
own section below.

**`tools/_capture_t1_variants_lineup.gd`** — close-shot camera pulled back and
seat offset tightened (Q2-D12: both subjects were losing a whole eye off the
frame edge). Evidence now writes to `ralph/reports/T1-VARIANTS-2/shots/`
instead of overwriting the predecessor lane's frames.

**`tools/_capture_t1_variants_inworld.gd`** (new) — in-world evidence tool,
described under Evidence.

**Generated assets regenerated** (same files, same generator, no new asset):
`assets/creatures/tetherbound/trailpup/models/trailpup_extracted_{base_color,emissive}_stormtrail.png`,
`assets/creatures/tetherbound/paddlenewt/models/creature_paddlenewt_lod0_{base_color,emissive}_riftfrill.png`.
Nightburrow's and Ashtusk's textures were not regenerated — JUDGE-4 cleared
both and their specs were not touched.

## The eye-glow bug (Q2-D3): root cause, not retuning

The eye/tusk billboards were drawn on the same depth-tested `ImmediateMesh` as
the aura motes. Their anchor is a body-proportion heuristic
(`Vector3(0, height*0.83, radius*0.85)`) borrowed verbatim from
`creature_body._build_capsule()`'s placeholder snout — written for the
fallback capsule, not for real GLB head geometry. On every one of the four
real models that point sits fractionally **inside** the head's own opaque
surface, so the billboard lost the depth test against the model's own
fur/scales — and a depth-tested billboard that loses that test is not dim, it
is invisible, indistinguishable in a frame from "never fired". That matches
JUDGE-4's evidence exactly: eye colour absent in all four close-ups while the
primary/paw mote groups (anchored well clear of the body) rendered fine on
the same creatures, and the one "working" eye (Ashtusk's) was actually albedo
paint that happened to match its sheet.

Fix (`scripts/creatures/vfx/aspect_vfx.gd`): the eye and tusk discs moved to
their own second `ImmediateMesh` whose material sets `no_depth_test = true`;
the aura/paw motes stay depth-tested so a mote passing behind a limb is still
correctly hidden. `_disc()` now takes an explicit target mesh. The anchor was
then retuned by rendering each of the four species in turn (the old constant
sat between the ears, above the eyeline, on the canine and boar models) —
lower and slightly forward, still one shared constant rather than a
per-species table (see Known limits).

Why this was in scope despite also helping the two cleared variants: it is
shared code, and both of this round's target creatures' owner sheets specify
glowing eyes by name (Stormtrail: vivid cyan; Riftfrill: Violet Glow family).
The sheet cue could not reach the frame on either of them without this fix —
JUDGE-4 itself flagged the eye glow as the single highest-value fix available
and noted the texture layer is, by prior design (the JUDGE-3 eye-bleed fix),
forbidden from lighting the eye, so the billboard is the only path.

## JUDGE-5's blind verdict on this round's evidence, and the follow-up

`ralph/reports/JUDGE-5-2026-08-30.md` read the 16 lineup frames and 4 in-world
frames below directly off this branch (Set 3 of a three-set pass covering two
other lanes' work too). Its bar questions on the creature set: **"distinct
enough to tell apart in a fight; still one silhouette per pair"** — a "large,
real improvement" over `T1-VARIANTS`, and a clear **yes** on "would this sit
beside Palworld as the same kind of game" for the creatures specifically
(it said no for the other two sets it read). That is the actual answer to
this lane's founding question, from a judge that had not read this file or
any other lane document first.

It also named specific defects, two of which land squarely on this lane's
own two target creatures or its own shared-code change, and both were fixed
before this handover was written (commit `a81f7223`):

- **D19 — Nightburrow has four eyes.** "Two pink glow sprites sit on the
  forehead... the animal's actual eyes are below them" and the sprites read
  as "visibly hexagonal rather than round". This is a regression this lane's
  own eye-glow fix introduced: the shared anchor constant (tuned by
  rendering all four species and eyeballing "close enough") happened to land
  well below the eyeline on the two longer-snouted models but well *above*
  it on Burrowback's rounder, squatter head, creating a second glowing pair
  above the real one. Fixed two ways: `MOTE_SEGMENTS` doubled (8 → 16, a
  free change — an unshaded, tiny, textureless triangle fan costs nothing
  extra) so every disc reads as round rather than an octagon at close range;
  and the eye anchor is now an optional per-species override
  (`eye_anchor` in `aspect_vfx.gd`'s `PRESETS`, falling back to
  `DEFAULT_EYE_ANCHOR` when absent) with Nightburrow given its own retuned
  value. This resolves the "config needs a place to live" limitation the
  first draft of this handover listed — the place was already there
  (`PRESETS`), it just needed the one extra key.
- **D18 — Riftfrill is "the weakest of the four... most likely to be read as
  a recolour"**: "same mesh, same pose, same size, and the change is violet
  on the frills and crown over an otherwise identical cyan body." JUDGE-4's
  own pixel sampling had found the round-1 body numerically darker (60-80
  units), which this lane's first pass left untouched on the theory it was
  "already working" — JUDGE-5's fresh, un-primed look says a value move that
  subtle does not register as different at a glance, only under sampling.
  Pushed the body rule further on both axes: hue further from Paddlenewt's
  own 186° (196° → 206°) and value dropped further toward the sheet's own
  deep River Teal swatch (`val_scale` 0.82 → 0.6).

**Not fixed, and not this lane's to fix without wider authorisation:**

- **D17 — every pair shares one mesh, pose and (mostly) size**, differing
  only in surface treatment. JUDGE-5 itself points at Nightburrow's own
  scale bump as evidence this is "cheaper than it looks", but that scale
  bump lives in `data/creatures/species.json`, which this lane's own brief
  and CLAUDE.md forbid touching. Same routing gap JUDGE-4 already named for
  Stormtrail's "scale up modestly" line.
- **D20 — Trailpup itself reads as a stock, undesigned wolf** beside the
  stylised trainer. True of the BASE species, not the variant this lane
  built; fixing it means redesigning Trailpup's own vivid colourway, a
  different lane's asset.
- **D22 — the roster occupies only two size bands** (species-wide scale
  authorship, `species.json` again) and **D23 — the night stands are a
  near-black void with no moon/stars**, a lighting-rig gap in the capture
  tools' own stage/world setup, not a texture or VFX question.

At the time this section was written, the regenerated Riftfrill textures and
the `aspect_vfx.gd` eye-glow fix had not yet been re-rendered and re-eyeballed
— see the Evidence section below for whether that happened before this
handover was finalized.

## Evidence

### Synthetic-stage lineups (committed with `b17cb3d0`)

16 frames in `ralph/reports/T1-VARIANTS-2/shots/` — 4 variants × day/night ×
wide/close, each beside its own base species plus the trainer for scale, same
neutral stage and light rigs as the predecessor lane (all four re-shot because
the eye-glow fix affects all four).

What the frames show, stated as observation, not verdict:

- `stormtrail-vs-trailpup-day-wide.png`: the variant is now a near-black
  animal with gold lightning marking down flank and legs beside the base's
  tan — the coat value drop is plainly visible at lineup distance.
  `-night-close`/`-night-wide`: the gold marking emits at night; two soft
  cyan eye dots are visible. In the day close-up the cyan eye glow is
  present but reads as a soft dot on/near the socket, not a crisp iris, and
  drifting aura motes are visible around the head.
- `riftfrill-vs-paddlenewt-day-wide.png`/`-day-close.png` (after the D18
  body push, `a81f7223`): the whole head and body now read as violet-blue
  beside Paddlenewt's cyan, not just the frills — the close crop in
  particular shows a clear hue difference across the face, not only a
  brightness difference. `-night-close`: the variant reads violet against
  the base's blue with lilac filigree shimmer along the jaw/frill; the
  violet eye gleam is present.
- `nightburrow-vs-burrowback-night-close.png` (after the D19 fix): the two
  violet eye-glow discs now sit at eye height and read as round, not as a
  second higher pair — the "four eyes" JUDGE-5 named is gone in this frame.
- Ashtusk frames: re-shot with the eye-glow fix; texture identity unchanged
  from what JUDGE-4 already cleared, ember eye-glow now guaranteed visible
  rather than working "by luck" via texture rim colour alone.

### In-world frames (real Meadows, this round's addition)

`tools/_capture_t1_variants_inworld.gd` spawns each pair in the real
`scenes/world/meadows_playground.tscn` at encounter range (7.6m), day and
night via `WorldLook.apply_time`, and runs `tools/capture_check.gd` per shot.
This answers the gap JUDGE-4 called real but disclosed: the stage frames
"cannot answer whether the four read as distinct **in the Meadows**, against
grass, at encounter distance, in real light".

All four planned frames were produced and eyeballed
(`ralph/reports/T1-VARIANTS-2/shots/inworld-*.png`):

- `inworld-stormtrail-vs-trailpup-day.png` — real 3D grass blades, shrubs,
  flowers, trees and the dirt path fill the frame; both animals whole, side
  profile at 7.6m. The variant's black coat and gold lightning marking are
  unmistakable beside the base's grey-tan in full daylight against grass. A
  wild creature wandered into frame right (the tool does not fence wildlife;
  it does not obscure either subject).
- `inworld-stormtrail-vs-trailpup-night.png` — the gold marking visibly
  emits at night while the base wolf nearly disappears into the dark grass;
  the strongest separation of the four frames.
- `inworld-riftfrill-vs-paddlenewt-day.png` — the lilac/violet frill and
  face read clearly against the base's uniform cyan at encounter range in
  daylight.
- `inworld-riftfrill-vs-paddlenewt-night.png` — the pair still separates
  (darker violet vs blue) but this is the subtlest of the four frames: the
  filigree glow is faint at this distance and the eye glow is not
  discernible at 7.6m in-world, unlike in the close lineup frames.

`capture_check` flagged one warning per shot — "WorldWeather is still
processing, the weather pin will drift across a multi-shot pass" — a
determinism warning about weather drift between shots, not a grass or
framing failure. Knowing the check once passed a frame shot from below the
terrain (JUDGE-4's §Evidence validity), every frame was also eyeballed
directly; observations above are from looking, not from the check.

The frames include the live game HUD (health/food, minimap, quest toast,
hotbar) because the tool runs the real playground scene rather than a bare
viewport; wild creatures occasionally wander into frame. Neither obscures
the subjects.

**These four in-world frames were captured before the JUDGE-5 D18/D19
follow-up** (the Riftfrill body push and the Nightburrow eye-anchor/
roundness fix, `a81f7223`) — they show the state JUDGE-5 itself reviewed,
not the state after this handover's last commit. The synthetic-stage lineup
frames referenced above this section (day-wide/day-close/night-wide/
night-close for all four variants) **were** re-rendered after that fix and
reflect the current state; see the observations already written under
"Synthetic-stage lineups" above, updated in place. Re-shooting the in-world
frames after the D18/D19 fix was not done in this round — see Known limits.

## Tests run

- `godot --headless --path . --script tests/smoke_art.gd` (under
  `xvfb-run`/`opengl3`, never `--headless` with a real driver) — **art: OK —
  models loaded, sized to their colliders, and the meadow is dressed.**
  Took roughly 39 minutes on this box: this box renders far slower than the
  project's own documented figures for a "fast box" (see the in-world
  capture section above), and this particular test's evolution-only-species
  check in particular is the slow section — not a hang, just genuinely slow
  software rendering, confirmed by letting a run go to completion with a
  50-minute budget after two earlier attempts were cut off mid-test by a
  shorter timeout.
- `godot --headless --path . --script tests/run_tests.gd -- --only=test_creature,test_wild_alphas`
  — **45 tests, 173 assertions, 0 failed.** Matches the predecessor lane's
  own reported baseline exactly (same counts).
- The 16 synthetic-stage lineup frames were re-rendered a final time after
  the D18/D19 fix and eyeballed directly: Nightburrow's eye-glow now sits at
  eye height, round, no longer reading as a second pair above the real eyes;
  Riftfrill's whole head/body is now visibly violet-purple beside
  Paddlenewt's cyan in the close crop, not just the frills. Both match what
  the fix was meant to do.

## Known limits / honest gaps

- **The in-world frames predate the D18/D19 follow-up** (Riftfrill body
  push, Nightburrow eye-anchor fix) — they are still valid evidence for
  "does this read as distinct in the real world" (JUDGE-5's own question)
  but do not show this round's Riftfrill body colour or Nightburrow's
  corrected eye placement specifically. A next pass shooting fresh in-world
  frames after these two fixes would close that gap.
- **The eye-glow anchor is now a per-species override where needed
  (Nightburrow), but the other three still share `DEFAULT_EYE_ANCHOR`**,
  tuned by eye rather than measured per socket. It lands close to the eye on
  all three but is not guaranteed pixel-exact — if a future blind pass finds
  it still off on Stormtrail, Riftfrill or Ashtusk specifically, the fix is
  the same one applied to Nightburrow: add that species' own `eye_anchor`
  entry to its `PRESETS` block, no code change needed.
- **Stormtrail's "scale up modestly" (sheet + JUDGE-4 Q2-D2 fourth bullet)
  remains unimplemented** — it lives in `data/creatures/species.json`, which
  this lane is forbidden to touch. JUDGE-4 already called this "a routing
  gap, not a lane failure"; it still needs an owner-authorised route.
- **The one-sided-marking risk (Q2-D4) is reduced, not eliminated**: the
  spine bolt is near-solid along the top line and `lightning_branches` is
  wide, but branch density still varies per flank by clump noise.
- The `WorldWeather` drift warning above means day/night pairs of in-world
  shots are not guaranteed pixel-comparable weather-wise; adequate for "does
  the identity read", not for calibrated lighting comparisons.
- The in-world tool shoots at fixed world positions chosen for open grass;
  it is not the Burrow Warrens placement check the T1-CREATURE-ART lane
  flagged (Nightburrow in its actual habitat) — still untested, still other
  lanes' terrain territory.
- Per this project's standing rule, **this lane does not grade its own visual
  work**. The observations above describe what the frames contain.
  JUDGE-5 already ran once against this branch mid-round and its verdict is
  recorded above; the D18/D19 fixes made in response to it have not
  themselves been blind-judged.

## Full file footprint

**Code:**
- `scripts/creatures/vfx/aspect_vfx.gd` — second depth-test-disabled mesh for
  eye/tusk billboards; `_material(no_depth_test)`; `_disc(target, ...)`;
  `MOTE_SEGMENTS` 8→16; `eye_anchor` per-species override in `PRESETS`
  (`DEFAULT_EYE_ANCHOR` fallback) with Nightburrow's own retuned value
  (JUDGE-5 D19).

**Data:**
- `data/creatures/aspect_variants.json` — Stormtrail coat/spine-bolt/
  branches/lightning-glow re-spec; Riftfrill lilac-frill widening + filigree
  layer, plus a further body hue/value push (JUDGE-5 D18).

**Tools:**
- `tools/generate_aspect_variant_textures.py` — `"sample": "albedo"` option
  for `select: match`.
- `tools/_capture_t1_variants_lineup.gd` — close framing fix (Q2-D12), new
  output dir.
- `tools/_capture_t1_variants_inworld.gd` — new in-world evidence tool.

**Generated assets (regenerated, no new asset, no Meshy spend):**
- `assets/creatures/tetherbound/trailpup/models/trailpup_extracted_{base_color,emissive}_stormtrail.png`
- `assets/creatures/tetherbound/paddlenewt/models/creature_paddlenewt_lod0_{base_color,emissive}_riftfrill.png`
  (regenerated twice this round — once for the initial frill/filigree work,
  again for the D18 body push)

**Evidence:**
- `ralph/reports/T1-VARIANTS-2/shots/*.png` — 16 lineup frames (re-rendered
  after the D18/D19 fix, current state) + 4 in-world frames (predate the
  D18/D19 fix — see Known limits).

**Docs:**
- `docs/ASSET_LEDGER.md` — second follow-up note under the existing
  T1-CREATURE-ART row (committed `3f51b308`).
- This file.

**Nothing else touched.** No `species.json`, no spawn placement/tables, no
`stronghold.gd`/`landmark.gd`, no terrain/scatter configs (read-only for the
in-world shots), no UI, no `performance.json`, no opening/gate files.

## What I would do next

1. **Re-shoot the in-world frames** against the post-D18/D19 state — the
   committed ones predate that fix (see Known limits).
2. If Stormtrail's or Riftfrill's read is still judged weak on a next blind
   pass, the remaining named defects (D17 shared silhouette, D20 Trailpup's
   own generic design) need `species.json` scale authority or a different
   lane's asset work respectively — not more of this lane's own materials/
   VFX budget.
3. If eye-glow placement is judged still off on Stormtrail, Riftfrill or
   Ashtusk specifically (only Nightburrow got its own override this round),
   add that species' own `eye_anchor` to `PRESETS` the same way.
4. D22 (badger/boar size collision) and D23 (near-black night stands, no
   moon/stars) are both real but outside this lane: `species.json` scale
   authority and a lighting-rig question respectively.

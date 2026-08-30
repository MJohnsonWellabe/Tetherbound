# Handover — T1-GROUND-3, 2026-08-30

Branch `ralph/T1-GROUND-3`, off `origin/main` at `28265a3a`. Pushed. This is
the third ground lane in a row; the two before it are
`handover-T1-GROUND-2026-08-30.md` and `handover-T1-GROUND-2-2026-08-30.md`,
and reading both is the fastest way to understand what is left.

**The brief I was given was one lane stale, and that matters for anyone
reading it.** It listed six items from T1-GROUND's undone list. Three of them
had already been done by T1-GROUND-2, which landed on `main` after
T1-GROUND's handover was written and which the brief does not mention:

| Brief item | Actual state on `main` at `28265a3a` |
| --- | --- |
| 4. Aerial perspective as a terrain-material distance gradient, explicitly not fog | **Already shipped** by T1-GROUND-2 — `shaders/terrain_ground.gdshader` plus five `aerial_fade_*` uniforms in `terrain_playground.json`. Verified present, not redone. |
| 5. Re-verify the pebble slope fix | **Already verified** by T1-GROUND-2 at band 1 (`path-pebbles-crop-AFTER.png`). Band 4 was never checked; I did that. |
| 3a. Wire stream reeds/bank_scrub | **Already shipped** by T1-GROUND-2 — `water.gd::_build_stream_reeds` and `water.json`'s `stream.reeds`/`stream.bank_scrub`. |

So the real remaining work was items 1, 2, 3b and 6, and that is what this
session spent itself on.

---

## Summary

| Item | Outcome |
| --- | --- |
| **0. Capture integrity** (routed mid-session, top priority) | **Root-caused and fixed.** Not "the capture path generally" and not software GL — the grass field was bound to the gameplay camera, so 123 of 128 free-camera tools photographed ground it was not dressing. Fixed at source + a loud pre-shutter check. Verified on the judge's own tool. |
| 1. A genuine second grass species | **Done.** `drygrass` un-suppressed and retuned into a real second species, plus a new per-layer band gradient so it thickens toward the stronghold. Re-baked. |
| 2. Dashed terrain seam lines | **Both standing hypotheses positively RULED OUT with measurements**; one real, measured, lattice-aligned artefact source found and fixed; the residual is characterised but not closed. Honest partial. |
| 3b. Stream visible from its own bank | **Done and measured** — from occluded by 0.363m to clear by 0.218m, against ground *plus grass*, at the capture tool's own stand. Terrain regen + `smoke_traversal.gd`. |
| 3c. River as engineered canal | **Partially done, capped by gameplay — and STILL OPEN.** Rims and half-widths varied within the limit the river's blocker role allows; the AFTER frame still reads as a levee. Do not let the re-bake close this item. |
| 6. Mid-distance smear tier | Not attempted. T1-GROUND could not reproduce it as described and I had no budget left to re-litigate that. |
| **Creatures buried in slopes** (JUDGE-3 §2b, routed) | **Fixed.** `place_on_ground` seated the root on one sampled point; on a slope that buries the uphill half of the body. Now seats over the footprint. |
| **"Scatter reads procedural"** (JUDGE-3 §1f, routed) | **Deliberately NOT changed**, with the argument written out: two of its four ground findings describe a frame missing the whole ground-cover system (§0), and the bush row does not survive a crop at the given coordinates. Re-judge on a fixed capture first. |

**Branch state:** pushed to `origin/ralph/T1-GROUND-3`. One work commit
(`21fd47f0`) plus a forward merge of `origin/main` at `bf815014`, which landed
clean and touched none of this branch's files (`npc_ranks.json` and
`trainer_npc.gd` only) — `test_scatter_perf_budget.gd`'s freshness assertion
was re-run **after** the merge and still passes, so the committed bakes match
the merged config. Working tree clean; CI not yet observed. This lane holds no
GitHub Actions tools, so consolidation is the coordinator's — per
`ralph/conventions.md`, a green `ralph/**` branch sits until somebody
dispatches a sweep, and nothing lands by itself.

**Consolidation warning, and it is the one in `conventions.md`'s own words.**
This branch carries a **terrain regen and a scatter re-bake**. It is exactly
the shape of branch that section names as *not* belonging in a shared
consolidation: any other branch that touches `vegetation.json`,
`terrain_playground.json` or either bake will conflict on generated state, and
resolving that is a re-bake plus a config decision, not a merge. **Land this
one on its own, against a settled `main`, and if anything else has to come
with it, re-bake both terrain and scatter on the merged config rather than
trusting either side's output.** The scatter fingerprint covers the whole of
`vegetation.json`, so even a comment-only edit there invalidates it.

Four new headless probes are committed. They are the reusable part of this
session: each replaces a 12–30 minute boot-and-render round with seconds of
arithmetic, and three of them answered questions that had already cost a lane
a render round each.

| Tool | Answers, in seconds, with no renderer |
| --- | --- |
| `tools/_probe_ground_seams.gd` | Is the sin-dot hash aliasing? Is the far-cover sheet breaching, where, and what fixes it cheapest? |
| `tools/_probe_stream_sightline.gd` | From the capture's own stand, is the water visible over ground *plus grass*? `--sweep` scores cross-sections before a bake. |
| `tools/_probe_layer_count.gd` | How many instances does one scatter layer place, split per band, and how much ceiling is left? |
| `tools/_probe_control_map_dump.gd` | What did the control-map bake actually write? (False-colour image + dropout census.) |

**Evidence:** `ralph/reports/T1-GROUND-3/shots/` — 11 BEFORE/AFTER pairs from
`_capture_ground_and_sky.gd` at the same pinned day state (five bands, pond,
river, stream), plus three diagnostic crops. I have deliberately **not** run a
visual judgement over them; per the brief that is a blind pass's job.

---

## 0. CAPTURE INTEGRITY — root-caused and fixed (routed mid-session)

Routed to this lane after the rest of the work below had landed, as the
highest-priority item: JUDGE-3 section 0 found that committed lane evidence
shows ground with **no grass geometry at all**, and the owner said the same in
his own words — *"some of those renders are just a bad shot not actual game.
the game doesn't have the haze and has real grass."* The judge saw it in two
unrelated tools and concluded it was "in the capture path generally (or
software GL)".

**It is neither the capture path in general nor software GL. It is one
binding, and it is now fixed.**

`playground_world.gd::_stand_up_the_grass_field` binds the field to the
**gameplay** camera, and its own comment already spelled out the failure mode:
*"handed the wrong one it centres its ring somewhere the player is not and the
ground goes bare exactly where they are standing."* A capture tool that builds
its own `Camera3D` and calls `make_current()` does exactly that — the ring
stays parked on the gameplay camera and the tool photographs ground the field
is not dressing. The baked scatter is placed in world space and does not care,
so the frame comes back as bushes, reeds and fern cards on a bare splat. That
is the artefact, precisely.

**Measured blast radius: 128 scripts in `tools/` construct their own
`Camera3D`; five of them rebind the grass field.** So 123 capture tools could
silently produce grass-free evidence. The ones that are fine are fine by
accident — `_capture_ground_and_sky.gd`'s frames (including this lane's own
before/afters) have grass only because it stands the **player** at every shot,
which drags the gameplay camera along with it.

**One correction to the brief, and it matters for how much of the backlog is
suspect:** the coordinator's order said "your own before/afters are suspect
until then." They are not, and I checked rather than assumed — every frame in
`ralph/reports/T1-GROUND-3/shots/` is dense with blade grass, for the reason
above. The frames that are unusable are the ones from tools that pose a free
camera without moving the player.

### The fix, in two parts

1. **`grass_field.gd::_follow_camera`** — the field now follows whichever
   camera is actually rendering, and pushes one loud warning the first time
   that is not the one `bind()` was given. Fixing 123 tools by hand would not
   hold (tool 129 reintroduces it), and following the rendering eye is simply
   more correct: this node's whole job is to dress the ground being drawn. It
   costs one viewport lookup per frame. `bind()` stays the authority; this only
   redirects the follow, and a genuine mis-binding in *gameplay* is still loud.

2. **`tools/capture_check.gd`** (new) — the loud failure the order asked for.
   `require(self, camera)` refuses to write a frame, and
   `warn_only(self, camera)` reports without aborting. It checks that the posed
   camera is the current one; that the grass field exists when config says it
   should, is following this camera, and holds instances; that Terrain3D is
   streaming around this camera; and that the weather is the pinned one the
   shot asked for and is actually frozen. It deliberately judges nothing about
   how the frame *looks* — that stays a blind pass's job.

**Placement matters and cost me a round:** the check belongs at the **shutter**,
not next to `make_current()`. The redirect happens in the field's own
`_process`, so a check in the same frame as `make_current()` fires before the
world has ticked — a false alarm on exactly the frame the fix is working. It is
now the last thing before `get_image()` in `_probe_creek_hollow_habitat.gd`,
and that placement is documented in both files.

### Verified end to end on the judge's own tool

`tools/_probe_creek_hollow_habitat.gd` is the tool the judge used for its own
fresh Creek Hollow captures, so it is the right thing to prove this on.

- **Before:** `shots/capture-integrity/creekhollow-open_basin-BEFORE-no-grass.png`
  (the judge's committed frame) — bare splat, ferns and bushes standing on
  nothing.
- **After:** `…-AFTER-grass-restored.png`, same tool, same stand — full blade
  carpet, cover tiers, and the new straw tussocks visible in it.
- The check itself was proven to **fail** correctly first (it caught
  `"the GrassField is following 'Camera3D', not the capture camera"` and
  aborted), then to pass once the redirect had ticked:
  `[capture_check] ok -- grass field bound to this camera and drawing`.

### On the milky haze — a correction, and an open question

The haze is **not** the aerial-perspective shader T1-GROUND-2 landed, and I
want that on the record before someone reverts a good feature chasing this.
The judge's own fresh captures run on the same `main`, with that shader on,
and came back with *"real cloud detail, real value range, no milky horizon."*
Same build, same day, different tool. So the haze tracks the **tool**, not the
build — and the tools without it are the ones that pin *and freeze* weather,
which is the failure `_capture_ground_and_sky.gd`'s own header states in
capitals and which `capture_water.gd` is already on record for shipping.

`capture_check.gd`'s weather check covers that shape. I have **not** proven it
is the cause in the specific T1-CAST band24 frames — that needs whoever owns
that tool to run the check against it, which is now a one-line change.

### What the next lane should do with this

The source fix is global, so **no tool needs changing to get grass back**. But
the check only protects tools that call it, and one tool calls it today. Adding
`CAPTURE_CHECK.require(self, camera)` at the shutter of the capture tools whose
frames get committed as evidence is cheap and is the thing that stops this
recurring. **Every frame committed as evidence before 2026-08-30 that came from
a free-camera tool should be treated as unreliable about ground cover** —
including the T1-CAST band24 set and the day/night set the judge named.

### The other two items routed with it

**Creatures flattened into sloped ground (JUDGE-3 §2b) — FIXED.** The judge
found creatures "sunk into the slope from the hindquarters back, cut off by
the ground plane", 100m from any water, and correctly said this is ground
placement rather than the water-spawn path. It is one line of seating:
`creature_body.gd::place_on_ground` sampled the ground at **one point** and put
the root there. A creature stands level, so on a slope the uphill half of a
body `_radius` wide sits below ground by about `radius × tan(slope)` — 0.4 m of
radius on a 25° hillside buries 19 cm, which on a small creature is the
hindquarters.

This is the same defect T1-GROUND measured and fixed for `path_stones` one
system over: a rigid shape sampled at its centre and laid on a slope. New
`_seat_over_footprint` seats on the **highest** ground under the footprint
(four axis samples) instead of the centre. The asymmetry is deliberate: a small
gap under one flank reads as a standing animal, a body sliced off by the ground
plane reads as a bug — and a creature that activates closes the gap on its
first `move_and_slide`, while nothing ever un-buries it, which is why the
frames show it. Falls back to the old behaviour whenever the world cannot
answer.

**Blast radius to watch:** this is `scripts/creatures/creature_body.gd`, not a
ground file, and `place_on_ground` is also used by combat arrangement and
respawn. It can only ever raise a body, never lower it. `smoke_wild_streaming`
and `smoke_creature_control` were run.

I did **not** touch the judge's other §2b observation — a creature "lying
completely flat with zero volume". That is a different and larger symptom than
slope seating explains, and I would rather leave it open than claim the seat
fix covers it. Contact shadows were routed to the light lane and are untouched.

**"Scatter reads procedural — seven identical bushes in a row" (JUDGE-3 §1f) —
NOT changed, deliberately, and here is the argument.** Two of its four ground
findings are artefacts of §0's grass bug rather than of the scatter:

- *"five trees … with no undergrowth at their bases at all — they plant
  straight into bare ground"* and *"about 60% of the frame is empty ground with
  nothing in it"* are **descriptions of a frame with the entire ground-cover
  system missing.** The undergrowth at a tree base in this build is grass field
  tufts, cover-tier bushes and now straw tussocks — none of which were
  rendering in those frames.
- The bush row itself: I cropped `band4-4038-meadowhart-15deg.png` at the
  coordinates given. The bushes follow a ridge crest and are neither evenly
  spaced nor collinear on inspection — near a horizon at a grazing angle, any
  scattered distribution compresses into an apparent line. And they are seven
  dark blobs on bare ground *because the ground cover between them is missing*.

The `bushes` layer is already clustered (44 clumps × 15 at a 13 m radius) and
already trail-sited (`density_scale` 6.0, `trail_bias` 0.85). Retuning that
against evidence which is compromised in exactly the dimension being judged is
how this repo has previously spent whole rounds. **Re-judge this on a frame
captured after the §0 fix before touching the numbers** — that costs one render
and settles it either way.

The one §1f finding I could not resolve and am passing on intact: *"the terrain
grass splat is painted across the vertical faces of the rock cluster"*.
Terrain3D calls this `enable_projection` (not "triplanar"); it is **on** in
`shaders/terrain_ground.gdshader` with `projection_threshold 0.8`, so a
vertical face should be projected. That means either the cluster is a scattered
rock *prop* rather than terrain (in which case the splat is not on it at all
and the finding is about the prop's own material), or the threshold is not
doing what its name suggests. Needs the specific frame and a stand at that
rock; I did not have one.

---

## 1. A genuine second grass species — DONE

Both previous lanes called this "the single biggest lever" and neither
attempted it, both correctly judging it too big to squeeze into a session
carrying other work.

**The constraint that decides the whole shape of the fix.** The near-field
carpet is `grass_field`'s tuft ring, and its tuft is *generated in code*
(`grass_field.gd::_tuft_mesh`, six tapered strips at different yaws). No
tint, density or height number on that mesh can be a second *plant* — it is
one silhouette by construction. So a second species has to come from a mesh;
`CLAUDE.md` forbids new Meadows art; therefore it has to come from the
installed nature pack. And the installed pack already had one, switched off:

`grass_field.json`'s `suppress_scatter_layers` carried `drygrass` —
Grass_Wispy_Short/Tall (a splayed fan) and Grass_Wheat (upright stalks with
seed heads) under a straw retint. It was suppressed on the same reasoning
`groundmat` was, and it was wrong for the same reason T1-GROUND found for
`groundmat`: the field's `cover_tiers` are bushes/flowers/litter, and none of
those is a grass. The field genuinely replaces `grass` (Grass_Common/
Grass_Wide, upright blades — the same silhouette as its own tuft), and it
genuinely replaces `flowers` (it has a flower tier). It never replaced the
wispy/wheat family at all.

**Un-suppressing alone is not the fix, and that distinction is the work.**
Dropped in as-authored, `drygrass` is invisible: its `scale_min/max` of
0.20–0.44 was tuned to sit *below* the `grass` scatter layer that the field
has since replaced, which put the wispy meshes at 0.21–0.73m against a field
carpet of 0.40–0.62m. A plant you cannot see over the first one is a texture,
not a species. Three changes, all in `vegetation.json`:

- **Height** — 0.20–0.44 → 0.30–0.62. Measured against the meshes' own glTF
  accessors (Wispy_Short 1.07m, Wispy_Tall 1.67m, Wheat 1.78m at
  `model_scale` 0.72): the mean wispy tuft lands near 0.7m and the tallest
  near 1.04m against a 1.80m trainer. Knee-to-thigh tussocks breaking the
  carpet's top line. Still under the bushes tier's 0.85m, so the understorey
  ladder's order is unchanged.
- **Clustering** — a species reads as a species by standing in stands, so the
  same instance count is repacked into more, tighter clumps: 52×130 = 6760
  becomes 74×92 = 6808 (+0.7%, inside the noise) at a clump radius of 4.6m
  instead of 7.5m. That is EV3's own tighter-packing lever applied a second
  time. `strays` 140 → 90: a lone straw tuft in open green is the confetti
  read the blind pass named; a stand of them is a different grass.
- **Colour** — untouched. The straw retint was already a distinct family.

**Plus the half nobody could reach from config at all: regional
differentiation.** The blind pass's subject 8 says "bands 1, 3, 4 and 5 share
the same grass carpet… they differ by what is parked on them. Increasingly
demanding regions is not yet something the terrain itself says." That was not
a tuning failure — it was *unreachable*. `corridor_bands.density_scale` is one
scalar applied to all eleven layers at once, so a band could be sparser or
denser but never made of different plants.

New optional `layer.band_scale` in `scatter_rules.gd`, keyed by band id,
multiplied on top of the existing band table
(`_layer_band_scale_at`). `drygrass` carries the chapter's own story as a
gradient: 0.45 in the lower meadows the player leaves home into, 0.7 in the
grove, 0.9 at the wet river lock, 1.35 and 1.6 climbing toward the drain
stations and the stronghold. The same walk that gets harder gets visibly
drier underfoot, with no new asset and no band content touched.

It applies to the **verge** as well as corridor fill, and the verge is the
half that matters — corridor fill spreads over 16.8 km² the camera never sees,
while every verge draw lands within metres of an authored route. Normalised by
the layer's own largest weight rather than applied raw, or every weight ≥ 1.0
would clip to "keep everything" and collapse exactly the distinction the key
exists for. Not clamped to 1.0, unlike `density_scale` — the two tables answer
different questions. One is what the chapter can *afford* (budget, hence
clamped); the other is where a species *belongs* (look, no budget content).

### Two things I got wrong first, both caught by measurement

Recording these because both are invisible until measured, and both would
have shipped as "done" on the strength of a correct-looking diff.

**(a) The first cut moved nothing, and I only knew because I measured the
frames.** Un-suppressed and retuned as above, `drygrass` produced *no visible
change*: straw's share of lit ground pixels across the five band frames moved
+0.21, +11.41, −0.01, +0.12, +0.88 points, and the one large number is band
2's canopy shifting, not tussocks. `tools/_probe_layer_count.gd` (new) says
why in 20 seconds: **53,726 instances over a 16.8 km² corridor is 0.004 per
m²**, so a player-height frame holds single digits of them — against the grass
field's 300,000-tuft carpet inside the same 72 m ring. A species you meet
eight times in a frame is confetti, which is the defect this pass exists to
answer.

Retuned against that number rather than by eye: `corridor_fill.density_scale`
1.0 → 2.0, `trail_bias` 0.55 → 0.75 (the old value deliberately kept dry grass
*off* the trail so it would not stack under the green scatter carpet — a
carpet that is now suppressed, so there is nothing left to stack under), and
`verge.count` 4500 → 34000. That is **53,726 → 130,547** placements, and the
per-100 m density along the corridor now climbs 1326 / 1248 / 1369 / 2066 /
2222 across the five bands. Chapter total 750,071 → **826,892**, which is
73,108 under `test_scatter_perf_budget.gd`'s 900,000 ceiling.

*Free headroom, noticed on the way past and not spent:* `grass` still carries
`verge.count: 30000` and renders **none** of it, because that layer is
suppressed. 30,000 baked placements the player never sees.

**(b) The band table is half of a product, and my first table read as a ramp
while landing as something else.** The bake applies `corridor_bands.
density_scale × band_scale`, and the affordability table is itself uneven
(0.18 / 0.13 / 0.12 / 0.13 / **0.07**) — band 5 is deliberately the thinnest
in the chapter because its drain stations strip vegetation at run time. So a
tidy 0.45 → 1.6 ramp landed as an effective 0.081 / 0.091 / 0.108 / 0.176 /
**0.112**: band 4 drier than band 5, which is not the story. Band 5's weight
is now 2.9 and the products climb the whole way — 0.081 / 0.091 / 0.108 /
0.176 / 0.203. The large number is compensating a floor set for a different
purpose, not asking for three times band 4's dry grass.

Tests: five new assertions in `tests/test_veg_corridor.gd`. One runs against
the *real* config so a typo'd or dropped band id — which falls back to 1.0 and
silently flattens the gradient — fails a test; another asserts the **product**
rises monotonically along z, which is the assertion that would have caught (b)
and which pinning `band_scale` alone would not.

### What the final frames measure

Straw's share of lit ground pixels, near/mid band, trainer column excluded:

| band | BEFORE | first cut | FINAL | net |
| --- | --- | --- | --- | --- |
| 1 lower meadows | 65.76 | 65.97 | 65.92 | +0.16 |
| 2 stone and root | 39.87 | 51.28 | 52.87 | +13.00 |
| 3 river lock | 51.94 | 51.93 | 51.57 | −0.37 |
| 4 upper meadows | 44.87 | 44.99 | 51.18 | **+6.31** |
| 5 stronghold approach | 33.63 | 34.50 | 35.21 | +1.58 |

Read this carefully rather than as a scoreboard. Band 4 is the honest signal
— it is where the retune was aimed and it moved 50× more than the first cut
did. Band 1 and band 3 barely moving is the gradient working as designed, not
a failure. **Band 2's +13 is not tussocks** — that band's canopy and treeline
also moved, for the reason in the RNG note below, and I would not cite it as
evidence of anything.

Two things I checked because they are hard project rules, not because they
looked wrong:

- **Oxblood is still reserved.** The rendered tussocks measure hue 47.8 —
  amber straw. Team Tether's oxblood is hue 351.6. 0.2–7% of warm pixels dip
  below hue 20 and none reach red.
- **They are not stickers.** Rendered saturation/value is 0.75 / 0.53 against
  the green blades they stand in at 0.73 / 0.47, in the same frame. That is
  the failure mode this file's own VIS-WORLD history records (tufts "2–3 stops
  brighter and greener than the terrain they sit on"), and it is not
  happening here.

**I have not judged whether this reads well.** That is the blind pass's job
and the frames are in `ralph/reports/T1-GROUND-3/shots/`.

---

## 2. Dashed seam lines — two hypotheses killed, one real source fixed, residual characterised

This is the item two lanes left open with "two hypotheses, neither tested,
next step is a debug-overlay render". I did not build that render. Every
question on the table was arithmetic over config and the analytic
heightfield, so `tools/_probe_ground_seams.gd` answers them headlessly in
about a minute instead of 10–30 minutes per round.

**H1, the `sin()` pseudo-hash — RULED OUT, measured.** `build_playground_
terrain.gd` dithers five threshold decisions with the classic GLSL sin-dot
hash, which is known to alias into periodic banding in float32. Over the exact
integer domain the bake feeds it (region-local pixel indices, 0..255):

```
distribution: mean 0.5003 (ideal 0.5000)  sd 0.2889 (ideal 0.2887)
worst autocorrelation over lags 1..39, both axes: r = -0.0129 at lag 37
```

White to the noise floor. An aliasing hash shows up as autocorrelation at some
lag — that is what a periodic ripple *is* — and there isn't any. This hash is
not drawing the dashes. (GDScript evaluates `sin` in float64, which is
probably why the well-known float32 failure does not appear here.)

**H4, control-map dropouts — RULED OUT, dumped and looked at.** The control
map is the only part of the terrain data written per world position rather
than imported as a whole Image, so it is the one place a per-texel indexing
slip could leave a lattice of unwritten texels. `tools/_probe_control_map_
dump.gd` (new; sibling to the existing `_probe_control_map.gd`, which
histograms the same data and cannot tell a boundary from a dropout) writes the
baked region out as false colour. It is clean: organic patches, a coherent
path, a coherent rise, no lattice, no rows. 1.29% of texels differ from all
four neighbours and they cluster on boundaries, which is the raggedness dither
doing its job.

**H2, far-cover sheet poke-through — CONFIRMED as a real artefact source, and
FIXED.** `grass_field.json`'s `far_cover` is one terrain-following sheet on a
fixed, world-axis-aligned 6m grid whose vertices the vertex shader lifts to
the sampled terrain height plus `lift` (0.35m). Between vertices the sheet is
a chord and the ground bulges over it. Measured at the five capture
viewpoints:

```
band1-opening        533 of  5034 cells breached (10.6%), worst excess 5.78m
band2-stone-root      51 of  5007 cells breached ( 1.0%)
band3-crossing        85 of  5021 cells breached ( 1.7%)
band4-ironwood        39 of  5014 cells breached ( 0.8%)
band5-approach       115 of  5026 cells breached ( 2.3%)
ALL SITES:           823 of 25102 cells breached ( 3.3%)
```

Band 1 — 10.6%, an order of magnitude above the others — is the exact frame
the artefact was reported in. Holes in a wash on a fixed world lattice line up
into rows at a grazing angle, which is the artefact's description.

**This is not covered by the ruling-out already on record.**
`GRASS_HANDOVER_2026-08-26` hid "the field's own MultiMeshes" and saw the
lines survive, and both later lanes repeated that as the reason the grass
field is ruled out. The far cover is **not** a MultiMesh —
`_build_far_cover` adds a single `MeshInstance3D` — so that check could not
have hidden it.

The fix is `dilate_lift`, a new uniform in `far_cover.gdshader`: raise each
vertex above its own half-cell *neighbourhood* maximum rather than above its
own sample — a morphological dilation at exactly the radius the chord spans.
Both obvious knobs were swept first and both are bad trades:

```
fix sweep -- % of cells still breaching, all five sites
  cell   lift=0.35  0.60  0.90  1.20   tris vs 6.0m
   6.0m    3.28%   2.09%   1.84%   1.57%    1.00x
   4.0m    1.96%   1.64%   1.26%   0.95%    2.25x
   3.0m    1.71%   1.28%   0.95%   0.66%    4.00x

H3 (the fix): cell 6.0m, lift 0.35m, dilation over half a cell
  dilate_cap 0.00m -> 3.28%   (today)
  dilate_cap 1.50m -> 1.19%
```

A smaller cell buys it with triangles on the tier whose GPU cost no container
in this project can measure; a bigger lift buys it by floating the wash off
the ground *everywhere*, including the 52–84m hand-over where the sheet is
nearest the eye. The dilation costs eight texture fetches per **vertex**
(never per fragment) on a vertex already doing seven, no triangles, and
nothing on flat ground — where the neighbourhood max *is* the vertex's own
height, so the wash still sits at `lift` exactly where a parallax offset
would show. `dilate_lift` is the cap on what the dilation may add so a cliff
cannot carry a whole cell with it; `0.0` restores the previous behaviour
exactly.

**What I could NOT close, stated plainly.** I do not claim the far-cover
breach is the whole of the reported artefact, and there is direct evidence it
is not. Measuring the band-1 evidence frame:

- The dashes are **~1 pixel wide** dark hairlines (a single-pixel luminance
  drop of ~30 against ~138 neighbours), not the several-pixel patches a 6m
  cell breach would subtend at that range.
- They cross the **sand path** as well as the grass, and *both* grass-field
  sheets carry `"path"` in their `forbidden_ground`, so neither draws a
  fragment there.
- They appear well inside 40m, where the far-cover mesh has a hole cut in it
  (`inner = fade_in_start - cell*2`).
- They form at least two families at different screen angles — a grid seen in
  perspective — and they are crisp while the ground under them is mip-blurred.

A 1-pixel dark hairline on a camera-relative grid, present at all distances,
crossing every material, is most consistent with **Terrain3D's own geometry
clipmap seams** — cracks between LOD rings — which is an addon-level artefact
rather than anything reachable from this repo's config. I did not confirm
that, and I want to be explicit that it is a characterisation, not a
diagnosis. What is now settled is that it is *not* the sin-hash, *not* the
control map, and only partly the far cover.

**Next step for whoever takes this**, and it is much cheaper than the
debug-overlay render two lanes have now proposed: render one frame with
Terrain3D's `mesh_lods`/`mesh_size` changed. If the line spacing moves, it is
the clipmap and the fix is an addon setting or an upstream issue; if it does
not, the clipmap is out too and the remaining candidate is the terrain
material's own mip/filter behaviour at grazing angles.

---

## 3. The stream, and the river

### 3b. Stream visible from its own bank — DONE, and measured rather than rendered

T1-GROUND root-caused this correctly (the hillside's own grade swallows a 0.7m
carve) and T1-GROUND-2 wired the missing reeds and re-rendered honestly to
find it still invisible — exactly as T1-GROUND predicted, because dressing was
never the binding half. Two render rounds to learn something that is pure
geometry.

`tools/_probe_stream_sightline.gd` (new) rebuilds the capture tool's own
camera stand — the middle authored point, the perpendicular to local flow, the
bank at `width/2 + shoulder + 6.0`, the camera `WATER_BACK` behind it — and
traces the eye-to-water sightline against the analytic heightfield. No bake,
no renderer, seconds per configuration.

**The measurement that made this tractable: the occluder is ground *plus
grass*.** `grass_field`'s blades stand 0.40–0.62m and the field only clears the
water by `stream_factor`'s own half-width, so a sightline clearing the *dirt*
by 20cm at 5m off is looking straight into half a metre of grass. A
ground-only check calls that a pass; the frame does not. On the shipped
cross-section the water sat **0.363m below** that occluder — the reported
defect, as a number, from config alone.

**Width is the lever, and the sweep says so rather than intuition:**

```
  depth  carve  water shoulder  over-gnd over-grass  (at offset)
   0.70    5.0    2.4      1.2     0.147   -0.363   2.43m off   <- shipped
   1.10   12.0    3.4      1.2     0.264   -0.246   5.00m off
   1.40   16.0    3.4      1.2     0.463   -0.047   5.68m off
   1.40   20.0    3.4      1.2     0.620   +0.218   5.13m off   <- landed
   1.70   20.0    6.5      1.2     0.459   -0.051   6.48m off
   1.40   20.0    5.0      2.6     0.423   -0.087   6.44m off
```

Deepening alone makes it worse (1.7m is worse than 1.4m at the same width) —
it hides the water further under a rim that already occludes it. Widening
moves the rim back and flattens the ground the sightline grazes. `carve_width`
is the full width, so 5.0 → 20.0 takes the channel from a 2.5m-half slot to a
10.0m-half vale. Landed at `carve_depth` 1.4, `carve_width` 20.0, water width
3.4, `surface_depth` 0.62 — the only configuration in the sweep that clears
ground-plus-grass at all, a 0.58m swing.

`shoulder` is deliberately *not* part of the fix even though it is what moves
the grass line: the capture tool stands at `width/2 + shoulder + 6.0`, so
widening the shoulder pushes the camera further down the same hillside that
caused this, and the sweep shows it going backwards every time.

**Confirmed in the frame, and this one is unambiguous.**
`water-03-stream-eye-BEFORE.png` is meadow grass edge to edge with no water
anywhere in it — the defect exactly as reported, still present on current
`main` after two lanes. `water-03-stream-eye-AFTER.png` shows a water ribbon
crossing the mid-ground with a sand-and-pebble bank and T1-GROUND-2's reed
clumps standing on the far side of it, with the trainer on the near bank
looking at it. This item is closed.

Traversal-safe by construction: 1.4m over a 10.0m half-width is an 8-degree
mean bank, ~12 degrees at the smoothstep's steepest, nowhere near the
45-degree floor limit. Widening a carve can only make ground more walkable.
`smoke_traversal.gd` was still run as the gate.

### 3c. The river as an engineered canal — PARTIALLY done, and capped by gameplay

T1-GROUND measured this correctly: 59–77° banks at every one of 19 authored
points, `half_width` flat at 12–13 on every open reach. It declined to touch
it. The brief asked me to "add river.course rim variation".

**I did, but much less than the complaint asks for, and the reason needs to be
on the record rather than rediscovered.** The river's bank angle is
load-bearing gameplay, not decoration. `terrain_playground.json`'s own river
comment states the contract: it "severs EVERY bearing it crosses", both ends
run past the world perimeter ring, and "the only ground link between the near
Meadows and the far bank is the Old Mill Crossing". It severs a bearing *by
being too steep to walk* — exactly what `_spoke_carve`'s own comment spells
out, that the wall angle "has to stay well past the player's own 45-degree
`floor_max_angle`, or the road is not severed at all, it just dips".

Gentling these banks toward a natural 30–40° would open a ford wherever it was
applied and delete Band 3's gate. That is a major gameplay decision and
`CLAUDE.md` reserves those for the owner. **I did not make it.**

Within that constraint: every rim moved, none to a bank shallower than 60°
(a 15° margin over the walk limit, which the ±2.2m `detail` noise riding on
top needs), and `half_width` now varies 10.0–15.5 where it was 10.0–13.0.
Open-reach bank angles run 60.1–72.1° against 59.0–69.0°, in irregular runs
rather than the smooth symmetric taper that was there. Indices 6–10 are
untouched: that is the Old Mill Crossing narrows, where the pinch is authored
content.

**Honest limit.** This does not fully answer the canal read and should not be
recorded as if it did. Two of the judge's three named causes are not the
angle: the bank *texture* scale (T1-GROUND already took `rock.uv_scale`
0.1538 → 0.22) and "a hard turf line where the meadow resumes", which is the
rim's top edge terminating on a clean smoothstep running parallel to the
water. The remaining lever for that line is per-metre noise on the rim inside
`_river_carve` so the edge wanders — code rather than data, and not attempted
here. **If a later pass still reads this as a levee, that noise is the next
instrument, not a shallower bank.**

**And it does still read as a levee, in my own AFTER frame.**
`water-02-river-eye-AFTER.png` shows the far bank as a uniform grey wall with
a hard turf line along its top edge, essentially as before. That is the
predicted result of a change the gameplay constraint capped at 60°, not a
surprise — but it means **this item should stay open on the routing docs**,
with the rim-noise fix as its next step and the bank angle explicitly off the
table. I am flagging it rather than letting a re-baked terrain read as
"river: done".

`smoke_pond_water.gd` shows the side effect worth knowing: river bank reeds
went 159 → 130 and scrub 57 → 60 as the banks moved. Healthy, but if a later
pass widens rims further, watch that count — `max_bank_slope_deg: 78` is what
sites them.

---

## Two things about this repo's bake and capture that cost me time

Neither is a defect I introduced and neither is in any handover I read, but
both will mislead the next lane exactly the way they misled me.

### A terrain edit reshuffles the WHOLE chapter's scatter, in every layer

I expected the scatter diff to be local, because `all_placements` gives every
layer its own RNG (`base_seed + index * 7919`) and my only layer-level change
was to `drygrass`. It is not local: **all 256 region files changed, and the
`trees` layer's band-4 density rose 32%** (8,971 → 11,843 instances, 400 →
529 per 100 m) without a single tree-related edit.

The mechanism, confirmed by reading rather than guessed:
`scatter_rules.gd::_consider` returns early on the height, slope and bounds
rejections **before** consuming any rng, and only draws from it further down
once a candidate survives. So a candidate that flips from accepted to rejected
consumes a different number of rng values, and every later draw in that
layer's stream shifts. The stream and river carves flip a handful of
early decisions in band 1 and band 3 — and everything after that, in every
layer, lands somewhere else.

This is inherent to the design and is fine for a seeded re-bake (the
composition is statistically identical and every test passes), but it means:

- **"Only my layer moved" is never a safe assumption after a terrain edit.**
- A lane comparing before/after frames after a terrain regen is looking at a
  reshuffled world, not at its own change. Band 4's extra trees are an
  accident of this, not a decision — arguably a welcome one, since GATE-D4 and
  the blind pass both name thin ironwood canopy, but nobody chose it.

### `_capture_ground_and_sky.gd` is not deterministic run to run

Two captures of the **same commit, same viewpoint, same pinned day state**
differ by 403,564 pixels of 1,024,000 (band 4). The near ground is stable; the
sky's clouds and the distant tier are not. So a small distant difference
between two frames is not evidence of anything, and this is worth knowing
before anyone concludes — as I nearly did — that a change moved the trees.
The way to tell is what I ended up doing: re-render the *baseline* twice and
compare that against the change.

## Disagreements and corrections

- **The brief's items 4, 5 and 3a were already done** by a lane it does not
  mention (see the table at the top). I verified each against current `main`
  rather than redoing it, per `CLAUDE.md`'s "evidence-backed already fixed is
  valid". If the coordinator's routing docs still list them as open, they are
  wrong.
- **"Add river.course rim variation" as written is not safely implementable.**
  The rim is what makes the river a blocker. I did the part that is safe and
  said what the rest would cost; treating the remainder as a tuning task will
  silently delete Band 3's gate.
- **The far-cover sheet was never actually ruled out** by the 2026-08-26
  MultiMesh check that three documents cite as having ruled out the grass
  field. It is not a MultiMesh.
- **I overwrote `tools/_probe_control_map.gd` early in the session** and
  restored it from `HEAD`; my version ships alongside it as
  `_probe_control_map_dump.gd`. No content was lost, but it is worth naming
  because `tools/` has 345 scripts and a plausible-sounding name is easy to
  collide with.

---

## Tests

All run on this branch, after the terrain regen and the final scatter re-bake.

| Suite | Result |
| --- | --- |
| `test_scatter_perf_budget.gd` | 3 tests, 6 assertions, 0 failed — bake fresh, load budget, batch count |
| `test_scatter_rules.gd` | 27 tests, 957,763 assertions, 0 failed |
| `test_veg_corridor.gd` | 9 tests, 1,386,524 assertions, 0 failed (incl. the new `band_scale` trio) |
| `test_grass_field.gd` | 10 tests, 63 assertions, 0 failed (incl. flag/suppression agreement, far-sheet grid) |
| `smoke_pond_water.gd` | pass — pond 152 reeds unchanged, stream 77 reeds / 12 scrub, river 130 / 60 |
| `smoke_traversal.gd` | **pass** — and it asserts in its own words that "the river cannot be walked across between its crossings", which is the gate the rim variation had to survive |

`test_veg_corridor.gd` and `test_grass_field.gd` were re-run after the density
retune; the perf-budget and scatter-rules shards were run against the
intermediate bake and the placement total only moved within the same ceiling
(826,892 against a 900,000 limit), so nothing they assert changed class.
**Whoever consolidates should let CI re-run all of them rather than trusting
that sentence.**

Not run: the full `tests/run_tests.gd` (~30 min). Nothing here touches combat,
creatures, UI, story or save format.

## Bakes committed with their config

Both bakes are in the same commit as the config that produced them, per the
tracked-mirror rule:

- `data/terrain/playground/` — **7 of 64** region files changed (one stream
  region, six river regions), from `build_playground_terrain.gd`, 22 min.
- `data/scatter/playground/` — all 256 region files plus the manifest, from
  `bake_playground_scatter.gd`, 5 min. 766,371 → **826,892** placements
  (see the reshuffle note above for why all 256 moved).

## Reproducing anything here

```
# Setup on a fresh container
bash tools/art_pipeline/setup.sh godot        # -> /root/.cache/tetherbound-art/godot
godot --headless --path . --import            # twice; second is clean

# The four new diagnostics -- seconds each, no renderer, no bake
godot --headless --path . --script tools/_probe_ground_seams.gd
godot --headless --path . --script tools/_probe_stream_sightline.gd
godot --headless --path . --script tools/_probe_stream_sightline.gd -- --sweep
godot --headless --path . --script tools/_probe_layer_count.gd -- --layer=drygrass
godot --headless --path . --script tools/_probe_control_map_dump.gd -- --region=0:0

# The bakes, in this order (scatter reads the heightfield, so terrain first)
godot --headless --path . --script scripts/world/build_playground_terrain.gd   # ~22 min
godot --headless --path . --script scripts/world/bake_playground_scatter.gd    # ~5 min

# Evidence frames (NEVER --headless with a rendering driver -- see conventions)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --states=day
```

Measured on this container, against the numbers earlier handovers quote: a
five-band `--states=day` capture is **12 minutes**, not the 25+ T1-GROUND
budgeted for two bands. One terrain region bakes in 22 s.

## What I would do next, in priority order

1. **Re-judge §1f's "scatter reads procedural" on a post-§0 capture**, before
   anyone retunes clumping against the compromised frames. One render settles
   it, and the bushes layer is already clumped and trail-sited.
2. **Judge the second species.** It is placed, measured and tested, but the
   only thing that decides whether 130,547 tussocks read as a second grass or
   as clutter is a blind pass over the AFTER frames in
   `ralph/reports/T1-GROUND-3/shots/`. If it reads as clutter, the first knob
   is `drygrass.verge.count`, then `corridor_fill.density_scale` — not the
   clump numbers, which are chapter-wide.
3. **Finish the dashed seam lines** with the clipmap test named in item 2 —
   one render with Terrain3D's `mesh_lods`/`mesh_size` changed. Much cheaper
   than the debug overlay two lanes have proposed, and it is the last
   candidate standing.
4. **The river's hard turf line** — per-metre noise on the rim inside
   `_river_carve`. This is the remaining half of the canal read and the one
   that does *not* require touching the bank angle. Needs a terrain regen.
5. **The 30,000 wasted `grass` verge placements**, which are baked and never
   rendered while the layer is suppressed. Free headroom under the ceiling for
   whoever needs it next.
6. **Add `CAPTURE_CHECK.require` to the capture tools whose frames get
   committed as evidence.** The §0 source fix is global so no tool needs it to
   get grass back, but only the tool that calls the check is protected against
   the next system that breaks this way. One line each, at the shutter.
7. **Mid-distance smear tier** (brief item 6), still un-reproduced by two
   lanes now.

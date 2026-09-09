# Veilfall visual attribution brief

The standing visual lane selects the current Water audit's cascade whiteout,
not another catalogue-wide judgment. `REJUDGE-WATER.md` identifies extreme pale
wash and overlapping foreground anatomy in destination 15, day and night.
The retained corrected night image was inspected directly: most of the world
view is pale cyan/white with creature anatomy visible through it, while the HUD
and a dark terrain wedge remain legible. This does not yet distinguish the
waterfall from the foreground creature's own material.

Source candidate: `water_veilfall.gd::_build_waterfall` creates a 20 by 82 metre
plane with constant 0.83 alpha, double-sided rendering, and unshaded colour.
This is a local waterfall presentation mechanism, separate from the shared
world lighting and creature colourway systems. No production fix is justified
until the plane's contribution is isolated.

Root approved this bounded attribution on 2026-09-09. Ownership is limited to
the waterfall visual builder/config, a new curtain shader if justified,
`tools/veilfall_visual_probe.gd`, and this report. No actor dimensions, installed
art, interactions, progression, or controller gates may change.

The new probe extends the existing production catalogue survey. It retains the
canonical day/night captures, then records explicitly diagnostic matched pairs
with the runtime paused and the curtain visible/hidden. Pausing prevents moving
creatures from masquerading as the material delta. Curtain visibility is restored
before resuming. A normal left-stick backstep, bounded by 12 metres or 240 physics
ticks, supplies a second context without relocating world actors. The normal
canonical frames remain separate from these diagnostic images.

Predeclared measurement: matched-pair RGB absolute difference and fraction of
pixels changed by more than 8/255; report both whole viewport and world-only
crop x=0..999, y=0..449. Also compare that crop's median luminance and fraction
with all RGB channels above 0.75. The hidden-curtain image is attribution only,
never a proposed final look or acceptance frame. A material repair, if confirmed,
requires fresh visible-curtain day/night before/after frames and independent
code-blind judgment.

The probe parsed successfully on its first check-only execution using Godot 4.7
headless and an isolated APPDATA/LOCALAPPDATA profile. No world was booted for
that parse. The full-world lease belongs to the aim lane until its terminal
result; visual rendering is queued next, capped at 600 seconds externally and
580 seconds internally, with the existing resource guard.

## Attribution result and bounded repair

The first render completed in 54.6 seconds with `CATALOGUE SURVEY OK: 2/2`:
two normal canonical frames and eight labelled diagnostic frames in
`shots/veilfall-attribution/round-20260909/`. The console identifies Windows
Compatibility/OpenGL on NVIDIA RTX 3050. No `ERROR:` or `SCRIPT ERROR:` occurred;
retained Terrain3D missing-mipmap warnings remain. The wrapper recorded no guard
stop and all owned processes ended. Its launcher exit-code field was null, so
terminal success here is the engine's explicit result plus the complete manifest,
not an invented process exit code.

Matched canonical night pair: curtain visibility alone changes 99.9278% of the
declared world crop by more than 8/255. Crop median luminance is 0.85444 visible
versus 0.09738 hidden; all-channels-above-0.75 fraction is 99.1262% versus zero.
The hidden-curtain image retains the same coloured creature anatomy and dark
terrain. This confirms the unshaded plane as the dominant whiteout mechanism.
Day changes 99.8853% of the crop, with mean absolute RGB difference 0.17167.
The ordinary backstep faces the cliff and has zero significant curtain-toggle
delta: it is a useful negative control but no distant waterfall context proof.

One material repair replaces the constant unshaded overlay with a lit spatial
curtain. Vertical flowing noise breaks up opacity, and outer edges feather.
All visual tunables live in the existing waterfall config. Colour, dimensions,
transform, entry prompt, gameplay and actor scale remain unchanged. No new art
asset or generation is involved. A bounded right-stick orbit was added to the
supplemental probe to seek curtain context after the ordinary backstep; canonical
capture remains identical. The adapted script parses successfully.

Current status: after-render and independent visual judgment pending. This is
an implemented candidate, not a visual improvement or acceptance claim.

## First candidate render

The single after run completed in 55.6 seconds with `CATALOGUE SURVEY OK: 2/2`,
no native/script errors, no resource-guard stop, and no remaining Godot process.
Its launcher exit-code field again returned null; the manifest and engine result
provide terminal evidence. Raw logs are `.artifacts/veilfall-after-20260909/`.
Normal current frames and neutral `_sheet_current.png` are in
`shots/veilfall-attribution/round-after-20260909/`. Only the two unsuffixed
canonical day/night PNGs are judge inputs; every paused pair and hidden-curtain
image is excluded. The bounded backstep/orbit still faces the cliff and supplies
no useful broader waterfall context. No actor was relocated to improve it.

| Canonical world crop | Before | Candidate |
|---|---:|---:|
| Night median luminance | 0.85444 | 0.15338 |
| Night all-RGB >0.75 fraction | 99.1262% | 0% |
| Day median luminance | 0.74344 | 0.77283 |
| Day all-RGB >0.75 fraction | 0% | 34.7036% |

These cross-run numbers are observational, not pixel-isolated material deltas:
production creatures continued moving, and shader flow follows runtime time.
The earlier paused within-run attribution is the causal evidence. The candidate
removes the measured night whiteout, but daylight is brighter by these metrics;
that is retained for the critic, not glossed over as an improvement.

Current canonical SHA256 identities:

- Day: `252482D2ED40BA1762679556A32C8D1AB2F53B59445825B43942AE98D98E44D7`.
- Night: `3FF608793E9ED1712B46AC38A92F6B6D2EFB5167B2C2F94234D238E28BB490AB`.

Scoped diff whitespace check passed. The shader compiled and rendered through
actual Compatibility execution. No full campaign or gameplay acceptance is
claimed. Independent judgment is pending; no second tuning round has run.

Retained corrected night frame quantitative anchor: the declared world crop
has median luminance 0.85444 and 94.9613% of pixels with every RGB channel
above 0.75. These are display-referred RGB measurements, not physical light
or a creature/material attribution. The pale wash is measurable before the
diagnostic; those initial measurements did not yet establish the cause.

## Independent verdict and final mechanism round

`VEILFALL-BLIND-JUDGE-0909.md` independently answers A No / B Yes / shipping No.
The broad night whiteout is gone, but the critic names daylight wash, a hard
diagonal water/ground edge, cramped actor silhouettes, bare repeated cliff forms,
and compressed night player values. Actor crowding, character materials, HUD,
and environmental dressing remain separate unresolved causes. The candidate
is held for review, not presented as a complete waterfall or biome repair.

Root approved one final mechanism round, with no further waterfall tuning after
it. The shader now samples a 64-pixel floating-point line of actual terrain
heights across the exact curtain world X/Z (including the -2m local depth offset).
Linear sampling and a 2m height-above-ground opacity fade address the intersection
that UV-edge feathering cannot. World X maps the sample independently of mesh UV
orientation. Invalid heights raise an explicit error before a safe entrance-height
fallback; shader divisions/fade ranges have positive minima. Dimensions, actor
scales and gameplay remain unchanged. Albedo range is exposed in config and
reduced from 0.66–1.0 to 0.40–0.68 to address the daylight wash without a global
lighting change or removal of the waterfall.

The capture now walks 65m back along the final segment of the existing
`veilfall_exploration_spine` with the shared physical-stick navigator (3000 tick
bound), then uses physical yaw AND pitch input toward the curtain centre (360
tick bound). It saves an unpaused normal context frame even if the approach
cannot expose the full landmark; route failure stays evidence, not a reason to
relocate actors. Canonical normal day/night frames remain separate.

The existing `test_water_veilfall_geometry.gd` passes on final source: one wrapper
test/five assertions and 356 initialized child assertions, zero failures or
native/script errors. It exercises actual cave building and guarded controls,
including the new terrain texture construction against its fixture world.
The adapted capture parses. An initial wrapper invocation refused before launch
because a separately owned tiny network fixture still had live Godot processes.
No render round was spent; the guard was preserved. After those processes ended,
the single final render launched in a fresh profile under
`.artifacts/veilfall-final-render-20260909/`, output
`shots/veilfall-attribution/round-final-20260909/`.

## Final round result; tuning stops here

The final render completed in 97.1 seconds, engine `CATALOGUE SURVEY OK: 2/2`,
with two canonical normal frames, four labelled paused attribution frames, and
two unpaused ordinary-context frames. No native/script errors or guard stop;
all owned Godot processes ended. The wrapper again has null launcher exit code,
so the complete engine result/manifest is the terminal evidence.

Both physical approach walks reached the intended stance: requested
(274.2922, 144.0558, 3908.388), actual (276.0696, 143.9187, 3907.609).
The resulting ordinary camera exposes the tall curtain through the rock corridor.
Its enclosing rock and waterfall silhouette are still a visual acceptance
question, not certified by reaching the stance. No actor or camera was teleported
after each canonical fixture setup. The new context images are explicitly
unpaused, curtain visible, with production actors/HUD present.

Final canonical world-crop median luminance: **day 0.66363, night 0.26107**.
All-RGB >0.75 fractions: **day 2.2038%, night 0%**. Day's first-candidate values
were 0.77283 and 34.7036%. Moving creatures and running shader time prevent these
cross-run numbers from being exact isolated material deltas. They support the
reduced broad wash; the critic must decide whether the actual presentation works.

Neutral judge sheet: `round-final-20260909/_sheet_current.png`, frames ordered
canonical day, canonical night, ordinary context day, ordinary context night.
It includes no paused or hidden diagnostic. All files share the basename
`water__veilfall__15__the_veilfall_cascade`:

| Suffix | SHA256 |
|---|---|
| `__day.png` | `810313be7ded2c7e925a152427fce1bbdc0d61d4fe01493409f40ed9122d5d20` |
| `__night.png` | `f87def75fb9ec30ab5658109a133760b8beb0cf9347f6adcce264429ae0523dd` |
| `__day__ordinary_context.png` | `8a0d2b5380f8cab6bf9ab1838fb7441cb3c01d708a8f0086e24cb50bf08e5c99` |
| `__night__ordinary_context.png` | `0e1180a2adcdb47cddc9e8ef1fa0b8d23404f5488db0062fef192bd60a1bab97` |

Final independent judgment remains pending. This is the second and final serious
waterfall material round. No further tuning or repeated render to chase acceptance
is authorized under this brief. Unresolved environment, crowding, character, HUD,
or waterfall construction findings must move to a distinct cause/issue strategy.
All changes remain uncommitted and held for orchestrator review.

## Final blind verdict, candidate disposition, and capture confound

`VEILFALL-FINAL-BLIND-JUDGE-0909.md` answers A No / B No / shipping No for its
four supplied views. It observes near-total creature-surface obstruction at
night, crowding, bare canyon walls, a detached rectangular waterfall, and
uncontrolled creature colours/night subject values. These observations and the
frames remain intact. Narrow whiteout removal does not establish an acceptable
waterfall landmark, intersection treatment, biome, or shipping presentation.
The final candidate remains held for the root's decision; no further waterfall
material tuning will occur. The new ordinary context exposes existing unchanged
20x82m plane placement against the sky; it is not proof that this material edit
introduced the detached geometry. Neither is lower white-pixel coverage enough
to claim every material effect improved.

Before editing any camera/spawn production code, manifest comparison found a
capture-only confound: the probe's day context physically looks upward, but
the inherited catalogue row resets yaw and retains pitch. The following night
canonical therefore inherits +27.2 degrees instead of the baseline -12 degrees.
This places its camera at Y139.644, only 0.237m above the trainer's feet, with
camera-player distance 2.954m. All earlier day/night pairs and final day use
-12 degrees, camera Y142.238, trainer Y139.407, distance 5.821m. Thus the final
night cannot serve as a matched canonical comparison, and its luminance numbers
cannot isolate a material regression. A body obstructing an actually reachable
camera angle can still be a production issue; the contaminated canonical alone
does not locate that cause or justify modifying shared gameplay collision.

Root approved one harness correction capture, explicitly not another cosmetic
round. The probe restores its original initial pitch before every canonical row;
ordinary context still uses physical yaw/pitch and navigation. No shader, material,
production camera, actor scale, or spawn change accompanies this correction.
The corrected probe parses. Exact row pitch/camera receipts will be compared to
the earlier manifests before submitting the fresh images for judgment.

The correction run completed in 99.6 seconds with complete manifest, explicit
engine success, no native/script errors, no guard stop and no remaining Godot
process. Day/night pitch is now -12.000001/-11.999999 degrees. Camera Y is
142.238113/142.238052 and camera-player distance 5.821172/5.821143 metres,
matching the original canonical framing. The corrected night shows complete
creatures, trainer and corridor rather than the earlier inside-body close-up.
Crowding and night subject-value defects remain visible; no broad pass follows.

Corrected neutral sheet and four normal frames are under
`shots/veilfall-attribution/round-canonical-corrected-20260909/`; paused/hidden
diagnostics are excluded. Exact normal-frame hashes, in sheet order:

- Day: `1f7938f376a51c800e50e07c268510ea1f1c11899b70dc0fde31d5cc8c1f1e0f`.
- Night: `c60f582b6a86536332ceb258e8db8c8f8bdf8148729d9678d271a91e173e453c`.
- Day context: `85204091c491e37aabf0fd1665f5af9b0677e519a497a79d8899c4f2404681b2`.
- Night context: `5d6243a2d363c228080f65665b376f7aebadc06ce84db5ee1d9656a2b16ca08c`.

The final material is unchanged. This was an evidence correction, not a third
waterfall tuning round. Both previous independent verdicts remain unedited.

The corrected fresh review is
`VEILFALL-CORRECTED-BLIND-JUDGE-0909.md`: A No / B Yes / shipping No. It confirms
that readable complete actors and night mood are available at corrected framing,
while retaining crowded silhouettes, weak subject lighting, exposed waterfall
boundaries, bare repeated canyon geometry and weak ground/water transitions.
The original constant night whiteout is removed. The terrain-height fade replaces
the sharp ground-intersection mechanism, but the critic does not certify a
convincing wet transition or integrated waterfall; those remain unclosed. The
candidate must not be advertised as a waterfall landmark or visual gate pass.
No additional water tuning follows. Root retains the shipping/holding decision
for this narrow material repair; the standing visual lane moves to the distinct
creature-clearance diagnosis.

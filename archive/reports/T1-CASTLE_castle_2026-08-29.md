# T1-CASTLE — the castle, 2026-08-29

Continuation of `ralph/reports/T1-ARCH_buildings_2026-08-29.md`'s open item 3
("Castle — inspected, root cause is NOT what it looks like, not fixed").
That lane's own diagnosis stands and is not redone here: a wall face
pixel-samples to the authored `LightRock` colour, correctly brightened by
direct sun; the "pale, flat, plastic/toylike" read is the Quaternius kit's
own solid-colour, no-texture geometry with nothing between "wall" and
"crenellation".

## Re-verification before touching anything

Godot was not installed in this session's container; the previous lane's
tools assumed it was. Downloaded Godot 4.7-stable (the version CI pins) to
`~/godot-bin`. Wrote `tools/capture_castle_t1castle.gd` — the same
lightweight terrain+landmark-only staging `capture_castle_lite.gd` already
proved valid for judging the castle's own materials, but at the current
post-GATE-E2 `landmark.gd::SITE` instead of that file's stale `TOWER_AT`, and
with `capture_castle_63.gd`'s own four stands (a fourth, `04-flank-close`, a
point-blank single-wall-panel view, added here — the other three don't get
close enough to judge the texture fix at the range STRONGHOLD-R2's own mottle
was tuned against).

Checked out `building_prefabs.json`/`landmark.gd` at the parent commit
(pre-fix) to render a genuine "before" set. Confirmed the diagnosis directly:
`03-corner-close` and `04-flank-close` both show a single flat cream-white
value across an entire 20m+ wall run, with only the module seam lines (no
texture) breaking it up — the plastic read is real and exactly as described.

**Trap hit and fixed while doing this**: the task brief's own warning
("`--headless` HANGS FOREVER with `--rendering-driver opengl3`") was read,
understood, and then violated anyway on the first capture attempt (`godot
--headless --path . --rendering-driver opengl3 ...`) — the process span at
~150 SceneTree ticks/second forever without ever reaching
`RenderingServer.frame_post_draw`, burning ~25 minutes before `strace`
confirmed it wasn't merely slow, it was the documented hang. Killed it,
re-ran without `--headless` (`xvfb-run ... godot --path . --rendering-driver
opengl3 ...`), and it produced all four frames in about three minutes.
Recorded here so the next lane doesn't spend the same 25 minutes rediscovering
it.

## Root cause: two independent, unrelated defects sharing one label

**1. Every material in the kit imports at `metallic=0.5`, not a stylistic
value — a second, DIFFERENT kit-export gap from the one `_why_retint` already
named.** Direct probe (`load()`ing `WallBricks.obj` and reading the resulting
`StandardMaterial3D`):

```
LightRock: albedo=(0.64,0.64,0.64) roughness=1.0 metallic=0.5
DarkRock:  albedo=(0.64,0.64,0.64) roughness=1.0 metallic=0.5
```

Every `.mtl` in the kit (`Banner`, `Black`, `Celing`, `DarkRock`, `LightRock`,
`LightWood` — all variants) carries the identical placeholder block including
`Ks 0.500000`. Godot's OBJ importer has no specular workflow to put `Ks`
into, so it lands in `metallic` — exactly the same class of bug
`BASELINE_RETINT` in `building_prefabs.gd` already found and fixed for
`MI_RockTrim` (a glTF kit missing `metallicFactor` outright; this OBJ kit
supplies a `Ks` that gets misread instead). A 50%-metal dielectric-shaped
surface under the Compatibility renderer (no reflection probes, real-time
lighting only) has nowhere to put the specular half of its response, so it
renders flattened and desaturated relative to real stone — independent of,
and additional to, the "no texture" defect the previous lane already named.

**Fix**: `building_prefabs.json`'s `castle.retint` now sets `metallic: 0.0`
on every material name in the kit (12 entries, converted from bare colour
strings to `{color, metallic}` dicts — the same shape `_apply_retint` already
supports for `MI_RockTrim`, no code change needed in `building_prefabs.gd`).

**2. The kit's geometry has zero UVs**, confirmed directly (`grep -c "^vt "
WallBricks.obj` → 0), so any texture fix has to be triplanar — not a style
choice, the only mapping this geometry supports. This is exactly
`landmark.gd`'s own plinth problem (STRONGHOLD-R2's boxes have no meaningful
UVs either), already solved once in this same file with a generated,
triplanar-mapped stone texture.

**Fix**: `landmark.gd::_weather_castle()` (called once, right after the
castle prefab is instantiated) walks the castle's own stone-material
surfaces (`LightRock`/`.001`/`.002`, `DarkRock`/`.001`, `Black`/`.001`/`.002`
— not `Banner`, `Celing`, or `LightWood`; see below) and sets a generated,
triplanar grayscale multiply texture onto the ACTIVE material
`building_prefabs.gd::_apply_retint` already produced. Two octaves: a fine
mineral grain (same order of magnitude as the plinth's own mottle) and a
coarser, darken-only blotch layer standing in for uneven grime/staining. Safe
to mutate the active material in place rather than duplicate it again: the
`prefabs` composer in `landmark.gd::build()` is local to this one call and
used for no prefab but `castle`, so nothing else shares these material
instances, and mutating once per unique material (not per mesh instance)
means the whole castle pays for one texture lookup, not eight.

`Banner` is deliberately left un-weathered — the reserved heraldic cloth
should stay clean per STRONGHOLD-R2's own reservation. `Celing`/`LightWood`
are small interior/trim surfaces with no `_why_retint`-documented complaint
against them; widening to them would be scope creep past what the owner
verdict and the report actually named.

## What this did NOT do, on purpose

**Did not retint.** The task brief is explicit that the previous lane already
proved the authored albedo is correct, and that changing it "would be motion
without progress." The metallic fix is a material-response bug, not a colour
choice, and left `retint`'s `color` values untouched.

**Measured, honest side effect**: fixing metallic 0.5→0.0 without touching
albedo makes the wall render brighter, not darker — diffuse response scales
with `(1-metallic)`, so removing the 50% cut roughly doubles it in theory;
measured on a fixed pixel patch (`04-flank-close`, same camera before/after)
the actual increase is smaller (~15-25%, likely because ambient/sky fill
contributes a floor that doesn't scale the same way): avg RGB (184,172,148)
→ (212,203,185). The albedo values in `building_prefabs.json` were tuned
across several rounds (`OF4-rebuild`, `GATE-E-STRONGHOLD-ART`) against
renders that had this bug the whole time, so correcting it shifts the whole
castle's exposure up. **This was left as-is rather than compensated with a
second colour change**, per the "do not retint" instruction — but it means
if the owner's next pass still reads the castle as too pale, the fix is
likely a value-ladder retune of `LightRock`/`DarkRock`/`Black` now that
`metallic` is correct, not a reach for `metallic` again. Flagged, not fixed.

Texture-variance measurement on the same fixed patch (`03-corner-close`,
same camera): std-dev of a clean wall region rose from 21.9 to 28.1 (~28%),
confirming the "single flat value" defect is measurably broken up, not just
subjectively different.

## Verified

`shots/t1castle_before/` and `shots/t1castle_after/` (both gitignored, not
committed — same as every other lane's frames in this repo) hold the four
views for each state. `03-corner-close` and `04-flank-close` are the
load-bearing pair: before, an unbroken flat cream field with only module
seams for texture; after, visible mottled grain and grime-blotch variation
across the whole wall, even readable at `02-silhouette-far`'s distance.

`01-approach-gate` is broken in BOTH sets (camera embedded in built
geometry, near-black frame) — inherited verbatim from `capture_castle_63.gd`'s
own offset `Vector3(2.0, 1.8, 24.0)`, which sits +24 local z from `SITE`,
inside the castle's own footprint (z -10..+34) rather than south of the ramp
foot (z -21) the way that file's own comment describes. This predates this
lane (the same offset is duplicated in `capture_t1arch_all.gd`'s
`C-01-approach-gate`, and the T1-ARCH report never actually looked at that
frame — only `C-02`/`C-03`). Not fixed here: it's a capture-tool bug in
inherited coordinates, not a castle defect, and `02-silhouette-far` already
carries the "whole south face from the approach" read this lane needed.
Worth a real fix by whoever next touches these capture tools.

## Not attempted, per the brief

**The `stronghold.json` `yaw_deg: 90` relocation flag.** Read the previous
lane's own note (`_comment_ow5d_relocation`) and agree with its judgement:
re-deriving the room-by-room layout for the correct approach bearing is a
full re-siting job (probe grid, every chamber/light/mark recomputed) and not
something to attempt blind inside this lane's time box. Confirming this in
writing, as instructed, rather than guessing at a fix.

## Performance

Not measured on ROG Ally hardware — this environment has only Godot's
software (llvmpipe) rasterizer. Reasoning about cost rather than measuring
it: the fix adds one `StandardMaterial3D` with `uv1_triplanar` set (one extra
texture sample per pixel of stone, not a shader), the same flag the plinth's
own material already carries in this exact scene, mutated onto up to eight
shared material instances rather than duplicated per mesh instance or per
surface. It is not a new performance category for this scene, only more
surface area paying a cost this scene already pays elsewhere — but "the same
class of cost, more of it, on the single largest built structure in the
Meadows" is exactly the kind of change §21 asks to be measured on real
hardware before calling closed, and this lane could not do that.

## Residual, tunable

The weathering texture's blotch layer is visible as a faint repeating
pattern at `02-silhouette-far`'s distance — the 96×96 texture tiled every 5m
across a >20m wall starts to read as a texture repeat rather than pure
randomness at that range. `WEATHER_TEXTURE_SIZE`/`WEATHER_TEXTURE_METRES` in
`landmark.gd` are the first place to widen if a future pass finds this.

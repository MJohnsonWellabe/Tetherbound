# G3-CREATURE-COLOUR-0904 — evidence

Reopening CREATURE-LEGIBILITY-0903 (Gate 2.4): its own `field_emission` fix
(0.9 → 2.5 for Bramblebun) was a constant per-species multiply, unscaled by
time of day, and the ledger recorded two consequences of that as if they were
separate — the night "glowing blob" (P2, found after 2.4 shipped) and the
daytime "candy pink" (GATE2-EVIDENCE-0903's blind judge, independently). Both
trace to the same mechanism.

## Method

`tools/_probe_grass_separation.gd` (extended this session: `--time=` to set
the world's clock via `WorldLook.apply_time()`, `--extra-field-scale=` to
sweep `creature_body.gd::set_field_brightness_scale()` directly). Fixed
camera stand at throwing range, real camera-bound grass, Compatibility
renderer under `xvfb`/`opengl3`. Rec.709 luma via
`tools/_grass_separation_ratio.py`, extended this session to also report the
creature crop's mean RGB / hue / saturation, since a luminance ratio alone
cannot see "reads pink" — a magenta-shifted creature and its hue-neutral
original can share the same luma.

Two real bugs surfaced and were fixed *during* this measurement, not found
in the target code:

1. `world_look.gd::_process()` re-blends the full environment (including the
   new `creature_field_emission_scale` key) every `BLEND_INTERVAL`
   regardless of `apply_time()` — an unfrozen clock silently overwrote a
   `--extra-field-scale=` variant's manual value within a couple of frames.
   Every value in a first attempt at this sweep rendered identically. Fixed
   by calling `WorldLook.set_clock_frozen(true)` (its own existing public
   API) before a `--time=` sweep in the probe.
2. The probe's own `_shoot()` called `set_field_brightness_scale()`
   unconditionally with a `1.0` default on every shot, which silently forced
   every *ordinary* variant (SHIPPED, height/emission/degreen sweeps) back to
   the daytime scale even at `--time=night` — the very thing meant to prove
   the real `art.json`-driven path works ("SHIPPED-1.00 at night" rendered as
   the unscaled defect until this was fixed). Now only an explicit
   `--extra-field-scale=` variant drives the scale directly.

Both are committed to `tools/_probe_grass_separation.gd`; see that file's own
git history on this branch for the exact diagnosis in place.

## The fix

**Time-of-day scale (the night half).** `field_emission`/`field_degreen`
used to bake into a duplicated material once, at spawn/colourway-swap time,
with no further connection to the clock. `creature_body.gd` now caches one
shared, rescalable material per `(species, source material, strength,
degreen)` and rescales it in place via a new
`CreatureBody.set_field_brightness_scale()`, mirroring the existing
`set_emission_floor_scale()` (the NIGHT-LEGIBILITY additive floor) — same
static-cache-plus-setter shape, driven off the same clock in
`world_look.gd::_apply_environment()`. New `art.json` key
`creature_field_emission_scale`: base `1.0` (unchanged daytime), night `0.2`
(measured below).

Building this surfaced a second real bug: the pre-existing NIGHT-LEGIBILITY
floor (`_apply_night_floor()`) wraps whatever material is active at BUILD
time by duplicating it once; without an explicit propagation step, a later
rescale of the field-bright material was invisible on the actually-rendered
(night-floor-wrapped) copy. Fixed in `_apply_field_bright_values()` by
pushing the new albedo forward into the wrapped copy when one exists. Caught
by `tests/smoke_creature_field_brightness.gd` (new) before any render was
needed.

**Decoupling `field_degreen` from `field_emission`'s strength (the day
half).** `field_degreen` suppresses the green channel's share of the same
brightness push (`_brighten_node()`'s `g_factor`), and that suppression used
to scale WITH `field_emission`'s own `strength` — `g_factor = 1 + strength *
(1 - 0.5*degreen)`. Gate 2.4 raising `field_emission` 0.9 → 2.5 for a
luminance bar therefore nearly tripled the R/B-vs-G divergence a *separate*
hue lever (OWNER-0901-CREATURE-GRASS-VISIBILITY-V2, for moss patches reading
grass-hued) had been tuned to open, at the SAME `field_degreen` value the
whole time. A value push for one bar quietly re-tuned a hue lever it was
never meant to touch. `FIELD_DEGREEN_GAP` (`creature_body.gd`) now pegs that
gap's absolute size to what a real blind pass approved at the species'
*original* `field_emission` (0.9 × 0.5 × 0.75 = 0.3375 → 0.35), independent
of how far the value lever is pushed afterward.

## Measured — Bramblebun, day

Real render, `--time=day`, crop boxes `(600,380,680,440)` creature /
`(150,260,380,340)` grass (a tighter version of CREATURE-LEGIBILITY-0903's
own `(585,350,700,450)`/`(150,260,380,340)`, since the wider box dilutes hue
with surrounding grass at this scale):

| | luma ratio | creature mean RGB | hue | sat |
|---|---|---|---|---|
| Before (coupled degreen, shipped code) | 1.263:1 | (99, 100, 63) | 63° | 0.377 |
| After (decoupled degreen, this fix) | **1.618:1** | (126, 130, 74) | 65° | 0.427 |

Both clear/fail the 1.5:1 bar as shown — a second finding: **the scene's
own lighting has drifted since Gate 2.4's 1.568 measurement** (unrelated
lighting/terrain passes landed on this branch since 0903), so the shipped
0.9→2.5 fix no longer clears its own bar at all under the *old* formula on
current `main` — only this session's fix does. Not investigated further;
recorded so it isn't mistaken for this fix's own regression.

The crop-box hue numbers above do NOT show a large swing (both read
yellow-tan, not literally magenta) — a fixed-box mean over torso+shadow+
grass dilutes exactly the kind of local, high-saturation shift a human eye
catches on sight. The blind judge (below), looking at the actual rendered
image rather than a numeric crop mean, is the real evidence for the "candy
pink" claim and its fix.

## Measured — Bramblebun, night

Same stand, `--time=night`, clock frozen, `--extra-field-scale=` sweep
against shipped `field_emission=2.5`/`field_degreen=0.75`:

| scale | creature luma | ratio | note |
|---|---|---|---|
| 1.0 (unscaled — the shipped-until-now defect) | 0.388 | 8.83:1 | unambiguous glowing blob, see contact sheet |
| 0.5 | 0.307 | 6.93:1 | |
| 0.4 | 0.291 | 6.60:1 | |
| 0.3 | 0.269 | 6.08:1 | |
| **0.2 (chosen)** | **0.251** | **5.69:1** | |
| 0.15 | 0.241 | 5.45:1 | |
| 0.1 | 0.233 | 5.28:1 | |

Monotonic, roughly linear. `creature_emission_floor` (the separate, already-
tuned NIGHT-LEGIBILITY additive floor, 0.22 at night) is a different lever
doing the "stay visible in the dark" job; this scale only had to stop ADDING
an unscaled daytime push on top of it, not replace that floor. 0.2 sits past
the steepest part of the curve (1.0→0.5 alone is a 22% cut) while leaving
enough of the push that the creature is not relying on the floor alone.
Re-rendered end-to-end through the real `art.json`-driven path (no
`--extra-field-scale=` override) to confirm: `creature=0.249`, `ratio=5.67:1`
— matches the sweep's own 0.2 point.

## Blind visual judge

Contact sheet `_sheet_before_after.png` (day-before / day-after /
night-before / night-after, this branch's own real frames), handed to a
fresh sub-agent with no source or conversation context, asked specifically
about pink-coat-by-day and glowing-blob-by-night, plus two overcorrection
checks (bleached-by-day, invisible-by-night). Full transcript is this
session's own record; verdict:

> Day: [before] "the body fur has a distinct salmon/blush cast... sitting
> close to a light pink". [after] "noticeably whiter and cooler... the pink
> cast is not visible... primarily a colour shift... not just a brightness
> change." No new bleaching: "still shows texture... still carries real
> colour."
>
> Night: [before] "a bright, near-white/pale-lavender mass... reads as
> self-lit, like a glowing prop." [after] "visibly darker and more
> desaturated... no longer popping as an obviously lit object... sits much
> closer in value to the dark grass." Not invisible: "still clearly
> identifiable as a distinct shape."
>
> Verdict: "Both changes are real, visible improvements targeted correctly
> ... Neither fix overcorrects into a new defect."

## Rest of the roster (docs/CURRENT_STATE.md §3's own open item)

Only Bramblebun had been re-measured against Gate 2.4's 1.5:1 bar; Mudsnout,
Terrapup and Burrowback still carried an earlier pass's 1.06–1.15-tuned
values. Measured this session, `--species=`, day, same grass reference box:

| species | shipped `field_emission` | measured ratio | verdict |
|---|---|---|---|
| Terrapup | 1.4 | 1.66:1 | **clears**, unchanged |
| Mudsnout | 1.4 | 1.35–1.43:1 | **fails** — raised to **2.2** (measured 1.73:1); no `field_degreen`, hue held flat at ~44° across the whole sweep, no pink-shift risk |
| Burrowback | 0.9 | 0.85:1 (creature *darker* than the field) | **not a straight fix** — see below |

Burrowback is grey-olive "rock-nodule armour" *by design* — its own
`_comment_field_emission_vp9` names the colour choice as deliberate camouflage
against a ridge camp's rocks. It is naturally darker than grass, not
brighter, and even scored as an absolute contrast ratio (max/min) only
reaches 1.18–1.19:1 across a sweep to `field_emission=1.7`. Pushing it toward
1.5:1 the same direction as the other three (brighter) trades away the
identity the species was built around, for a bar written around a creature
meant to stand out in grass. Left at 0.9, unchanged, documented in
`species.json` as a design question for whoever owns that call next, not
silently treated as passing.

## Grass acid-lime finding (investigate-and-report only, per this lane's scope fence)

GATE2-EVIDENCE-0903's judge named "the grass highlight going acid lime" as
one of two palette breaks, alongside Bramblebun's own candy-pink. Traced
(read-only — `shaders/grass_field.gdshader` and `data/config/grass_field.json`
are not this lane's to edit, and the owner's standing instruction is
explicit: *"don't change the look of my grass. it's awesome"*):

`grass_field.json`'s `tint_tip` is `#66803a` — HSV (82°, 55%, 50%): a real,
fairly saturated yellow-green, consistent with an "acid lime" read once lit
and pushed through ACES at full sun. `tint_base` (`#354410`) is a much
darker, less saturated olive by comparison. The lift from base to tip
(`grass_field.gdshader`'s `mix(root, tint_tip, smoothstep(...))`, plus
`translucency` backlighting the tip toward `tint_tip` again) is what would
make the blade *tip* specifically read hotter than the rest of the field.
Not touched, per scope. If this is picked up: the tip's hue (82°) and
saturation (55%) are the two numbers a future pass would want to move, and
`translucency` (0.18) is the lever most likely to be amplifying it toward the
sun.

## Tests

- `tests/smoke_creature_field_brightness.gd` (new): rescale reaches a live,
  already-spawned material (the night mechanism); `FIELD_DEGREEN_GAP` is a
  flat constant independent of `strength` (the day mechanism). **PASS.**
- `tests/smoke_art.gd`: unaffected — model/collider fit, shiny/alpha/tier
  presentation, humanoid cast, vegetation. **PASS.**
- `tests/smoke_night_ecology.gd`: pre-existing failure (duskhush night
  clusters), reproduced identically on this branch's own base commit before
  any change here — not this lane's regression, not investigated further.

## Files changed

- `scripts/creatures/creature_body.gd` — time-of-day field-brightness scale,
  night-floor propagation fix, `FIELD_DEGREEN_GAP` decoupling.
- `scripts/world/world_look.gd` — wires `creature_field_emission_scale`.
- `data/config/art.json` — new key, base 1.0 / night 0.2 (measured).
- `data/creatures/species.json` — Mudsnout `field_emission` 1.4 → 2.2;
  Burrowback documented, unchanged.
- `tools/_probe_grass_separation.gd` — `--time=`, `--extra-field-scale=`, two
  real bugs found and fixed while using it (clock freeze, scale override).
- `tools/_grass_separation_ratio.py` — hue/saturation reporting.
- `tests/smoke_creature_field_brightness.gd` — new.

# Gate sentries at night — chest-height post lights (VP8, round 12)

Frames: `round12-sentries-night/` (1280x720, `--only=10-stronghold`, one render).

## Mechanism
`gate_sconces` is an EMISSIVE PLAQUE (no light node) on the tower face, and
the real `gate_source`/`lights` OmniLights sit 6-10m away at the tower base —
neither reaches the inner jamb face the sentries stand at (see
`DECISION-sentries-restart.md`). Added exactly one mechanism: a new
`gate_sentries[].night_light` block in `stronghold.json`, read by
`stronghold.gd::_build_gate_sentries` to spawn one shadowless warm
`OmniLight3D` as a **child of the sentry body** (offset lands in the body's
own local space, follows `facing_deg` automatically) at chest height, offset
toward the camera side. Both entries face 0.0 deg (local -Z = world south =
the gate-face camera), so `offset.z = -0.6` lights the figure's front.

No day/night gate added: `_build_hall_fire()`/`_build_gate_tower_sconces()`
carry no `is_dark()` check either — every stronghold practical is a fixed
light/plaque, always on — and a 4m-range chest-height omni is lost in
daylight ambient on its own (confirmed below).

## Values (both `gate_sentries` entries, identical)
`light_color (1.0, 0.72, 0.45)`, `energy 2.4`, `range 4.0`, `attenuation 1.2`,
`offset [0.0, 1.3, -0.6]`.

## Proof (PIL, luma = .299R+.587G+.114B, one render)
Boxes confirmed against the day frame: west x[710,759] y[272,379], east
x[529,575] y[258,379] (`DECISION-sentries-restart.md`'s own measured extents).

`10-stronghold-gate-face-night.png`:
- west guard mean luma: **29.17** (was 5.1) — PASS (>= 25)
- east guard mean luma: **30.55** (was 6.4) — PASS (>= 25)
- both read at 3x zoom: head, harness, belt, torso, boots all legible.

`10-stronghold-gate-face-day.png` vs round11 baseline: **1.005%** pixels
changed (< 5%) — day composition unaffected.

## Decision
Keep the change. Night passes at both posts with margin; day unchanged.
`tests/smoke_stronghold.gd` passes (exit 0).

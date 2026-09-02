# BACKLOG-B2-GRASS-SEPARATION — height/rim sweep against the live shipped mesh

Branch `ralph/BACKLOG-B2-GRASS-SEPARATION`. Investigates the ledger's own
closing-cost note ("tune existing rim/height knobs in `species.json`") for
`data/creatures/species.json`'s `bramblebun` entry, against the target the
2026-08-31 audit (`ralph/reports/audit/B-2026-08-31.md`, §B2 + addendum)
names: restore the creature/grass luminance ratio to roughly the pre-redesign
1.06-1.15 range.

**Result: no numeric field in `bramblebun.placeholder` reaches that range
without breaking a real constraint. `height` and `field_rim` are left
unchanged (1.00m / 0.0).** This is a measured conclusion, not a default.

## Why the probe itself needed a fix first

`tools/_probe_grass_separation.gd` only ever rendered two hardcoded heights
(0.78/0.96) — the audit's own addendum named this as the reason it could not
test the actual shipped height (1.00m) directly. Fixed here: the script now
always renders a `SHIPPED` variant reading `placeholder.height`/`field_rim`
straight from the live species table, plus an optional `--extra-heights=`
list for sweeping candidates in one boot. See that script's diff on this
branch.

## Method

`tools/_grass_separation_ratio.py` (new) reimplements the audit addendum's
ad hoc method — Rec. 709 luma (`0.2126/0.7152/0.0722`, the same weighting
`tools/frame_stats.py` uses), one creature-region crop, one grass-region
crop, ratio = creature_luma / grass_luma — since the original script that
produced the 2026-08-28 figure was never committed.

Unlike the audit's own crop box (hand-picked from looking at one frame, the
addendum's own stated limitation), this session's creature box —
`(595,325)-(745,445)` in the probe's fixed 1280x800 camera stand — was
checked by eye against every rendered height (0.86 through 1.15m) to confirm
it bounds the full visible silhouette at each one, not just the height it was
picked from. Two independent grass reference boxes are used, as the addendum
did: `(60,260)-(260,380)` and `(800,320)-(940,410)`.

Seven heights were rendered against the real, current `bramblebun_redesign`
mesh (`meadows_playground.tscn`, same camera stand and throwing-range distance
the probe's header describes): the grass-clearance floor (0.86m — the tallest
tuft `grass_field.json`'s `height_far`/`height_jitter` can produce), 0.90m,
0.96m (the pre-T3-CREATURES height), the shipped 1.00m, and two candidate
increases, 1.10m and 1.15m. Evidence:
`ralph/reports/audit/grass_separation_verify_0831/` (1.00/1.10/1.15) and
`grass_separation_verify_0831b/` (0.86/0.90/0.96/1.00).

## Results

| height | ratio (box 1) | ratio (box 2, HUD-clear) |
|---|---|---|
| 0.86m (grass-clearance floor) | 1.025 | 0.979 |
| 0.90m | 1.022 | 0.974 |
| 0.96m (pre-T3-CREATURES) | 1.015 | 0.970 |
| **1.00m (shipped)** | **1.015** | **0.967** |
| 1.10m | 1.006 | 0.959 |
| 1.15m | 0.999 | 0.956 |

Target: 1.06-1.15. **Nothing in this range gets there — not even close.** The
best point tested (0.86m, the floor below which the creature sinks back
under the tallest grass tuft) still falls 0.035-0.08 short of the target's
own lower bound.

## The ratio moves the wrong way from what the ticket assumed

The ticket's framing was "a small upward nudge... restores clearer visual
separation." The measured relationship is the opposite: **ratio falls as
height rises**, monotonically, across the whole range tested. This is not
new — it is the same direction the pre-redesign 2026-08-28 measurement
already recorded for the *old* mesh (`species.json`'s own
`_comment_field_rim_0828`: 0.78m -> 1.15, 0.96m -> 1.08, height *up*, ratio
*down*) and the same direction the 2026-08-31 audit addendum recorded for
the *new* mesh at its own two hardcoded heights (0.78m -> ~1.05, 0.96m ->
~1.02). This session's sweep across the mesh's full safe operating range
confirms the relationship holds everywhere in it, for the same reason in
both mesh generations: the model's brightest pixels are concentrated in the
ears/antlers at the top of its silhouette, and a fixed-camera crop sized to
the *whole* creature dilutes that bright cap with proportionally more of the
darker body/thorn mass as the creature (and therefore its body, not just its
ear tips) gets bigger. Bigger reads as *less* separated for this mesh, not
more.

## Why the other placeholder fields don't help either

- **`field_rim`**: already measured a no-op-to-negative by the audit's own
  four-way test (1.15->1.14, 1.08->1.06 — rim *lowers* the ratio slightly).
  It is a self-lit material; `creature_body.gd::_apply_alpha_presence()`'s
  own reasoning for why only the alpha tier's much stronger rim (0.65)
  registers applies unchanged. Not retested here; no reason to expect a
  different sign.
- **`model_scale`**: traced through `creature_body.gd::_fit()` — it is a
  pure multiplier applied *after* the height-based fit
  (`fit *= maxf(extra_scale, 0.01)`), feet still anchored to the origin. A
  larger `model_scale` predicts the identical "more body mass, less ear-tip
  fraction" mechanism that makes the ratio fall as `height` rises, so it is
  not expected to help and was not worth spending a render on. A *smaller*
  `model_scale` would shrink the rendered mesh below its own declared
  collider height — reintroducing, visually, the exact "creature sinks into
  the grass" failure the 2026-08-28 height fix exists to prevent, for a
  species whose art and gameplay height must not visually disagree
  (`_comment_art` in this same placeholder block).

## Conclusion

Confirms and extends the audit's own finding rather than overturning it:
**closing B2 for real needs an albedo/value change to the
`bramblebun_redesign` mesh, or an owner-approved size push past "modest"** —
not a config tweak, and specifically not `height` or `field_rim`. Given that,
changing either field on this branch would either reopen the owner-directed
2026-08-28 "too small to see" defect (lowering height below 0.86m) or move
the ratio further from target while gaining nothing (raising it). Both are
worse than leaving `species.json` as-is. A one-line comment recording this
investigation has been added next to `bramblebun.placeholder.height` so the
next lane does not re-spend a render cycle re-deriving the same direction.

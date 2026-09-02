# Decision request: rebuild the Warrens exterior, or keep patching it?

**Raised by:** PLACES area coordinator, after round 9.
**Decision owner:** program coordinator. **PLACES is not making this call unilaterally.**
**Status:** PLACES has paused Warrens-exterior patching pending an answer. Everything else continues.

## The ask

The owner's read is that the Warrens exterior visuals "are not moving in the right direction" and that it
may be better to start fresh rather than keep patching what exists. This document puts the evidence
behind that so the call can be made deliberately.

## The record

Every code-blind judge verdict on `04-warrens-approach-day`, round by round:

| round | verdict |
|---|---|
| 3 | "This is a grey rock pile on lawn… reads as placeholder" |
| 4 | "Changed, better" — recolour only; shape unchanged |
| 5 | "still reads as a sculpted rock bunker with a flush door"; rock material seam at the threshold |
| 6 | "slightly more monolithic/uniform brown"; **introduced** a hard-edged white patch that "reads as a bug, not a design choice" |
| 7 | "Pixel-near-identical. The rock-mound silhouette…" |
| 8 | "byte-identical between rounds — still there, still reading as a [rock pile]" |
| 9 | pale panel still unidentified after two structured attempts |

Seven rounds. The core verdict has not moved once. In the same period this lane converged the Hall at
400 m, the relay compound from bleached white to weathered stone and dark earth, the storm band from ~30 %
to ~3 % of visible sky, and the courtyard banners — so the process is not the problem.

The Warrens exterior also **regressed twice** under patching: the round-6 white patch (still unresolved),
and round-7's scale-up to 15–20 m slabs dwarfing the 1.8 m player (corrected the same round).

## Diagnosis — why patching has not converged

The reference (`docs/reference/palworld-02.jpg`) is an **excavated earthwork**: one continuous weathered
mound with a mouth cut into it. The current build is a **boulder cluster**: a procedural grid —
perimeter courses, a roof grid, a skirt — of individual rock meshes.

Every round has re-tinted, re-scaled, re-counted or re-materialled that same grid (223 → 89 → 66 → 15
pieces, four different material paths, three tint schemes). **You cannot reach "a hole cut into earth" by
tuning a pile of rocks.** It is a different construction, not a different dressing of the same one. That
is the whole reason the verdict repeats.

A secondary cost: seven rounds of patching left overlapping material paths (`_wear_the_cave_stone`,
`_wear_as_earth`, `_wear_as_wall_stone` — since deleted, `_material`, the stain shader, plus
`mouth_dome` / `accent_boulders` / `spoil_mounds` / `entrance_dressing`). The round-9 pale panel could
not be identified in two attempts partly because of that accumulated surface area.

## Options

1. **Rebuild the exterior construction** (PLACES' recommendation). Author the mound as a shaped earth form
   with the entrance cut into it, and keep boulders only as a handful of half-buried accents.
2. **Keep patching.** Cheaper per round, but seven rounds of evidence say it does not converge.
3. **Hand the exterior to a fresh pass with no attachment to the existing build** — the owner's own
   suggestion, and compatible with option 1.

## If a rebuild is chosen — what to keep, not a blank sheet

- **The interior is untouchable and must not move.** It is owner-approved GOOD and the den stand is the
  pixel-stability guard. `burrow_warrens.gd` builds both, so the rebuild must be scoped to the exterior
  functions only (`_build_mound`, `_build_site_skirt`, `_build_approach_apron`, `_build_entrance_dressing`,
  `_build_mouth_dome`, `_build_accent_boulders`, `_build_spoil_mounds`).
- **Keep `shaders/warrens_boulder_stain.gdshader`** — it works, and the accent boulders should still wear it.
- **Keep the earth triplanar treatment** (the trodden-ramp material shared with the village doorstep).
- **Keep the grass suppression** via `CLEAR_RADIUS_META` / `apron_run_m`.
- **Keep the interior rock-colour match** (`site.rock` `#5b5147`) so exterior and interior stay one family —
  a judge finding this lane already paid for.

## What PLACES will do meanwhile

Warrens-exterior patching is paused. The two open non-Warrens items — the courtyard-night trainer disc
(median 5.82 vs a ≥ 20 target) and sentry legibility at the new `gate-face` stand — continue as normal.

One caveat for whoever picks the exterior up: the round-6 judge locates a pale "bowtie" patch **directly
above the door in the approach frame**, while round 8 refers to "two conspicuously pale, flat" surfaces.
The round-9 hunt targeted a pale slab on the right of the **standing** frame. These may be two distinct
surfaces, and a rebuild would likely remove both — but if patching continues instead, they should be
treated as separate defects and each proven with its own region diff.

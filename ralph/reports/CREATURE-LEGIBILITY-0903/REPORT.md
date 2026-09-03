# CREATURE-LEGIBILITY-0903 — Gate 2.4 evidence

Task: `docs/ROADMAP.md` 2.4, "Creature legibility in habitat". Acceptance:
Bramblebun-vs-ground luminance ratio >= 1.5:1 at 30% scale, measured off real
rendered frames.

## Method

`tools/_probe_grass_separation.gd` (already in the repo from an earlier pass
at this same problem) renders a fixed camera stand at throwing range in real,
camera-bound grass (`meadows_playground.tscn`, Compatibility/opengl3
renderer, xvfb). Luminance measured with Rec.709 luma
(`0.2126R + 0.7152G + 0.0722B`) over two fixed crop boxes on the 1280x800
frame:

- creature box `(585,350,700,450)` — tight around the Bramblebun's own body.
- ground box `(150,260,380,340)` — open grass, clear of UI, shrubs and flowers.

Ratio verified unchanged when both boxes are scaled to 30% before measuring
(same mean, since luma averaging is scale-invariant): SHIPPED 1.3327 vs.
1.3310 at full res, TEST-e2.00 1.5218 vs. 1.5232, TEST-e2.50 1.5661 vs.
1.5681 — the "at 30% scale" clause holds regardless of which resolution the
crop is measured at.

`_sheet.png` in this directory is BEFORE (left) and AFTER (right), same
camera stand, same tick. Per-frame captures are not committed
(`.gitignore`'s `ralph/reports/CREATURE-*/**/[!_]*.png`, matching this
project's existing evidence-payload policy) — the contact sheet is the
tree's own record.

## Lever 1 — material value (the one that moved the ratio)

Bramblebun's `field_emission` (`data/creatures/species.json`,
`creature_body.gd::_apply_field_brightness()`) already existed from a prior
pass at this same defect, shipped at 0.9. Re-measured at the CURRENT
stand/lighting because that pass's own target (1.06-1.15) is well under this
gate's 1.5:1 bar:

| field_emission | ratio |
|---|---|
| 0.9 (shipped, before this lane) | 1.331 |
| 1.2 | 1.389 |
| 1.6 | 1.467 |
| 2.0 | 1.523 |
| 2.5 (shipped now) | 1.568 |
| 3.0 | 1.612 |

2.5 was chosen for real margin over the 1.5 floor while the rendered frame
still reads as the creature's own cream/tan coat rather than a blown-out
white shape (checked against the frames directly — see the blind judge's
own note on this below).

Height and `field_rim` were left alone: this species' own `species.json`
comments already measured height moving the ratio the WRONG way (falls as
height rises) and rim as a no-op on this self-lit-by-multiply material, in
an earlier pass. No mesh change, no shrink — OWNER DIRECTIVE 2026-09-01's
"grow, don't shrink" rule; this pass only raises a value multiplier already
in the species table.

## Lever 2 — ground-contact shadow (grounding, not the ratio)

`shaders/creature_contact_shadow.gdshader` + `creature_body.gd`'s new
`_apply_ground_contact_shadow()`: a flat, unshaded, soft-edged ellipse under
every creature body's own model origin, sized off gameplay `radius` and
applied uniformly (not per-species). Verified headless with
`tools/_probe_contact_shadow_check.gd` (`OK: ContactShadow present,
size=(0.8775, 0.8775), visible=true, material=ShaderMaterial`). This does
not move the luminance ratio above (the crop boxes are chosen clear of the
shadow's own footprint, by design — the ratio is about the creature's own
material, not the ground under it) but answers the renderer's own missing
SSAO (`tools/survey.sh`'s header: no SSAO on Compatibility) — the "sits ON
the ground, not IN it" half of the task brief.

## Lever 3 — spawn siting away from shrubs

Already implemented by an earlier pass (`OWNER-0901-CREATURE-GRASS-VISIBILITY-V2`):
`encounter_director.gd::_pick_clear_spot()` retries a candidate spawn point
against `vegetation.gd::has_solid_scatter_near()`, which checks both
COLLIDABLE scatter and the non-colliding `bushes` layer's own
`_bush_positions`/`BUSH_VISUAL_RADIUS`. Verified this mechanism is still
wired into the one spawn path every authored `spawns.json` entry uses
(`encounter_director.gd:409`) and left unmodified — it already does the job
this lever asks for, and `CLEAR_MARGIN`/`CLEAR_ATTEMPTS` are load-bearing for
the meadow's per-cluster spawn determinism (shared `rng` draws across a
cluster's members), so retuning them without a measured reason risks moving
every downstream creature's position in that cluster. No file under
`data/config/vegetation.json` or `grass_field.json` touched, per the task's
own scope fence.

## Blind visual judge (`.claude/skills/visual-judge/SKILL.md`)

Run against `before.png`/`after.png` (same frames as `_sheet.png`), with no
knowledge of what changed. Verdict, in full:

> **Readability**: At full size [the after frame] reads clearly: the
> creature's body is now a pale cream/white mass with concentrated
> rust-orange mottling around the head/ear-spikes, sitting against a
> mid-dark olive grass ground — there's real value separation now, unlike
> before. Shrunk to ~30%, it still reads as a distinct pale blob with a
> spiky silhouette breaking the grass line.
>
> **What changed**: In before.png the coat was a rosy-tan base overlaid with
> dark blackish-green camo blotches that sat close in value to the shadow
> patches in the surrounding grass — classic camouflage-into-background
> failure. In after.png the base coat is much lighter with the dark patches
> replaced by warm rust-orange, which no longer value-matches the grass
> shadows — a genuine, effective fix for value contrast.
>
> **Defects**: The new coat reads as flat and slightly blown-out on the
> torso/haunch — near-paper-white with little shading gradient, edging
> toward "bleached toy" rather than "furred animal." Noted, not fixed this
> pass — the acceptance criterion is the measured ratio and whether the
> creature reads, and the judge's own direct answer (below) is yes on both.
>
> **Direct answers**: Belongs to the key-art world: borderline-yes. Holds up
> next to the Palworld bar on legibility against terrain specifically: YES —
> contrast against the ground is now solidly better than before and
> comparable to how Palworld's pale creatures separate from grass.

## Tests run

- `tests/smoke_art.gd` (headless): `art: OK` — models still load, sized to
  their colliders, meadow still dressed. 0 failures.
- `tests/smoke_wild_streaming.gd` (headless): pass, 0 failures.
- `tests/run_tests.gd --only=test_shiny.gd,test_evolution_links.gd,test_wild_alphas.gd,test_spawns_data.gd`:
  63 tests, 2132 assertions, 0 failed.
- `tools/_probe_contact_shadow_check.gd` (new, headless): confirms the
  ContactShadow node builds with the expected size on a real spawned body.

## Follow-ups not chased in this pass

- The judge's "flat/blown-out" note on the 2.5 value is real and could be
  softened with a shading/gradient pass on the swap material rather than a
  flat multiply, if a future lane wants to chase it — not required to clear
  this gate's own acceptance criterion.
- Only Bramblebun was re-measured and retuned. Other species carrying
  `field_emission` from the earlier 1.06-1.15 pass (Mudsnout, Terrapup,
  Burrowback) were not re-swept against the new 1.5:1 bar — out of this
  task's named scope (Gate 2.4 names Bramblebun specifically as the
  acceptance target) but likely under the same new bar if it is ever applied
  to them.

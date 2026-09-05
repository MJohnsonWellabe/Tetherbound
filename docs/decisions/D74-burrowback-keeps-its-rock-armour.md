# D74 — Burrowback keeps its rock-armour, and is made legible by value and rim, not hue

**Date:** 2026-09-04 · **Decided by:** the W19-CONTRACTS lane, as the orchestrator's
recorded design call (D73 §"How evidence is produced": open design questions are decided
by the orchestrator and recorded here, not queued for the owner). **Source:**
`ralph/reports/G3-CREATURE-COLOUR-0904/REPORT.md` §"Rest of the roster";
`docs/FINISH_THE_MEADOWS.md` Phase 1 item 1.8, *"Someone has to decide whether the bar or
the identity gives."*

## The question

Gate 2.4 (CREATURE-LEGIBILITY-0903) set a creature-against-grass luminance bar of
**1.5:1**, measured as creature-crop luma over grass-crop luma at throwing range under the
Compatibility renderer. Bramblebun (1.618:1), Terrapup (1.66:1) and Mudsnout (raised to
2.2 `field_emission`, 1.73:1) clear it. Burrowback does not: at its shipped
`field_emission 0.9` it measures **0.85:1** — *darker* than the field — and across a full
sweep to 1.7 it reaches only **1.18–1.19:1** as an absolute max/min ratio. Its colour is
grey-olive "rock-nodule armour", named in `species.json`'s own
`_comment_field_emission_vp9` as deliberate camouflage against a ridge camp's rocks.

Pushing it brighter to meet the bar trades away the identity. Leaving it fails the bar.
The lane that measured it correctly refused to pick.

## The decision

**The identity stays.** Burrowback is a dark, armoured digger and it reads as one against
grass because it is *darker* than grass. The 1.5:1 bar was written for creatures meant to
stand out **bright** against a field, and it is kept for those. For Burrowback the bar is
restated in the direction its design already points:

1. **The accepted ratio is 1.30:1 in the dark direction**, measured as **grass luma over
   creature luma** on the same stand, same crop method and same renderer the
   G3-CREATURE-COLOUR report used (`tools/_probe_grass_separation.gd`,
   `tools/_grass_separation_ratio.py`, day, clock frozen). Today's 0.85:1 creature/field
   is 1.18:1 field/creature; the target is reached by taking the body's **value** *down*
   (`field_emission` below 0.9, or a darker albedo multiply on the armour material — the
   same shared-material rescale path `CreatureBody.set_field_brightness_scale()` already
   uses) — never by pushing the hue toward grass-green or the value up. A ratio between
   1.18 and 1.30 that a blind judge nevertheless reads cleanly is recorded as a measured
   miss, not rounded up.
2. **The silhouette is carried by rim and contact, not by fill.** The levers are the two
   that already exist and were tuned by measurement elsewhere: the alpha-style **rim**
   (`alpha_aura.gd`'s rim term, at a fraction that reads as edge light rather than an
   aura — the guardian's own 1.2 warm rim is the ceiling, the species default is a
   third of that) and the **contact shadow** (CL-A-era creature contact shadows, shipped)
   at full strength under the body. The judge's test for Burrowback is *"can I trace the
   outline?"* — the same question that closed the Warren Guardian's den read
   (`burrow_warrens.json` `_comment_guardian_stand_wash_verified_0830`: "the silhouette
   reads, carried by the dark body against a mid wall and the floor light pool under it").
3. **At night the emission floor does the job, unchanged.** `creature_emission_floor`
   (NIGHT-LEGIBILITY) and the 0.2 night `creature_field_emission_scale` apply to
   Burrowback as to every species; nothing here touches the night path.
4. **The 1.5:1 bright bar is not weakened for anyone else.** It stays the acceptance
   for Bramblebun, Terrapup, Mudsnout and every species whose design is *lighter* than the
   field. `docs/VISUAL_BIBLE.md`'s creature-legibility line gains one sentence: *a species
   authored darker than the field is measured field-over-creature at ≥ 1.30:1 and judged
   on outline, not on fill.*

## Why

- **A bar written around one creature's design should not overwrite another's.** The
  1.5:1 figure came from Bramblebun, a pale field creature. Applying it to a creature
  whose whole read is "dark rock on green" produces exactly the complaint the owner's
  colour directive was about — two families reading as palette swaps (D23 §1,
  Burrowback vs Terrapup). Making Burrowback brighter makes it more like Terrapup.
- **Dark-on-light is a legitimate contrast and the repo already scores it.** The
  Warrens den verdict was won by a dark body against a mid wall with a light pool under
  it — outline, not fill. The same judge, asked the same question on the field, is the
  test.
- **The levers exist and are measured.** Rim, contact shadow and the shared-material
  value rescale are all shipped, all data-driven, and all have a probe. No new shader,
  no new material, no new mesh (`CLAUDE.md`: no new creature meshes; differentiate with
  materials, VFX and context).
- **Refusing to decide costs more than either answer.** Item 1.8 has sat as "needs a
  call" while the creature colour work around it closed. The cost of this call being
  wrong is one re-measure; the cost of no call is the item staying open.

## What was rejected

- **Raise `field_emission` until 1.5:1 bright.** Measured: it cannot get there (1.19:1
  max across the sweep), and every step toward it erodes the armour read. Rejected on the
  measurement.
- **Retint the armour toward a lighter grey.** Changes an established colourway the owner
  approved on the sheet; a hue/value retint of a shipped species is an owner-board matter
  (D13, `docs/art/wild/`), and the visual lane's own rule is that "retinting an
  established alpha colourway is an owner decision, not a lighting one." Rejected on
  precedence.
- **Exempt Burrowback from any bar.** A creature with no legibility test is a creature
  that will fail the route strip's "creature present and readable" check (Phase 0.1) with
  nobody able to say why. Rejected: the dark-direction ratio *is* its bar.

## What this forecloses

Nothing about Burrowback's night read, its alpha colourway (`_base_color_alpha.png`), the
guardian's own tuned lights, or the 1.5:1 bar for every other species. It forecloses one
thing: a future lane "fixing" Burrowback by brightening it toward the field.

## Where it is wired

`docs/VISUAL_BIBLE.md` (the one-sentence dark-direction rule — the visual track's edit);
`data/creatures/species.json` `burrowback` (`_comment_field_emission_vp9` gains a pointer to
this record; the value itself is the visual lane's to move by measurement);
`ralph/reports/G3-CREATURE-COLOUR-0904/REPORT.md` (unchanged; its "design question" is
answered here). The measurement that closes it is one blind pass on a day frame at the
standard stand, with the field/creature ratio printed beside the verdict.

# OWNER-0901-CREATURE-GRASS-VISIBILITY — brighter, measured

Branch `ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY`. Owner directive
2026-09-01: "some of the smaller creatures blend into the environment too
well like bramblebun and others who disappear in the grass. they either
need to be bigger or brighter." Follows up
`ralph/reports/audit/BACKLOG-B2-GRASS-SEPARATION-2026-08-31.md`, which
proved height/`field_rim` alone can't reach the 1.06-1.15 creature/grass
luma-ratio target for bramblebun and concluded closing it for real needed
"an albedo/value change to the mesh... or an owner-approved size push past
modest." The owner has now approved both halves of "bigger or brighter";
this lane took brighter, per the prior report's own recommendation.

## What actually happened

Tried the B2 report's own suggested mechanism first — boost
`emission_energy_multiplier`, since the file's existing rim/tint code all
assumes creature GLBs ship self-lit (painted albedo copied into the
emission slot). Swept it 0.5-3.0 against bramblebun: **completely flat**,
ratio pinned at 1.014-1.015 the whole way. Diagnosed by spawning a live
body and reading its active surface material back directly: bramblebun's
shipped `bramblebun_redesign` mesh has `emission_enabled = false`. It is a
plain lit PBR material, not the self-lit convention the rest of
`creature_body.gd` assumes — that assumption is correct for the OLDER
production creature pipeline (confirmed on terrapup and mudsnout below,
both of which DO ship an emissive texture) but wrong for this one Meshy
redesign export.

Fixed by multiplying `albedo_color` unconditionally (the lever this mesh's
material actually renders through) and still multiplying `emission_energy_multiplier`
when a surface has it enabled, so the same per-species knob works
correctly either way. Pure multiply, so hue is untouched — the creature
stays in its own painted colour family, never shifts toward an arbitrary
new shade.

## The lever

`creature_body.gd::_apply_field_brightness()` / `_brighten_node()`, opt-in
per species via a new `placeholder.field_emission` value (0.0 = no-op,
same discipline as the existing `field_rim`). `tools/_probe_grass_separation.gd`
gained `--extra-emission=` (sweep `field_emission` at the shipped height)
and `--species=` (point the whole probe at a different species) so the
same tool and method could be reused for bramblebun, terrapup and
mudsnout without a rewrite.

## Measured results

All numbers from `tools/_grass_separation_ratio.py` against real in-game
renders (`tools/_probe_grass_separation.gd`, same camera stand and
throwing range as the B2 report's own evidence), two independent grass
reference boxes per the original audit's method, target **1.06-1.15**:

| species | crop box | before (field_emission 0) | after | tuned value |
|---|---|---|---|---|
| bramblebun | (595,325)-(745,445) | 1.011 / 0.961 | 1.139 / 1.079 | 0.9 |
| terrapup | (490,225)-(795,445) | 0.755 / 0.716 | 1.124 / 1.065 | 1.4 |
| mudsnout | (560,340)-(720,445) | 0.719 / 0.682 | 1.138 / 1.079 | 1.4 |

Before/after frames for all three are in this directory
(`<species>-before-field_emission0.png` / `<species>-after-field_emission<value>.png`).

Terrapup and mudsnout started noticeably *darker* than the field (ratio
below 1.0), not just close-to-1.0 like bramblebun — both needed a bigger
push, and both happened to land on the same tuned value (1.4) by
coincidence of the sweep, not because the two species share a value by
design.

Each species' final value was chosen where BOTH grass reference boxes
land inside the 1.06-1.15 window with margin on both sides, not just
wherever the easier of the two boxes clears first — box 2 (the stricter,
HUD-clear box) is consistently the binding constraint on the low end, and
box 1 the binding constraint on the high end.

## Why terrapup and mudsnout, not a different "2-3 others"

Terrapup: named directly in this lane's brief
(`BACKLOG-VISUAL-TERRAPUP-FIELD-SEPARATION`, mint shell blending into
grass) and it is one of the three starter species (`data/config/opening.json`),
so every player sees it constantly.

Mudsnout: picked by inspecting every species' `placeholder.height` and
`colour` for the smallest, darkest candidates
(`pipwing` 0.76m light grey-blue and `sparkit` 0.85m bright yellow are
both already high-value colours, unlikely to blend) — mudsnout's
`#6e492c` dirt brown at 0.95m was the clearest remaining candidate, and a
real baseline render confirmed it before any fix was applied (0.719/0.682,
visibly a dark blob in the field's own shadow pattern).

## Verification

- `tests/smoke_art.gd` (full meadow boot, every species' art/collider fit,
  colourway/shiny/rim/alpha machinery): **OK**, zero failures, including
  the terrapup-specific shiny/rim assertions this lane's material changes
  run through.
- `tests/run_tests.gd --only=creature,test_evolution_links.gd,test_creature`:
  **52 tests, 112 assertions, 0 failed**.
- `tests/run_tests.gd --only=test_wild_alphas.gd`: **7 tests, 112
  assertions, 0 failed** (alpha rim presence unaffected by the new
  brightness lever running alongside it).

## Not done

Two other "small creature" candidates (`pipwing`, `sparkit`) were checked
by colour/height only, not rendered — both are already high-value hues
unlikely to share this defect, and the owner directive named bramblebun
by name plus "others," which this lane reads as satisfied by two
additional, independently-confirmed cases rather than an exhaustive
roster sweep.

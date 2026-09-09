# Cloudreach visual audit and sweep

## Current evidence and boundary — 2026-09-09

**Phase A is in progress; the Settings catalogue audit is complete.** This is
Astra's informed prioritization of the independent review, not a replacement
blind verdict or a new master plan. The standing four-biome goal and its
anti-grind rules still govern execution. The broader sweep is not complete.

The fresh critic inspected all 24 Cloudreach day/night frames under
`shots/catalogue/cloudreach/round-pylon-20260909T015726Z/` and the combined
116-frame set. Images remain local; committed identity receipts are in
`ralph/reports/FOUR-BIOME-BUILD/audit-resume/PYLON-CONTACT-SHEETS.md`.
The unmodified verdict is `REJUDGE-CLOUDREACH.md` in that directory:
key-art world **No**, recognizable creature-adventure intention **Yes**,
shipping-art readiness **No**. Intention is not a quality pass.

The location crosswalk and local/systemic, in-engine/art dispositions remain in
`VISUAL-TRIAGE-BASELINE.md` and `VISUAL-TRIAGE-REVERIFY.md`. This document supplies
the previously missing named Phase A artifact required by the owner sweep
directive; it does not convert its missing observations into acceptance.

## Supported strengths and internal references

These are five useful traits to protect, not five approved complete locations.
All filenames below are relative to the frame directory above.

| Reference | Trait supported by the blind review | Boundary |
|---|---|---|
| `cloudreach__broken_causeways__03__three_bells_bridge__day.png` | Bridge, trainer and distant spire communicate a route; direct shadows ground the subjects. | Preserve route readability and scale while other systems change. |
| `cloudreach__gate_lower_cliffs__01__realm_gate_crag__day.png` | Green upland, grey cliffs and blue sky make the region intelligible. | The corresponding night sky/local-value relationship fails. |
| `cloudreach__gate_lower_cliffs__02__galefoot_waycamp__day.png` | Huts, bed and camp ring communicate a stop; the bed and large companions have plausible relative scale. | Cast finish, overlap and HUD obstruction remain poor. |
| `cloudreach__windscar_ravine__06__windscar_flight_aerie__day.png` | The wolf silhouette is legible and visibly larger than the trainer. | Cropping and inconsistent white/blue surface treatment remain open. |
| `cloudreach__upper_cloudreach__10__old_wind_observatory__day.png` | The vista communicates altitude and large scale. | Banded cliffs and hard white cloud forms fail; protect the elevation reward, not those forms. |

The catalogue does not establish which grass patch is the biome's best, whether
grass motion works, or which aerial approach is strongest. Those owner-requested
internal references still need actual route evidence; none is invented here.

## Ranked weaknesses and next passes

All five rows are Beta-blocking visual P1 families. None establishes a new P0,
collision failure or progression dead end from still images. Screen impact below
describes the recorded view; frequency over a played chapter is unmeasured.

| Order | Observed problem and impact | Cause scope, ownership and next action | Acceptance |
|---|---|---|---|
| 1 | Galefoot and Flight Aerie companions have incompatible surface/palette treatments and lose silhouette space behind UI. This affects the game's focal subjects. | Shared cast/material and HUD presentation, plus species-specific art. Existing owners include `creature_body.gd`, `creatures_visual.json`, `shiny_colourways.json` and `playground_hud.gd`. Diagnose authored repaint/aspect/shiny paths separately; inspect installed source art before choosing a repair. Do not infer a missing texture or remove intentional glow globally. | Actual ordinary creature views, including populated HUD and night, retain clear silhouettes and coherent reference-aligned finish. A fresh blind review must verify every affected biome; anatomy/art residuals stay open if installed assets cannot supply them. |
| 2 | Old Wind Observatory's hard white cloud overlaps and repeated cliff bands dominate the vista; Cliffhold has angular pasted path edges. | Shared/regional environment derivations with a local path transition component: `cloudreach_look.gd`, `cloudreach_world.gd` and their environment data. Inspect the visible geometry/material paths first; this does not reopen parked profiling or vertex-sampling work. Installed forms/materials precede any art request. | Matched ordinary vista and traversal views preserve altitude and route legibility while removing the named hard overlaps/path seams. Judge the result in context, not a material swatch. |
| 3 | High Perches presents immense plain columns above largely empty ground; Sky Shrine's visible cylinder lacks a readable destination composition. | Local landmark construction within a broader architectural finish gap. Cloudreach world/chapter presentation builders own the scene portion. Verify actual approach and installed architectural inventory before replacing or dressing geometry. Monumental detail may require art absent from the build; availability is unproved. | The trainer, approach and destination are legible from ordinary angles; scale has intermediate construction detail. Preserve documented progression and the approved rustic-stone aviary identity at the stronghold. |
| 4 | Cliffhold's isolated bushes, repeated huts and fragmented paths fail to communicate a lived-in settlement. | Local composition using shared village/prop families. Existing placement/builders own connected approaches and purposeful clusters; no new NPC role or story is authorized. | A walked approach and occupied view explain the settlement's existing purpose and connect foreground, activity and destination. Increasing object count alone is not acceptance. |
| 5 | Realm Gate Crag and Sky Shrine nights have a bright distant sky against very dark local subjects. | Shared world lighting/material policies plus local focal lighting: `world_look.gd` and Cloudreach look/presentation. Separate intended night/glow from loss of subject readability. | Matched day/night views retain distinct night identity, readable trainer/companions and coherent sky-to-local values across affected biomes. No global brightness or emission shortcut. |

Windscar Beacon, Sky Shrine and Waterward Overlook also have obstructed
catalogue views. They need usable ordinary approach evidence before a claim
that the underlying landmark is absent, undersized or fundamentally wrong.
The separate supplemental summit pylon attempt produced **zero accepted
frames** and stopped after its approach descended below the target. Do not
repeat that approach or silently count it as stronghold evidence.

## What has been repaired and what must remain protected

The production capture rig/floor correction has already been applied and the
full catalogue recaptured. Installed pylon textures were bound at five missing
consumer files and both affected biomes recaptured. Independent review verifies
the visible Verge material in Stormwood; it does not visually close Cloudreach's
obscured pylon contexts or certify the full aviary. Preserve the binding repair,
existing interactions, authored scale and traversal geometry.

Do not flatten regional identity by copying Meadows everywhere, blanket the
biome with its densest grass, reduce creature scale, recolour friendly assets
into Team Tether oxblood, or spend beyond the already scoped art pilot.
The installed humanoid, nature, village and prop families remain the starting
point. Missing architectural detail or cast anatomy is an art requirement only
after the installed inventory is checked; a screenshot alone cannot prove
that suitable source art is unavailable.

## Performance evidence and remaining Phase A work

The post-pylon Cloudreach capture completed all 24 frames. Its receipt records
about 5.143 GB peak renderer private memory and 70.1575% peak system commit
(`PYLON-CAPTURE-VERIFIED.md`). This is host resource evidence, not frame pacing,
Ally performance or a measured benefit from an optimization. The earlier
allocation failure coincided with exhausted system commit and generated-file
Git diff fanout (`ALLOCATION-DIAGNOSIS.md`). Do not misclassify that as an
unproved ground-cover allocator defect or resume the parked performance lane.

Before declaring the full Phase A complete, obtain the missing ordinary
ground/air route and stronghold-interior context, best/ordinary/sparse grass
comparison, meaningful weather and motion evidence, and measured target-hardware
performance in its authorized phase. Compare the stronghold to the supplied
aviary board using an actually visible approach/interior. The existing catalogue
does not answer flying integration, animation, NPC activity, weather transitions
or the complete journey's exploration payoff.

The one-round scene-polish and no-yield limits in prompt 78 remain in force.
This ranking authorizes no repeated cosmetic round to change a recorded verdict.
Continue the earned player-path work and retain these families in
`SECOND_PASS_BACKLOG.md`; complete the broader sweep and product audit with
appropriate evidence before Stage D/E acceptance.

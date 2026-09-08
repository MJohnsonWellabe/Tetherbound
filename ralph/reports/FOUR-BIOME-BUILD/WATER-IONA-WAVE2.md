# Iona baked footing diagnosis — 2026-09-08

The completed Water continuous run earned Aquaryn's defeat and personal Swim
Stone, then hit its unchanged cumulative 20-minute watchdog before Iona's recipe.
It did not report an independent Iona leg timeout or terminal pose. An automatic
save at 17:06:29.043 UTC (118 seconds before terminal) recorded the grounded
player at (703.5404,45.9485,1541.1134), with Stone but no recipe.

The new diagnostic `tools/_probe_water_iona_baked_approach.gd` reads only the
existing `terrain3d_01_02.res` and `terrain3d_01_03.res` height maps. It builds a
50×50 m HeightMapShape3D collision patch and instantiates the actual Player scene
with an identity camera basis and ordinary stick navigator. It never loads the
full Water world, imports, rebakes, writes terrain/cache resources, loads a save,
or awards progression. Initial player placement is an explicitly isolated
diagnostic fixture, not a campaign movement or earned milestone.

Shipped baked heights confirm the source concern:

| Point | Baked height |
|---|---:|
| Saved player's X/Z | 45.89397 m |
| Iona current (691,1553) | 113.42292 m |
| Existing first stance (693.5,1553) | 113.52217 m |

Twenty intervals along the final approach sampled a maximum slope of **81.6407°**.
The actual Player floor limit is **45.0001°**. In the small collision patch the
actual Player/navigator could not reach Iona's original stance within the existing
1200-frame diagnostic bound: end (710.1142,46.0746,1547.163), grounded beside the
road, with terrain contacts and zero confined resets. This establishes a physical
footing blocker independently of the continuous run's cumulative deadline. The
patch does not reproduce the whole encounter, NPC dialogue or world clutter.

An initial purported road control at (710,1552) also failed: its baked height is
48.12826 m and it remains on the steep shoulder. It was an invalid positive
control, not a reason to relax traversal. The corrected control is the exact
authored p3→p4 road-center projection at z1550: (714.004,1550), baked46.36175 m.
Actual Player reached that target within unchanged1m tolerance, ending grounded
at (713.387,46.3037,1549.283), zero confined resets. Only this changed control was
run afterward; the failing original leg was not rerun. Both processes exited0
(diagnostic tools print observations, not campaign pass results). No ERROR,
SCRIPT ERROR or warnings appeared. Each used an isolated APPDATA profile.

Evidence: `.artifacts/iona-small-patch.log` and `.artifacts/iona-road-control.log`,
each with a unique engine log. The resource `location` metadata prints an unset
sentinel; spatial indexing uses the shipped region filename, configured512m
regions and1m vertex spacing, and sampled saved-position height agrees with the
recorded player footing. No region was modified.

Proposed minimal repair, pending root ownership: change only `water_iona`'s
`island_local_offset` in `data/config/water_characters.json` from[-9,0,23] to
[11.504,0,20]. This places Iona at(711.504,1550), baked46.27083m, beside the road.
Her unchanged +2.5m first interaction stance lands at the tested road center.
NPC0.36m and player0.4m capsules fit that stance without overlap. Keep her identity,
dialogue, personal rewards, prompt radius and the overall watchdog unchanged.
No production edit has been made at this report's creation. A lightweight
placement check can guard the proposed row; actual continuous Iona interaction
and recipe remain required before acceptance.

## Approved row repair and actual NPC patch validation

Root granted exclusive ownership of the single Iona row. The proposed offset
change is now implemented; the production diff contains only the two X/Z numbers.
No other character, story, flag, radius, terrain or watchdog changed.

The changed placement was then checked once with `--placed-only` on the same
lightweight shipped-height patch. This mode creates the actual Player, production
NPC body from Iona's current `field_researcher` model config, its normal prompt,
and the actual InteractionArbiter. The normal controller walks and presses
Interact; there is no dialogue/reward handler and no progression state created.

Result: **arrived=true, exact_provider=true, actual_interact=true**, exit0.
Actual Iona stood at(711.504,46.27083,1550), model height1.7m, capsule radius0.36m,
unchanged prompt radius3.8m. The first stance was(714.004,46.46175,1550); actual
player reached(713.5648,46.32091,1549.49) and activated Iona's exact provider.
No ERROR, SCRIPT ERROR or warnings. Evidence `.artifacts/iona-placed-patch.log`
and corresponding unique engine log, isolated profile `iona-placed-patch-profile`.
Original negative and changed positive are separate diagnostics; the original
blocked walk was not rerun. Full continuous Iona recipe remains unvalidated.

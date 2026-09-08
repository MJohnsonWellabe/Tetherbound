# Tidewake opening continuous diagnostic — prepared 2026-09-08

`tests/smoke_water_opening_continuous.gd` covers the previously uncomposed
production arrival -> Pell briefing -> physical swim lesson seam. It is prepared
and parser-checked, not runtime acceptance.

The isolated initial fixture is an empty solo Water realm with its production
arrival placement. It does not earn the preceding Stormwood ending or transfer
an actual campaign party. A unique test save directory is installed before reset.
Independent source review added an explicit grounded, within-3-metre check
against `world.entry_anchor("from_stormwood")`, so a default/stale spawn cannot
silently count as arrival coverage.
No actor pose, Water progression flag, material, HP or stamina is written by the
diagnostic after arrival. This is not full fresh-save campaign proof.

Pell's actual NPC row resolves to XZ `(53.368,151.502)`, four metres west of the
lesson's safe start; arrival is `(0,1.929,162)`. The diagnostic walks there with
the shared stick navigator, requires the real InteractionArbiter to emit the
Pell prompt as the activated provider, and advances the real DialoguePanel with
input until the personal briefing flag is earned. It then walks to the lesson's
west landing, swims its surface polyline and reaches the dry east landing. The
production host observer, not the harness, must award the world lesson flag.

Existing `smoke_water_scene_npcs.gd` posed proximity at Pell; existing
`smoke_water_swimming.gd` posed the player at the west safe anchor and later
injected exhaustion. Their focused claims remain valid, but neither establishes
ordinary arrival-to-lesson progression. This diagnostic contains neither pose
nor exhaustion injection. Failed movement must be diagnosed, not bypassed.

Validation so far: Godot 4.7 `--headless --path . --check-only --script
tests/smoke_water_opening_continuous.gd --log-file
C:/Users/mattj/AppData/Local/Temp/water-opening-check.log` exits 0 without errors.
Full-world runtime is queued behind the active late Tidewake run and Stormwood
playable-path checks. No physical reachability or chapter completion is claimed.

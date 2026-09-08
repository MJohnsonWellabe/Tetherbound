# Tidewake opening continuous diagnostic — prepared 2026-09-08

`tests/smoke_water_opening_continuous.gd` covers the previously uncomposed
production arrival -> Pell briefing -> physical swim lesson seam. That bounded
production route has passed at runtime.

The default and Reedhaven-only initial fixture is an empty solo Water realm with
its production arrival placement. It does not earn the preceding Stormwood
ending or transfer an actual campaign party. The optional Brine composition's
synthetic party is disclosed below. A unique test save directory is installed before reset.
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

Godot 4.7 `--headless --path . --check-only --script
tests/smoke_water_opening_continuous.gd --log-file
C:/Users/mattj/AppData/Local/Temp/water-opening-check.log` exits 0 without errors.
The corrected composed runtime also passed production arrival, real Pell
dialogue and 64.487m of observed lesson swimming. No full chapter completion is
claimed.

## Optional composed Reedhaven continuation

`-- --through-reedhaven` continues the same player from the earned lesson-east
landing through the sheltered human crossing, four named resource nodes and
the material-consuming Reedhaven repair. Its sole extra initial fixture is
one knife, one axe and their hotbar assignments **before world creation/arrival**,
representing tools carried from the completed prior chapter rather than Water
supplies. No later fixture writes occur.
The helper requires the earned lesson and verifies exact six-reed/six-drift
gathering and six-reed/four-drift repair payment. It does not substitute a
previously repaired dock or grant materials. A focused verdict test passes
2 tests/16 assertions independently, including exact live ItemDB tool matching.
The first composed run proved arrival, Pell, 64.488m of lesson swimming and the
human crossing to Reedhaven, then exposed stale `hand` metadata on the first reed
node; production correctly requires a knife. The fixture/helper now carry and
equip the prior chapter's knife without weakening that gate.

The corrected composed run passed the ordinary crossing, all four exact named
controller harvests, exact six-reed/six-drift yield, and the paid Reedhaven
repair with `ok: true`, `failures: []`. The log has no `ERROR` or `SCRIPT ERROR`:
`%TEMP%/water-opening-reedhaven-corrected.log`. This remains a bounded Water
entry fixture, not proof that Stormwood completion supplied the party/tools.

## Optional composed Brine continuation

`-- --through-brine` includes the entire proven Reedhaven continuation, then
drives `tests/helpers/water_brine_segment.gd` from the paid dock across the
authored 107.088m human route to Tovin's real challenge. Its additional
pre-arrival fixture is exactly the existing Stormwood continuous diagnostic's
five species -- Sparkit, Mudsnout, Bramblebun, Terrapup and Brooktail -- each at
level 44. It is explicitly a synthetic carried party, not an earned Stormwood
save or proof of chapter continuity. The fixture adds no Water progress,
materials, HP, stamina or actor pose, and never changes the party after the
production world starts.

The default and `--through-reedhaven` modes remain party-empty and unchanged.
A focused argument test makes `--through-brine` imply Reedhaven while preserving
both shorter selections.

The repaired Brine composition passed exit 0 in one production process:
`%TEMP%/water-opening-brine-tovin-repaired.log`. It re-earned Pell's lesson,
the four Reedhaven harvests and paid repair, then completed the 107.088 m human
crossing, full graded p1-through-p5 approach, both authored Tovin opponents and
the durable defeat/trial flags. The surviving active creature retained
`294.5 / 358` HP. Each helper returned `ok: true` with no failures; native
`ERROR` / `SCRIPT ERROR` scan was clean. The only warnings were the separately
owned Brine ordinary ecology sites `_010/_011`.

This closes the bounded Water opening-through-Tovin route. It does not upgrade
the disclosed synthetic carried party into proof of the earned Stormwood save
handoff.

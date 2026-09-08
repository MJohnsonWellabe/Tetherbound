# Water wave 1: continuous Shellwatch and Tidal recipe diagnostic

2026-09-08, `codex/four-biome-wave1`, based on landed main
`75aaccca0210a9bc1ac0f16bac687d8557f0aacf`.

## Evidence boundary

This is chapter-entry diagnostic work. The opening still discloses its synthetic
carried level-44 party (`sparkit`, `mudsnout`, `bramblebun`, `terrapup`, `brooktail`)
and knife/axe before arrival. Those are not an earned Stormwood handoff.
There are no new post-arrival pose, inventory, HP, party, or progression grants.

The existing `--through-shellwatch` composition remains one world from arrival,
Pell, the swimming lesson, paid Reedhaven repair and Tovin through Shellwatch.
The first continuous attempt reached Tovin, then stopped at the Shellwatch
precondition described below; focused loading is not traversal acceptance.

## Prepared next bounded composition

`--through-tidal-recipe` includes the earlier segments unchanged, then uses
`tests/helpers/water_tidal_segment.gd` on that same live world. It requires the
earned combined Shellwatch gate and an uncompleted Aquaryn/Stone/recipe state.
It follows the authored 112.113m sheltered human crossing, Tidal spine points
1–3, the actual camp's creature-bed/rest controller flow, Aquaryn's own challenge
provider and real quick-attack input, then Iona's actual recipe dialogue.

The helper stops at Alpha defeat, personal Swim Stone and recipe. It preserves
the five carried creature identities and does not claim a capture, saddle craft,
mounted crossing or chapter ending. The actual route and fight remain unverified.
The existing 20-minute composed-opening watchdog is unchanged.

The next unresolved requirements are ordinary harvest of 8 reed fiber, 6 driftwood
and 4 reefstone for the real saddle recipe, plus an earned compatible mount. None
of this fixture's five is an explicit Water swimmer: the Water catalogue lists
Aquaryn, Mosshell, Sirenseal, Riverdrake and Cannonback. Brooktail's Water typing
does not make it a compatible swim mount. Any mounted continuation must therefore
prove ordinary capture and the five-slot release ceremony, or consume a genuinely
earned compatible party supplied by the earlier campaign. The synthetic owned
level-60 Aquaryn in the independent late-route smoke does not satisfy this seam.

## Focused verification

Command: Godot 4.7 console, `--headless --path . --script tests/run_tests.gd --
--only=test_water_tidal_segment.gd,test_water_opening_continuous_args.gd,test_water_shellwatch_segment.gd`,
with unique `--log-file`.

Initial result: **5 tests, 40 assertions, 0 failed**, exit 0. Shorter default, Reedhaven,
Brine and Shellwatch flag behavior remains covered. The new route contracts reject
the wrong preceding gate and a mounted-traversal substitution. An unrun or failed
helper cannot report success. Log: `.artifacts/wave1-water-composition-focused.log`.

## Save isolation

Before constructing the world, the opening binds a unique test-owned SAVE root,
checks it survived `reset_for_new_game`, and prints the resolved absolute path.
The queued Windows launcher additionally redirects APPDATA to a unique test
profile and fingerprints owner `saves/`, `worlds/` and `characters/` before and
after execution. No owner save is loaded to advance the chapter.

## First continuous runtime and exact first failure

The first `--through-shellwatch` run exited **1**. The isolated APPDATA profile
was `.artifacts/wave1-water-shellwatch-profile`, with printed SAVE binding
`.../Godot/app_userdata/Tetherbound/water_opening_continuous_4068154/`.
Owner saves/worlds/characters content fingerprints were unchanged; the engine
terminated. Logs: `.artifacts/wave1-water-shellwatch.log` and
`.artifacts/wave1-water-shellwatch-engine.log`.

In one live world it earned Pell's actual dialogue, **64.487m** physical swimming
lesson, the ordinary Reedhaven crossing, four harvest receipts yielding 6 reed
fiber and 6 driftwood, paid the **6 reed + 4 driftwood** repair, swam the authored
**107.088m** Brine crossing, and won Tovin's two production opponents. It observed
the durable Tovin victory and Brine trial flags, with the active ally at
**65.1/315.0 HP**. Brine result had `ok: true`, `failures: []`.

The first new failure was **`production Solm team contract is absent`**, before
any Shellwatch movement. This was a harness schema error: the director's
`WaterEncounterRuntimeData.build()` translates authored `mirejaw`,
`mangrove_monitor`, `riptusk`, `cannonback` to the corresponding `water_` runtime
species, but the helper compared its live trainer specifications with raw board
IDs. The two live comparisons now require the exact namespaced species. Authored
species, team sizes, levels, prerequisites and gameplay remain unchanged.

A new focused regression calls the actual production translator and demonstrates
that the old raw-ID comparison fails, the runtime-ID comparison passes, and a
wrong level remains rejected. An initial test declaration needed an explicit
Dictionary type; after correction, final focused evidence is **6 tests,
45 assertions, 0 failed**, exit 0, in `.artifacts/wave1-water-namespace-final.log`.
The repaired continuous run is queued; neither Shellwatch nor Tidal is accepted.

No native `ERROR:` or `SCRIPT ERROR:` appeared in the continuous run. Terrain
missing-mipmap warnings and the already-recorded Brine ordinary010/011 unsupported
spawn-site warnings remain; they are not silently counted as clean output.

Repaired namespace runtime completed once, exit 1; owner saves fingerprints
unchanged and no Godot process remained. Opening, four harvest receipts and paid
6 reed/4 drift repair passed again. The 107.088 m Brine crossing and Tovin's two
opponents earned both durable flags, with the active ally at 293.9/358.0 HP.
The corrected live team contracts passed. The continuous party physically crossed
93.320 m to Shellwatch and completed ordinary bed rest to day 2. First new failure:
`Shellwatch camp did not redeploy the recovered creature before Solm`.
Logs: `.artifacts/wave1-water-shellwatch-repaired.log` and corresponding engine
log; owner fingerprints `.artifacts/wave1-water-repaired-owner-{before,after}.json`.
No native ERROR or SCRIPT ERROR; existing mipmap and unsupported Brine spawn-site
warnings remain. Solm, Irva, release, pump and Tidal are still unaccepted.

Source diagnosis: `Party.set_resting(true)` cycles away from the bedded active
member. Completing the night heals and unbeds it but does not restore selection.
The helper previously pressed recall and required the old member's identity,
although production would summon the newly selected member. The helper now counts
ordinary party-cycle presses needed to reselect the retained recovered member,
verifies that selection, then summons once. It rejects unavailable/nonparty
members and keeps the exact identity/HP/day requirements. No gameplay writes,
retries or deadline changes. Focused real-Party regression reproduces automatic
selection change, proves unbedding leaves it changed, skips a fainted member and
restores the correct identity through production cycling. All Water focused tests:
7 tests, 56 assertions, 0 failed, `.artifacts/water-camp-selection-unit.log`.
This second repair has not yet had a full-world runtime; RAM returned to root.

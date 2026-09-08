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

Camp-selection repair runtime (`--through-tidal-recipe`) completed once, exit 1.
Fresh isolated profile and owner fingerprints were checked; owner saves remained
unchanged and all Godot processes were gone at terminal. The ordinary opening
lesson covered 64.491 m. Paid Reedhaven and 107.088 m Brine crossing passed;
Tovin's two opponents and durable flags were earned with ally HP 318.3/358.0.
The 93.320 m Shellwatch crossing passed. Ordinary rest advanced to day 2 and
`Shellwatch camp recovered active creature before Solm` proved the repaired
controller selection/redeployment with the retained member.

First new failure was physical approach, before the Solm challenge:
`water_trainer_solm challenge stance 0 walk failed: player=(335.8195, 58.26273, 1076.823) target=(342.0, 62.58215, 1090.0) resets=0`.
No Solm victory, Shellwatch release/pump or Tidal recipe is claimed. No ERROR or
SCRIPT ERROR in output/engine logs; existing terrain mipmap and unsupported Brine
spawn warnings remain. Evidence `.artifacts/wave1-water-camp-tidal.log` and
`.artifacts/wave1-water-camp-tidal-engine.log`; owner hashes in
`.artifacts/wave1-water-camp-tidal-owner-before.json` and `-after.json`.
RAM released to root. No rerun or new stage added following this first failure.

Solm approach diagnosis/fix (runtime pending): the original direct diagonal from
spine p2 (267.004,1006.349) to challenge stance (342,1090) crosses the radial
landing-sector flank. Quarter-metre samples of the production Water heightfield
show maximum ground slope 63.07 degrees, above the player's 45-degree floor angle.
A shorter candidate at z1094 still measured 47.47 degrees and was rejected. The
selected ordinary path goes via (315,1104) and (342,1104), then the unchanged stance;
maximum sampled slope is 39.85 degrees. The same waypoints are followed in reverse
after Solm before returning to spine p2. No production terrain/placement change,
teleport, radius/ceiling increase, skipped challenge or retry was added.

Focused regression uses the actual authored spine and production heightfield:
old diagonal fails the walkable slope criterion, selected path passes. This is
analytic support, not proof of baked collider traversal or combat acceptance.
8 Water tests / 58 assertions / 0 failures in `.artifacts/water-solm-path-unit.log`.
Probe evidence `.artifacts/solm-route-height.log` and `solm-route-height2.log`.
Full-world validation remains queued under root's RAM allocation.

Solm-detour runtime completed once with `--through-tidal-recipe`, exit 1 overall.
**Opening through Shellwatch passed in one continuous world.** Solm's actual team
was water_mirejaw + water_mangrove_monitor; surviving ally HP 55.0/340.1. Ordinary
return and resident-release interaction earned water_shellwatch_residents_freed.
Camp rest advanced to day 3 and redeployed the recovered retained member. Irva's
actual water_riptusk + water_cannonback team was defeated; ally HP 166.1/329.4.
The ordinary pump action earned water_shellwatch_pump_disabled, and the combined
gate plus actual departure barrier removal were verified. Shellwatch result:
`ok: true, failures: []`. This runtime validates the changed Solm detour on baked
terrain and the retained stronger victory/party/progression assertions.

The same live run crossed 112.113 m to Tidal and completed ordinary camp recovery
to day 4. First new failure was `Tidal basin spine point 3 walk failed:
player=(602.7661, 34.06974, 1392.609) target=(601.574, 33.934, 1389.434) resets=0`.
Aquaryn and Iona's recipe remain unproven. Owner save fingerprints unchanged;
no Godot processes remained. No ERROR or SCRIPT ERROR, with previously disclosed
terrain/Brine warnings. Evidence `.artifacts/wave1-water-solm-detour.log` and
`wave1-water-solm-detour-engine.log`; isolated profile and before/after owner
fingerprints share that prefix. RAM released; no unchanged-code rerun performed.
The chapter's synthetic carried party/tools remain disclosed; this does not claim
an earned fresh Stormwood-to-Water handoff.

Tidal point-3 diagnosis: `water_alpha.json` placement.spawn is exactly
[601.574,1389.434], the failed waypoint. `water_alpha.build()` places the real
colliding Aquaryn at that center; its peaceful tick requests zero movement.
The helper therefore demanded entering an occupied creature center before
requesting its challenge. No terrain slope assumption is needed to establish
that invalid destination. The final 3.39 m stopping distance alone does not prove
which slide contact/navigation choice was last; no runtime contact trace exists.

The helper now follows spine point 2, then approaches the actual live Alpha
from its near side, outside Aquaryn's body_radius() plus the player's actual
CapsuleShape3D radius plus the unchanged 1 m precise-walk tolerance. It grounds
that target and fails if it lies outside the unchanged production prompt radius.
It requires the exact Aquaryn provider to win and receive the controller press;
no challenge direct-call, fallback/grant, radius expansion or retry. Existing
level-49 fight, real defeat and personal Stone assertions remain unchanged.

Focused regression verifies the authored waypoint equals the occupied spawn,
near-side capsule clearance and unchanged prompt eligibility. Current production
Aquaryn radius is 1.6652163 m, player 0.4 m, derived target distance 3.0652235 m.
An initial negative assertion incorrectly claimed the old generic 2.5 m center
itself overlaps; corrected evidence is its 1 m arrival-tolerance near edge can
overlap (1.5 m < 2.0652163 m). Initial focused run 9 tests/64 assertions/1 failed;
final 9 tests/64 assertions/0 failed, `.artifacts/water-alpha-stance-final.log`,
no native or script errors. The occupied-center diagnosis is independent of that
corrected secondary tolerance assertion. Full-world validation remains queued.

Post-Iona bounded preparation: new `water_earned_swimmer_segment.gd` reuses the
real physical weakening/throw and five-slot farewell implementation through a
small default-Meadows `_replacement_realm()` seam (root approved). Water overrides
the collector because SequenceDirector/starter/name-picker dependencies are not
present in Water; it binds live CombatManager/ThrowAim signals instead. Caller
must supply the exact already-engaged compatible ordinary wild, full five belt,
earned Stone+recipe and carried pickaxe. Actual pending newcomer, unchanged belt
before farewell, default Keep, outgoing identity, other four identities and
appended caught identity remain checked by the inherited production-UI ceremony.

After successful capture/farewell, its separate paid-craft method requires actual
earned affordable materials, walks to the real Tidal camp workbench, selects the
actual recipe row through controller input, and verifies the exact current
production cost decrement plus one saddle. It does not directly call craft,
create resources, equip a saddle or claim mounted travel. No caller is wired yet;
ordinary target selection/engagement and material acquisition remain to compose.

Verified current saddle data: 8 reed_fiber, 6 driftwood, 4 reef_stone; both personal
Stone and recipe flags. ItemDB loads these registrations despite stale proposal
metadata. Runtime-compatible swimmers are water_aquaryn, water_mosshell,
water_sirenseal, water_riverdrake and water_cannonback; Brooktail is not compatible.
Tidal land table offers Mosshell/Riverdrake plus noncompatible Cragclaw at 47–49;
an authored table is not a guaranteed particular live spawn. Actual greater-orb
pickups exist at Tidal pickup004 (586,1758) and earlier Shellwatch pickup002/019;
no orb grants or respawn rerolls are part of this helper.

Tidal harvest supply candidates: reed001/008/010 yield3 each; drift009/012 yield3;
reef005/006 yield2 each. These IDs/coordinates are authored, not walked evidence.
Reef uses ItemDB's real pickaxe gate; water_pickups supplies no pickaxe/stone
pickup. Current chapter diagnostic carries only knife+axe and must stop at this
tool gap. Genuine fresh village earns the pickaxe; the synthetic tool gap is not
a whole-goal blocker and will not be patched with a grant. Base pickaxe crafting
costs 3wood4stone2fiber, so assuming reef can bootstrap its own pickaxe is invalid.

Focused new adapter/catalogue/cost plus existing real-Party receipt tests:
4 tests,35 assertions,0 failed (`.artifacts/water-earned-swimmer-unit.log`).
Adapter/world/throw/UI integration is unvalidated; no mounted suffix acceptance.

Changed Aquaryn stance runtime (wave2) completed once: terminal exit 1, owner
fingerprints unchanged, no remaining Godot processes. Opening/Pell/64.487 m lesson,
paid Reedhaven, Brine and complete Shellwatch all passed on the same live state.
Tovin survivor HP288.1/358.0; Solm29.6/340.1; Irva195.3/329.4. The Tidal112.113 m
human crossing and day4 camp recovery passed. The new outside-capsule stance won
and activated the exact production Aquaryn challenge. **Real Aquaryn defeat
then earned world completion and the personal Swim Stone.** Thus the changed
approach and authoritative Alpha combat/reward milestone have runtime evidence.

First failure: `Opening watchdog expired (20 minutes with Reedhaven; 10 minutes
lesson-only)` during the post-defeat Iona approach. The log did not record a final
Iona approach pose; it does not prove a specific obstruction or a recipe result.
Iona's recipe, paid saddle and capture/farewell remain unaccepted. The existing
watchdog was not raised and this is not reported as a full continuation pass.
No ERROR or SCRIPT ERROR in engine/output. Previously disclosed terrain/Brine
warnings and one `strike_intent refused: cooldown` remain recorded.
Logs: `.artifacts/wave2-water-aquaryn-stance.log` and corresponding `-engine.log`.
Profile and owner before/after fingerprint files share that prefix. RAM released
to the authorized Alpha lane; no second Water run launched.

Read-only post-watchdog Iona audit (no world run/code change): output/engine files
were created16:47:31UTC and last written17:08:27UTC on2026-09-08. Boot log records
local11:47:35. Individual milestone lines contain no timestamps, so exact Alpha
completion/Iona-start durations are unavailable. The20-minute SceneTree timer is
a cumulative whole-path deadline; the log has no independent Iona walk failure.

The isolated automatic save supplies an earlier real pose: slot_0.json written
17:06:29.043UTC, about118 seconds before terminal, contains world Aquaryn completion
and personal Swim Stone but no recipe. Grounded player position was
(703.5404053,45.9484711,1541.1134033), velocity(0.5824291,0,0.6961185). This is
an autosave observation, not a final failure pose; no save was loaded or changed.

Source places Iona at(691,1553), island center(700,1530)+offset(-9,23), grounded
to baked terrain. The first helper stance is(693.5,1553). Her0.36m capsule plus
player0.4m radius fits outside that2.5m stance, unlike the occupied Alpha-center
bug. There is a concrete terrain concern: nearest authored spine point to the
saved player has height45.5197m and is3.4741m away. Iona is20.5645m from the spine,
first stance18.5166m, outside the configured3m flat+15m feather grading extent.
The production radial formula gives Iona113.4229m and stance113.5228m, versus
nearest spine45.6810/45.7719m. This indicates a roughly67m shoulder climb between
the graded road and Iona's ungraded summit location. These are source calculations,
not a new baked-height/contact measurement; no precise final obstruction is claimed.

Next bounded diagnostic proposal: under a future RAM grant, inspect actual baked
heights and normals along the saved-pose-to-Iona-stance leg and the NPC's live
capsule/prompt geometry, without moving progression or claiming a recipe. If the
baked shoulder confirms source geometry, coordinate a reachable Iona placement
or physically supported authored approach before another continuous run. Do not
raise the20-minute timer or reload this save to advance. All Water source remains
frozen; achieved Stone/no-Iona boundary unchanged.

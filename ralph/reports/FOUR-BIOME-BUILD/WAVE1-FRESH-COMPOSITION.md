# Wave 1: earned-state campaign composition

Base main: `75aaccca0210a9bc1ac0f16bac687d8557f0aacf`, verified by its own
push CI `34231941105` (27 successful jobs / two conditional skips, attempt 1).

## First genuine opening prefix — 2026-09-08

`tests/smoke_four_biome_continuous.gd -- --through-opening` completed its first
runtime invocation in 111.822 seconds, exit 0, failures empty. The report says
`campaign_complete:false`; no later biome is credited.

The run starts at the production title with a unique empty scratch SaveGame
bound before title input. Production New Game, character choice, Get Up,
Grandpa dialogue, starter choice and naming, the first-catch supply dialogue,
ordinary walking, piloted creature attacks and physical orb throws all execute.
Grandpa supplies 50 Basic Orbs; actual attacks weaken the Bramblebun to 26/106
HP, and the real catch leaves exactly two party members with locomotion restored.

The old `gate_a_opening_drive.gd` catch deliberately drains inventory, pins both
combatants' HP and revives the ally on retry. Those are valid disclosed fixture
choices for its older smoke, but disqualify it from this goal. New
`tests/helpers/fresh_opening_segment.gd` replaces that catch path with input-only
attempts. Forbidden fixture seams fail closed. No production gameplay changed.
Independent review found no reachable HP/inventory/progression/pose shortcut.

Logs, local only:

- `.artifacts/wave1-fresh-opening.log`
- `.artifacts/wave1-fresh-opening-engine.log`
- `.artifacts/wave1-fresh-owner-before.json` and `-after.json`

Both logs have no native ERROR or SCRIPT ERROR. The process exited; the owner's
save/world/character file fingerprints are unchanged. APPDATA was isolated to
`.artifacts/wave1-fresh-opening-profile`; actual scratch slot was
`user://four_biome_fresh_24796_1251/slot_0.json`. No copied save was loaded.

Reproduce with the locked Godot executable, headless, a fresh isolated APPDATA,
unique engine log, and the script/flag above. The retained local launcher is
`.artifacts/run-wave1-fresh-opening.ps1`; it fingerprints owner files before and
after. Do not reuse a prior profile as fresh evidence.

## Next composition boundary

The driver also prepares ordinary key pickup, key consumption by the live
village gate, and the existing input-driven village tools/gather segment.
`--through-village` is prepared and parser-green, not runtime-proven. Default
execution fails explicitly at the missing suffix instead of claiming campaign
completion. A reusable `catch_existing` supports already engaged wild catches
below five members without fixture changes; its general team-building context
is not yet proven by the tutorial-only result.

Meadows earned team preparation, camp/tournament and the later chapter remain
uncomposed. Cloudreach, Stormwood and Tidewake lanes are preparing live-context
continuations. Existing synthetic chapter starts never count as the final
fresh opening-to-Tidewake-ending deliverable.

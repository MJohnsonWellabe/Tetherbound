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

## Expanded prefix: first failure, 2026-09-08 14:19 UTC

The first `--through-village` attempt exited 1 after 122.540 seconds, before
the village. It used a new isolated profile and scratch slot
`user://four_biome_fresh_9728_1219/slot_0.json`; owner fingerprints remained
unchanged. Evidence is `.artifacts/wave1-fresh-village.log` and its engine log.

The approach accepted `Engage Mudsnout` although the retained `_wild` handle
was the tutorial Bramblebun. The parent helper checked only the shared
EncounterDirector provider and its actionable offer. Combat HP readings then
came from the admitted Mudsnout (30/117 at the catch boundary), while camera
aim continued following the Bramblebun. One actual physical strike named
`Wild_mudsnout_1070_2`; later reticle-outside-body searches ended in a real
loss. The parent's Bramblebun checkpoint labels were hard-coded and do not
identify the opponent. This is a split-target harness defect, not evidence
that catch probabilities or combat balance need loosening.

The fresh helper now requires the exact `_engageable()` body before input,
verifies `enemy_body()` identity after admission, and applies the same
precondition at public `catch_existing` entry. No state correction, additional
retry, HP change, or limit change was made. Parser check passes; the changed
expanded prefix awaits its serialized runtime slot. The failed attempt is
retained and has not been rerun unchanged.

Earned team, catalogue-derived material gathering and paid camp construction
helpers are prepared locally. Camp source review found and corrected inherited
Free Build acceptance, a direct hotbar-assignment fallback, and an obsolete
objective ID. Construction now requires exact pre-press resource spending and
a durable `paid` building record. These helpers are not runtime-proven and do
not yet complete care, the tournament, or the full Meadows chapter.

## Corrected fresh village prefix: PASS

The changed target-specific `--through-village` run completed in172.968 seconds,
exit0, failures[]. It selected and admitted the same live Bramblebun, naturally
weakened it to28/106HP, landed a physical throw, and resumed exploration with
two creatures. The ordinary key pickup/gate consumed the key at116.31seconds.
Mira, Tam and the Foreman supplied the real tools through dialogue; the Satchel
assigned four tools through focused input. Actual equipped swings credited
4wood,4stone,4fiber. Oskar/Bram modal visits returned movement as well.

Evidence: `.artifacts/wave1-fresh-village-target.log` and
`-engine.log`, both without native ERROR or SCRIPT ERROR. Isolated scratch:
`user://four_biome_fresh_17504_1770/slot_0.json`. The launcher exited with the
owner fingerprints unchanged and no remaining Godot process. The earlier
failed run is retained; this was the first execution of the target-specific
fix. Focused identity regression:2tests/6assertions,0failed, including a different
body of the same species and an absent admitted body. An earlier local test
invocation mistakenly used unsupported `--filter`; that unintended broad run
was stopped and is not counted as validation. The correct invocation used
`--only=fresh_opening_target` and its own log.

The driver now composes prepared earned-team, catalogue-cost gathering, paid
camp, real sleep/Satchel care, and real marshal/bracket helpers behind explicit
prefix flags. They parse but have not run in the fresh composition. The default
still fails at the missing Meadows departure suffix and always reports
`campaign_complete:false`. No full chapter or four-biome completion is claimed.

## First earned-team execution: partial progress, navigation failure

The first `--through-team` execution exited 1 after 519.745 seconds. It earned
the actual five-member roster through physical catches: Ripplet, three
Bramblebun, and Mudsnout. Six ordinary wild victories credited XP and levels
to those same five identities. The run then failed with `Ordinary movement
did not reach the practice-meadow wild`; the team had not reached the required
training level. No training completion, camp, tournament, or chapter pass is
claimed. This is the first execution of the expanded team path, not a rerun
of an unchanged failed attempt.

Evidence: `.artifacts/wave1-fresh-team.log` and `-engine.log`, with no native
ERROR or SCRIPT ERROR. Scratch: `user://four_biome_fresh_8804_1743`.
The launcher confirmed owner saves unchanged; its unique manifests are
`.artifacts/wave1-fresh-team-owner-before.json` and `-after.json`.
The failed log lacks selected-target and geometry telemetry, so no specific
obstacle is proven. Source review found the selector weighted low levels over
distance while production offers the nearest living wild. The changed selector
prefers a currently offered eligible creature, otherwise the nearest eligible
candidate. It preserves the existing species/level/radius limits, 3,600-frame
watchdog and exact pre/post-admission identity. Added approach receipts expose
target, offer, positions, minimum distance, input owner and slide colliders.
Focused tests pass: 8 tests / 56 assertions, in
`%TEMP%/meadows-earned-team-selection-tests-20260908.log`. Runtime resolution
is still pending; no unchanged failed run was repeated.

The prepared driver now includes the
earned South Bridge segment; its composed parser check passed in
`.artifacts/wave1-bridge-composition-parse.log`. The default still explicitly
fails at the missing suffix and cannot report campaign completion.

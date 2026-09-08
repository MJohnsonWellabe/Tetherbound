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

## Earned full-belt replacement seam prepared

`tests/helpers/earned_roster_replacement_segment.gd` takes an already-engaged
actual wild, the current five-member party and an explicit outgoing index.
It reuses physical weakening/throws, requires the production pending catch to
be the exact caught instance while the belt remains unchanged, waits for the
automatic ceremony, and drives row choice, Keep/Let them go confirmation,
goodbye and menu exit through focused input. No `pending_catch` assignment,
party mutation, direct focus placement or ceremony callback is used.

The receipt checks all retained identities in production order: removal shifts
the remaining four and the caught newcomer is appended. Actual Party and
negative receipt tests pass: 2 tests / 21 assertions, zero failures, in
`.artifacts/wave1-earned-replacement-unit.log`; the helper parser passes in
`.artifacts/wave1-earned-replacement-parse.log`. This is prepared source, not
an earned Meadowhart capture or a live ceremony verdict. It is not yet wired
into the continuous route. The departure audit explains why the current
Ripplet/three-Bramblebun/Mudsnout roster needs an earned rideable replacement.

Independent UI/source review found no blocking focus, admission-identity or
fixture issue. It identified that the inherited tutorial weakening gate used
a fixed 4 m input distance. This new Meadows-only helper now asks the actual
`CombatManager.combat_move_reach("quick")` rule; the existing 1,800-step limit,
28% HP threshold and 35-step attack cadence remain unchanged. It does not
change the previously verified opening helper. The final helper parser check
is `.artifacts/wave1-earned-replacement-reach-parse.log`. No larger-body runtime
failure is inferred from this source finding and no live replacement is claimed.

## Expanded camp attempt: inherited key walk failed

The first `--through-camp` execution with changed training selection exited 1
after 144.996 seconds. The fresh opening physically caught its Bramblebun at
101.50 seconds (21/106 HP before the real throw), then the inherited straight
key walk exhausted its unchanged 2,600-frame limit. It never reached village,
the changed team selector, or camp; none is validated by this attempt.

Evidence: `.artifacts/wave1-fresh-camp-selected.log` and `-engine.log`.
Scratch `user://four_biome_fresh_9904_1798`; unique owner before/after manifests
under the same evidence prefix compare unchanged. The only ERROR is the
explicit key-walk harness failure; no remaining Godot process after terminal.
The stack identifies `_walk_toward` exhaustion, not a failed key interaction.
It does not identify a particular obstacle because the old helper omitted
position and collider telemetry.

The fresh key and gate path now uses the existing obstacle-aware stick
navigator under the same 2,600-frame and 2 m criteria, and requires the exact
enabled/actionable target offer before pressing. Start/failure diagnostics
record positions, closest approach, provider, offer and slide colliders.
Focused identity/offer tests pass: 3 tests / 10 assertions, zero failures,
`.artifacts/wave1-key-enabled-unit.log`. Runtime remains queued; the failing
code was not rerun unchanged.

The earned Warrens segment is now composed after South Bridge behind
`--through-warrens`: current seven quarry rootstone nodes, actual cave markers
and ungated passages, exact guardian victory/item/XP receipts, and walking out
with the same five. Its focused tests pass 8 / 82; no world execution is claimed.
The complete changed driver parses in
`.artifacts/wave1-key-warrens-composition-parse.log`. The default still fails
at its missing later Meadows suffix and reports `campaign_complete:false`.

## 2026-09-08 15:56 UTC — changed key approach proved; team route still blocked

Fresh scratch `user://four_biome_fresh_29284_1784`, current head
`0a91f9b39aa552e554b849b4eb57d8011e2c7589`, through-camp request:
actual opening catch at 104.57 s, key acquisition/consumption at 111.73 s,
village tools and gathers, then all five actual catches (Ripplet level 3,
Bramblebun 2, Mudsnout 4, Bramblebun 2, Bramblebun 2). One carried small potion
restored the selected Bramblebun from 46.467 to 81.467 HP; two remained. One
real Mudsnout victory granted actual shared XP. The next 3600-frame approach
stopped 24.914 m from Wild_mudsnout_1_2: player (-37.72714, 2.680571, 4.499945),
target (-54.17064, 5.498205, 23.00343), terrain collisions, no modal input owner.

Terminal exit 1 at 293.92 s. Owner fingerprint files match, no native ERROR or
SCRIPT ERROR lines. Logs `.artifacts/wave1-fresh-key-nav-camp{,-engine}.log`;
fingerprint files share that stem with `-owner-before.json` / `-owner-after.json`.
No camp completion, all-five level-5 training or uninterrupted ending is claimed.
The key navigation repair has actual fresh-path evidence. This second team
approach failure changes strategy to a bounded geometry/source diagnostic;
there is no third blind prefix, larger movement ceiling or skipped encounter.

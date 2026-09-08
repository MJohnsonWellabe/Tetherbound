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

## Prepared earned Cloudreach-to-Stormwood handoff (runtime unproved)

`tests/helpers/earned_stormward_handoff.gd` accepts the completed live Cloudreach
segment, requires its retained five identities and actual earned Stormwood key,
walks the existing route graph back to the overlook, then follows the actual
ScarredStep collision bodies to StormwardRealmGate. Two physical Interact inputs
must each activate that exact provider: the first earns the durable unlock while
retaining the chapter entitlement, the second lets production realm travel run.
It awaits the actual Stormwood scene, completed shell, cleared pending entry and
released input ownership under the existing 7200-frame scene bound, then checks
the same five instance identities. It never calls the router, loads a save,
assigns a player pose or writes progression. It is not yet wired after the
unfinished Meadows suffix and has no runtime proof. Parser passed; logs
`.artifacts/wave1-stormward-handoff-parse{,-engine}.log`.

Independent review caught that the first handoff draft could stop on stair21
up to0.75m early, outside the real prompt's4m radius. The revised walk reaches
stair22 with0.35m waypoint precision and stops before the gate-centred final
stair/barrier. It also waits for the actual Stormwood EncounterDirector's
population-ready state. Revised parser passed without errors; log stem
`.artifacts/wave1-stormward-handoff-reviewed-parse`. No runtime claim.

### 2026-09-08 16:39 UTC — verified wave1 landing, wave2 continuation

PR85 exact head19d6ea8ecbc44ea479d5e49514359f6c116ba199 was marked ready and
squash-merged as main bc26b21eec2b96a8fbd8295732007aa67f92198a after complete
first-attempt CI34248963300 review (26 successful jobs, three existing conditional
skips, 2980 tests/486685 assertions). PR comments were empty. Fetch confirmed the
main tree is identical to the verified head and contains prior main75aaccca0.
Main's OWN push CI34252353122 and Release34252353246 are now running; this entry
DOES NOT claim their success. Shared checkout is codex/four-biome-wave2 from that
main, preserving all uncommitted follow-up work.

The genuine fresh boundary/camp run remains live: actual five level5+ creatures,
ten training wins, wood44/42 and fiber gathering underway. Camp is not yet proved.
Root integration checks of the pending repairs passed13 tests/108 assertions
(log stem .artifacts/wave1-batch-focused-1637) and Crown6/74 (wave1-crown-focused-1640).
The first command named a nonexistent Crown test basename; the separate correct
Crown selection supplied the missing coverage. Neither run emitted engine/script
errors. Relay's actual continuous deck walk passed all five legs21/157/42/48/12
frames with deck minimumY10.0007448; log stem wave1-relay-deck-integrated-1643.
These pending repairs are not part of the landed wave1 tree and are not milestone
completion. The uninterrupted opening-to-Tidewake suffix remains open.

### Fresh material failure and revised supply choice — wave2

Boundary/camp session72564 was explicitly stopped with exit-1 after44 logged
SouthBridge trench recoveries (positions around x6–12,z1325,y-8). It was not a
successful prefix or timeout. Actual receipts reached wood44/42,fiber8/50 after
ten training wins; no paid camp was reached. The isolated launcher completed
its owner fingerprint comparison unchanged; no Godot remained and no engine or
script errors appeared. Evidence .artifacts/wave1-fresh-boundary-camp{,-engine}.log
and its owner-before/after.json pair. The selected supply target had no old
telemetry, so its exact identity is not claimed. Source showed authored supply
was always preferred over natural scatter regardless of distance.

Revised helper ranks both actual source types together, rejects supplies past
the closed SouthBridge near rim using current crossing geometry, and reuses the
actual open village gate route. Target/path telemetry is now printed. Tool,
yield, stock, reach and original total walk budget stay intact. Independent
review caught that raw step() dropped the existing navigator's held-input and
confined-detour recovery; revised code calls the original walk for each waypoint
with only the remaining total physics budget. No current-world runtime pass yet.

The first unit fixture attempted the real tree during runner initialization
and emitted a script error; a private uninitialized SceneTree then produced
empty live groups and failed2 assertions. Strategy changed to a deferred native
scene check, which passes4 assertions with actual authored/scatter node scripts:
.artifacts/wave2-material-live-selection{,-engine}.log. The pure crossing guard
unit passes1 test/6 assertions (wave2-material-final-unit log stem). Both final
checks are error-free; the native selector check is registered in CI.

Fresh driver now composes the earned Relay segment after Warrens and exposes
--through-relay as prefix-only. It still explicitly fails at the missing Hall
suffix. Parser check log stem wave2-material-relay-parse. No Relay full-world or
opening-to-ending completion is claimed.

The Hall continuation has now also been source-reviewed and composed after
Relay/Mill; --through-hall ends only at Warden arena entry, and the default
still fails at the unfinished Warden/ending suffix. Actual required captain,
Sigil expense and physical shutter checks are detailed in MEADOWS-HALL-WAVE1.md.
Root parser passed (.artifacts/wave2-hall-composed-parse{,-engine}.log). It has
no fresh runtime claim. A new isolated local-supply camp launcher is prepared
for after the current Water RAM allocation; it has not been launched.

The default fresh driver now continues through the prepared actual Warden and
acknowledgement/Rift tail into the existing Cloudreach live-context route, then
the physical Stormward gate, ordinary Stormwood Segment, paid Crown and Rootgate.
It does not invoke either chapter wrapper's synthetic-entry routine. The current
explicit unfinished suffix is after Rootgate, before the Dynamo/Water ending.
Optional --through-meadows and --through-cloudreach remain prefix-only. Parser
passed under log stem .artifacts/wave2-chapters-composed-parse. All these newly
connected later stages remain unproved in the genuine fresh run. The next unique
launcher is .artifacts/run-wave2-fresh-local-supply-campaign.ps1 (default full
composed route, no early --through-camp stop); it is queued after Water/Alpha.

Independent composition review found the completed Cloudreach helper disconnects
its physics clock and Fly recovery observers before Stormward reuses its walking
methods. The handoff now reconnects those real observations for its physical
travel, rejects any recorded failure, and disconnects before the realm-changing
input destroys the old scene. Arrival compares captured instance IDs instead of
a freed world reference. New focused clock/disconnect and missing-context checks
pass2 tests/8 assertions; log stem wave2-stormward-observers-unit. Parser stem
wave2-stormward-observers-parse. The wider composed batch passed41 tests/365
assertions (wave2-composed-batch-unit); no native/script errors in those final
checks. This repair preserves the existing measured-distance timeout rather than
silently disabling it. Full-world handoff remains unproved.

## Fresh local-supply attempt — actual catch failure, 17:19 UTC

The unique default launcher ran from the real title/opening and terminated with
exit1 at193.842 seconds. Opening/key consumption and village tools/gathers passed;
the next live catch failed before the new material selector or camp was reached.
Scratch was `user://four_biome_fresh_20152_2163`. Logs are
`.artifacts/wave2-fresh-local-supply-campaign{,-engine}.log`; its owner-before/after
fingerprints match exactly. No copied save, granted prerequisites or revived
combatant was used. This is a failed run, not a material or campaign pass.

Actual target `Wild_mudsnout_1070_2` was weakened naturally. Four launches had
eligible camera-ray diagnostics but hit neighboring `Wild_mudsnout_1070_1`;
the first two repeated essentially the same origin and reported closest4.75m
against needed1.40m. The fifth struck the target, but the live fight ended lost
before capture. The driver previously continued immediately after each physical
miss. It now walks using its existing alternative-angle routine after a miss,
and rejects an explicitly obstructed trajectory preview before spending an orb.
Existing launch, blocked-line and fight bounds are unchanged. Production preview
occlusion is being repaired separately; camera assist eligibility itself is not
a promise of clearance from the lower hand-launch origin. Changed runtime proof
is still pending; the failed run will not be repeated unchanged.

The next local composition now includes earned Rootgate-to-Dynamo core arrival,
then explicitly fails before Marrow. Review replaced the initially invented
per-waypoint ascent allowance with the existing ascent smoke's single6000-frame
budget and matching4x/60Hz clock, restored on exit. An unexpected fight during
that ascent is a failure, not a nested unbounded wait. Parser is clean under
`.artifacts/wave2-dynamo-catch-composed-parse{,-engine}.log`; combined exact-target
and Dynamo checks pass8 tests/59 assertions without engine/script errors under
`.artifacts/wave2-dynamo-fresh-focused{,-engine}.log`. These are source/contract
checks, not a runtime proof of that distant earned route.

## Changed catch run — five earned, training input failure

The changed default run `four_biome_fresh_35532_2265` completed the real opening,
key consumption, village tools/gathers, all three further catches, and three
training victories. It terminated exit1 at316.881 seconds because party-cycle
input did not select the intended next fighter. Final five were Ripplet4,
Bramblebun3, Mudsnout5, Mudsnout4, Bramblebun3. Owner fingerprints again matched.
Logs/profile/source hashes: `.artifacts/wave2-fresh-clear-throw-campaign*`.
No ERROR/SCRIPT ERROR lines occurred. No obstruction/miss was observed in this
changed catch run, so it is separate progress evidence, not a recreation of the
neighbor-blocker geometry. Native preview tests establish that repair. Camp and
the new material selection were still not reached. No unchanged rerun was made.

A tiny production EncounterDirector/Party input fixture reproduced the driver's
cycle problem: five old taps yielded a missed first press, a double second
press, then three single transitions. `.artifacts/party-cycle-native{,-engine}.log`
records the actual physics-frame transitions. A changed controller probe moves
the physical bound button edges to process-frame boundaries while retaining
the original three/five physics-tick hold/release. It produced exactly one
transition per press (`party-cycle-aligned` log stem). The earned helper now
uses that dedicated cycle input, logs before/after indices, and checks the
selection after its final allowed press; the five-press limit is unchanged.
The registered native production-helper regression passes16 assertions with
no errors under `party-cycle-production` log stem. This diagnostic uses an
isolated party and input reader, not a loaded save or a campaign continuation.
Changed full-world party selection remains pending.

## Changed cycle run — ten victories, first live materials, harvest failure

The genuine title-start run `four_biome_fresh_25636_2309` terminated exit1 at
624.730s. The actual five reached levels5,5,6,5,5 after ten training wins;
logged controller presses selected exactly one next party slot each time.
The new local material selector then harvested seven real nodes, increasing
wood from4 to31 of42. It failed on vegetation at(45.447,-62.501): the final
arbiter was the non-actionable priority-2 EncounterDirector status and the
wanted tree was5.29m away. No unchanged rerun was made. Two material-null
errors occurred during an earlier successful vegetation harvest, before
subsequent gathers; they are not classified as cleanup or a clean log.
Logs/profile/hash manifest: `.artifacts/wave3-fresh-cycle-campaign*`.
Owner before/after fingerprints match. Paid camp remains unproved.

After that terminal run, the next source composition adds actual Marrow/core
release, full-belt decline and physical Waterward gate handoff, Pell's earned
lesson, then the existing Reedhaven/Brine/Shellwatch/Tidal-to-Iona helpers.
It still explicitly fails at its unfinished swimmer/mounted ending suffix.
The three existing human crossing helpers now derive left-stick direction
from the current camera basis instead of assigning camera yaw; all original
frame/distance limits remain. The new composition parses cleanly and its
eight focused suites pass34 tests/272 assertions with no errors under
`.artifacts/wave3-water-composed-focus-engine.log`. These checks are not a
full-world or campaign pass. The completed cycle run loaded the earlier
Dynamo-only suffix and does not test this newer composition.

## Earned Guardian ending seam, Wave3 local

New `tests/helpers/water_earned_ending_segment.gd` requires actual Nerissa/tether
release inside the retained Veilfall world, invites the actual Guardian prompt,
observes its durable character/world claim, declines only the pending newcomer
through the full-belt GUI, and verifies the saved personal receipt, removal of
the host claim, all three ending flags and unchanged five identities. No reward,
transaction, flag or party API is invoked by the helper. It is not wired until
the ordinary mounted late route reaches the freed tether. Full-world ceremony
and ending remain unproved. Focused receipt/completion checks pass2 tests/16
assertions clean under `.artifacts/wave3-earned-ending-focus-r2-engine.log`;
the first test invocation failed to parse an incorrect Party preload path,
which was corrected to the actual autoload path. That failed log is retained.

## Changed material run — second, distinct reach failure

The new isolated `four_biome_fresh_40872_2563` title-start run terminated exit1
at632.274s after ten actual training wins and five creatures at levels5,5,6,5,5.
The earlier successful scatter harvest no longer emitted material errors;
entire `.artifacts/wave3-fresh-harvest-campaign{,-engine}.log` had zero
ERROR/SCRIPT ERROR lines. Owner fingerprints match. Wood again reached31/42.
At the same vegetation tree(45.44735,-0.188587,-62.50097), the final interaction
was now3.32m away versus5.29m in the previous run, but still offered only the
ordinary director fallback. The approach-policy defect was reproduced/fixed,
but this run does not establish that the actual tree is reachable. New
investigation compares its scaled prompt height and collision geometry;
no unchanged rerun, skip of that tree, or relaxed reach criterion is allowed.
The current PR87 head6c0f0e78046fbd15c3e1fe46de06fa154981be66 remains frozen
for CI34262351185. Further geometry/late-route work is a separate local batch.

## Complete source composition and actual Guardian GUI probe

The next local source now connects Iona -> actual swimmer selection/capture,
explicit duplicate-only farewell -> paid saddle -> ordinary care/mount ->
Salt Crown/Sluice/Veilfall/Nerissa -> Guardian invitation/farewell. Default
campaign_complete can become true only after every segment returns its actual
success receipt; prefix flags cannot set it. A caller-owned terminal callback
preserves the late route's original50-minute ceiling. No complete fresh run
has passed. Parser log: `.artifacts/wave4-complete-composition-parse-engine.log`.
The captured swimmer is wounded by design, so before mounting the driver also
uses the existing ordinary Tidal bed/rest flow for that exact newcomer; no HP
repair or extra fighter is injected. Four focused suites pass15tests/101asserts
without engine/script errors (`wave4-water-full-composed-focus-engine.log`).

`tools/_probe_water_earned_guardian_farewell.gd` separately booted actual Water
with disclosed fiveMosshell55/freed-tether flags and one starting interior
pose. It then called the actual new ending helper. That helper physically
approached/invited the Guardian, used GUI input to decline only the pending
newcomer, preserved all five, and observed actual saved character receipt,
host claim acknowledgment/removal and all three saved ending flags. Terminal
exit0; owner fingerprints unchanged; zeroERROR/SCRIPTERROR and seven existing
Water texture-mipmap warnings. Logs/profile: `.artifacts/wave4-guardian-farewell*`.
This is a chapter-end fixture proof, NOT an uninterrupted campaign completion.
The probe did not place or activate the optional Tideglass shrine afterward.

## Wave 3 landing and Wave 4 changed fresh run

PR87 exact6c0f0e78046fbd15c3e1fe46de06fa154981be66 passed CI34262351185,
26 executed jobs/three existing conditional skips, attempt1. All jobs, steps
and logs reviewed; 3037 unit tests/487178 assertions and all seven net shards
passed. The five new strict native checks passed without engine/script errors.
Empty PR comments were checked before expected-head squash merge. Fetched main
043cd1061ba8e1423d1681c7479d9ad36f6d4317 has the identical verified tree;
its own push CI34264602920 is pending, so no new main-green claim yet.

The next branch is codex/four-biome-wave4. Exact tree prompt-height and
same-live Aquaryn body-retirement repairs have native original/fixed evidence
in MEADOWS-TREE-PROMPT-HEIGHT-WAVE3.md and WATER-ALPHA-RETIREMENT-WAVE3.md.
Two additional CI checks are registered once with isolated profiles and strict
engine/console error detection; no retries or existing ceilings changed.

A new genuine title-start run began18:40UTC, scratch four_biome_fresh_3588_2512,
using .artifacts/wave4-fresh-complete-campaign-profile and matching named logs,
source hash manifest and owner-before fingerprint. It loads the complete
ending composition and both new runtime repairs. It is active, not passed.
The earlier failed scratch was neither copied nor reloaded. Live forward-view
coverage is still open: static authored rows and twelve staged captures do
not measure every sample on the actual continuously traversed campaign.

## Wave 4 first full-composition run — new neighboring-prompt failure

Fresh3588_2512 terminated exit1 at750.55s; owner before/after fingerprints
match and the entire engine log has zero ERROR/SCRIPT ERROR lines. Five earned
creatures reached levels5,5,6,5,5 after ten wins. Actual wood reached40/42:
the old exact tree and two further trees paid correctly. The next selected
tree at(78.98997,-2.175245,-44.09865) remained standing with stock3. Its prompt
was1.93m away while a neighboring Chop at(80.4,-43.9) won at1.517838m. No
harvest receipt was accepted, no failed tree was skipped, and no rerun began.
A native neighboring-tree reproduction is in progress. Logs/profile/manifest
are .artifacts/wave4-fresh-complete-campaign*. Paid camp remains unproved.
After this terminal, the next source adds read-only travel visibility JSONL
and explicit late Ride/recall failure reasons; neither changes this run's proof.

## Wave 4 actual first-camp lesson

The next fresh run, scratch35664_2471, ended at595.393s after the normal
opening, revised village conversations, five earned creatures and ten wins.
It gathered the authored one-bed camp bill, paid for all four pieces, and
completed two actual creature rests. A third assignment stopped5.2m from
the bed while walking from the bedroll. No care/tournament pass is claimed.
Owner save fingerprints match and engine/script errors are absent. The tent
and sleeping display are nonblocking; the retained log does not identify the
actual movement obstruction. No guessed detour or rerun is accepted as a fix.
The separate optional forest cluster remains deferred, not repaired.

Read-only observation recorded123 samples over1364.57m,92 below two visible
creatures and one undersampled interval. This is partial observed travel,
not full forward-view coverage. See MEADOWS-FIRST-CAMP-CONTENT-WAVE4.md.

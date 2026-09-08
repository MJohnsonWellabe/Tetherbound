# Stormwood Wave 1: Varga and route pickup proved; Fenn overlap repaired

## Runtime on landed main

Base: `75aaccca0210a9bc1ac0f16bac687d8557f0aacf`, on the Wave 1 integration
branch. The first `smoke_stormwood_continuous.gd` invocation terminated exit 1
at the newly observed Ondra interaction boundary. It was not rerun unchanged.

The uninterrupted route earned arrival, Hesk/Tamsin dialogue, the sheltered
Break, six harvested glass for pair A and real arch travel, route 03, Maren's
three won rounds/Verge switch, Dace's three won rounds/Hollows switch, the
measured Pools charged window with two exact +3 receipts and one tool wear
each, paid pair B, route 07 and Bryn's Act-I completion. Ordinary wild losses
were handled through the existing party controls, not health/position writes.

**Varga's relocation is now physically proved.** The ordinary Bryn-to-Varga
walk covered 114.4 m in 3.019 seconds wall time under the disclosed accelerated
simulation. The exact trainer prompt activated; all three rounds explicitly
reported `outcome=won`, the host published the finished victory, and the
chapter's `stormwood:varga_defeated` event arrived. This closes the previous
Bryn/Varga overlap reproduction on the actual player path.

The route then walked to Keeper Ondra. Its first failure was precise: the
co-located `stormwood_pickup_route_09` provider offered **Take Great Candy** at
1.749 m while Ondra's prompt was 1.81 m away. The requested dialogue never won
the arbiter. No Ondra recipe or Crown progress is claimed for this run.

Logs, all under `%TEMP%`:

- `wave1-stormwood-varga-75aaccca0-engine.log`
- `wave1-stormwood-varga-75aaccca0-console.log`
- `wave1-stormwood-save-before.json`
- `wave1-stormwood-save-after-varga.json`

The eight default campaign files under `user://saves`, `worlds` and
`characters` had identical before/after path and SHA-256 manifests: zero
differences. The wrapper bound its unique scratch SaveGame before its first
yield/reset. The only `ERROR:` was the explicit harness assertion identifying
Ondra's competing pickup; there was no native/script runtime error. The Godot
process ended and the RAM slot was released.

## Bounded harness change

Collect route 09 through its real one-time provider before requesting Ondra,
matching the already established route-07-before-Bryn ordering. The existing
pickup helper previously assumed `good_candy`; it now reads the exact item and
count from the production ordinary-pickup catalogue and cross-checks the live
pickup payload before interaction. Each collection requires both its durable
receipt and the exact authored inventory gain. This preserves route 03/07 and
correctly checks route 09's `great_candy`.

The wrapper also accepts `--through-crown`. Only a successful, physically
earned Ondra prefix can invoke the existing paid Crown helper with that same
live tree, world and Game. Default behavior still ends at Ondra. The prefix's
20-minute watchdog and all per-action limits remain unchanged; the additional
Crown construction segment receives its own separate 20-minute bound. No
progression grants, reload, travel call or direct placement was added.

Parser/loading and focused checks pass: **14 tests / 118 assertions**, zero
failures/native errors, in `wave1-stormwood-route09-crown-focus-r2-console.log`
and its matching `-engine.log`. An initial source parse found that an outer
static helper cannot be called unqualified from inner `Segment`; moving it into
that class corrected the scope before these passing checks. No world was
launched on the malformed source.

## Second runtime: pickup earned, overlapping trainer exposed

The changed `--through-crown` run terminated exit 1 at Ondra, after repeating
the full prefix and Varga's three won rounds. Route 03/07 each earned exact
`+1 good_candy`; route 09 earned exact `+1 great_candy`, each with its durable
receipt. The pickup repair is physically proved. Removing that one-time
provider exposed the next actual competitor: `StormwoodTrainers/Fenn/Interactable`
offered **Challenge Fenn** at 1.550602 m versus Ondra's 1.56 m prompt. The
recipe remained unearned and the Crown helper correctly did not start.

Logs: `%TEMP%/wave1-stormwood-ondra-crown-console.log` and matching
`-engine.log`. Before/after manifests `wave1-stormwood-ondra-save-before.json`
and `wave1-stormwood-ondra-save-after.json` again cover eight unchanged default
campaign files, zero SHA-256/path differences. Terminal exit 1 was confirmed;
Godot ended and RAM was released. The explicit failed Ondra assertion was the
only error category; no native/script error was found.

## Narrow production placement repair

Catalogue evidence showed `rodline_keeper_fenn` and `keeper_ondra` at the exact
same `[-160, 34.69, 2700]` coordinates. Their NPC body capsules each have a
0.36 m radius; Fenn's trainer prompt has radius 4.2 m and Ondra's normal story
prompt has radius 3.8 m. This is a production collision, not a reason to change
stances or interaction precedence again.

Only Fenn's trainer position moves to `[-180, 35.5290401887535, 2705]`, a
20.6155 m local move. The production heightfield gives ground Y
35.3790401887535; the established catalogue clearance remains +0.15 m.
Ground samples at the four capsule-radius offsets range from 35.32527 to
35.43836 m, all below the authored root. The site is on the same conductor-road
shoulder: 14.0195 m from the arriving leg and closer to the departing leg,
within the unchanged 30 m authored road bound. It does not overlap another
authored NPC/trainer, StillGrove camp, or the nearby Crown footing. The trainer
remains optional in Conductor Run with unchanged roster, strength and gates.

The pure heightfield probe is `%TEMP%/wave1-fenn-near-ground-engine.log`.
`test_stormwood_fenn_clearance.gd` checks disjoint production prompt ranges,
local grounded road placement and the capsule footprint. It reuses the Varga
route checks. Together with the trainer census/data and pickup contracts:
**10 tests / 540 assertions, zero failures**, terminal exit 0, no native/script
errors (`wave1-fenn-clearance-focus-console.log` and matching `-engine.log`).
This is analytic placement evidence, not Terrain3D or live dialogue proof.

## Third runtime: earned Ondra recipe; Crown encounter admission blocked

The one changed-Fenn run completed the entire prefix and **earned the Stormglass
Arch recipe through Ondra's production dialogue**, after route 09's exact
`+1 great_candy` receipt. Fenn's placement correction therefore has live
Terrain3D/interaction proof, beyond the analytic checks above. This closes the
old prefix endpoint without state grants or a reload.

The same live world then entered the prepared Crown helper. Its first failure
was `four ordinary approaches did not clear the named Capacitor Alpha
(body=/root/Stormwood/Named_capacitor_alpha distance=2.93 outcome=)`.
The existing helper's four approach attempts produced no combat outcome; this
is an encounter-admission boundary, not evidence that a fight was won or lost.
The wrapper additionally failed its paid-Crown endpoint assertion. No Crown
materials, frame crafts, placement or travel are claimed. No further helper
or production changes were made after this finding, pending integration.

Terminal exit 1 and no remaining Godot processes were confirmed. Logs are
`%TEMP%/wave1-stormwood-fenn-crown-console.log` and matching `-engine.log`.
The only two `ERROR:` records are those explicit harness failures; there are
no native/script errors. `wave1-stormwood-fenn-save-before.json` and
`wave1-stormwood-fenn-save-after.json` again show eight identical default
campaign files, zero path/SHA-256 differences. RAM was released to the root.

## Crown admission source repair, runtime pending

The helper only waited for aggressive proximity; it never pressed the ordinary
Engage action. Production `wild_creature.gd` announces proximity once while
close, setting `_has_announced` even if the director refuses because the ally
is absent or fainted. Party recovery does not itself reset that latch. This
explains a possible admission failure, but the previous log does not expose
the latch or arbiter state and therefore does not prove that cause.

The helper now reads the production engageable candidate and actionable
arbiter winner, presses normal `interact` only for the exact named Alpha with
the director as provider, and rejects a different admitted enemy. It records
candidate/provider identity, offer, ally availability, aggression, announced
latch, grace, return-home state, distance and fight state before/after input.
It neither resets the latch nor calls the director's fight-entry method.

The existing four approaches and 180-frame admission/receipt bounds remain.
Combat resolution and receipt verification now occur at the end of the same
approach, avoiding the old edge case where admission on approach four had no
following iteration to resolve it. The fight bound is unchanged.

Focused tests cover exact-body identity (including a different same-species
candidate), competing providers, status-only offers and refusal. Alongside
the paid Crown/material/no-bypass contracts: **5 tests / 72 assertions**, zero
failures, terminal exit 0, no native/script error. Logs:
`%TEMP%/wave1-crown-named-engage-focus-console.log` and matching `-engine.log`.
No full-world test has yet run on this changed helper.

## Fourth runtime: exact Alpha offer observed; admission still fails

Before launch, lifecycle review added an entry-combat resolution before recall
or cycling, a clear-receipt check immediately after a walk can resolve Alpha,
and retired-body guards around diagnostics. Focused checks then passed
**6 tests / 74 assertions** (`wave1-crown-lifecycle-focus-console.log` and
matching engine log). The production once-only path normally hides the body
after its faint linger; the guard also handles future retirement safely.

The changed full run, included in head
`0a91f9b39aa552e554b849b4eb57d8011e2c7589`, again earned Ondra's recipe.
Alpha telemetry then showed the following:

- All four approaches: Alpha alive, visible, aggressive, already announced;
  grace 0, not returning home; an available healthy ally was deployed.
- Approaches 1–3: the director offered the closer ordinary
  `Wild_tanglevolt_881250888_1` at roughly 1.6–2.2 m, while Alpha was
  2.8–3.4 m away. The exact-identity guard correctly withheld Interact.
- Approach 4: the candidate was the exact `Named_capacitor_alpha`, the winner
  was EncounterDirector and its `Engage Voltarach` offer was actionable.
  After physical Interact, the candidate remained Alpha but fighting remained
  false. No outcome was emitted. The terminal Alpha distance was 7.73 m.

This separates competing-candidate selection from the remaining explicit-input
or admission failure. It does not prove which admission guard/input consumer
refused the fourth press; do not report the latch alone as the cause.

Terminal exit 1, two explicit harness `ERROR:` records, no native/script error,
and no remaining Godot processes. Logs:
`%TEMP%/wave1-stormwood-alpha-engage-console.log` and matching `-engine.log`.
Manifests `wave1-stormwood-alpha-save-before.json` and
`wave1-stormwood-alpha-save-after.json`: eight default files, zero path/hash
differences. RAM released to the root's fresh-path run. No further world run
or implementation change followed this failure.

## Strategy change: bounded source audit and synthetic admission probe

Two Alpha attempts failed admission, so no third full-prefix replay followed.
The source chain is synchronous: arbiter physics input recomputes the offer,
calls provider activation, the director calls manager `begin`, and successful
`begin` publishes ACTIVE/entered before returning. There is no deferred/await
admission or terrain refusal between these calls. The physical tap already
waits six physics frames. The missing entry therefore needs input/activation
or guard evidence, not a longer wait.

New telemetry observes the real arbiter's `activated` signal and adds the input
owner, arbiter enablement, pause state, Interact state, director ally HP/fainted/
resting and manager state. Focused checks remain **6 tests / 74 assertions**,
zero failures (`wave1-alpha-observer-focus-console.log` and matching engine log).

`tools/probe_stormwood_alpha_admission.gd` is explicitly synthetic and low RAM:
real arbiter, real director admission methods and real manager `begin`, with
an isolated flat fixture and no Terrain3D, saved party or progression mutation.
It replaces only director startup/population. Physical Interact yielded:

- Resting ally: exact actionable Alpha offer, `no_usable_ally=false`, one
  director activation, zero manager entries, no fight.
- Healthy ally: same exact offer and activation, one manager entry, active fight.

Both cases passed, exit 0, with no native/script errors in
`%TEMP%/wave1-alpha-synthetic-admission-r2-console.log` and matching engine log.
The initial probe read the cached offer before its first idle publication and
failed that diagnostic assertion; settling process frames corrected the probe,
without changing admission. This does not validate an unchanged campaign run.

The resting mismatch is real but is not established as this campaign's cause:
CreatureInstance defaults resting to false, the continuous fixture does not set
it, and the production write found by source search is saved-state restoration.
Do not attribute the Alpha failure to resting without observing the live value.
An input owner also remains possible: the navigator checks locomotion enablement,
so walking alone does not prove that Interact is unowned. A focused synthetic
Stormwood admission fixture with the new telemetry is the next useful runtime;
it must be labeled diagnostic and must not count as earned chapter progress.

## Remaining proof and disclosure

### Wave 2 changed-clock actual-scene result

The changed synthetic scene run exited 1, but **proved the Alpha input repair**:
an exact actionable `Engage Voltarach` offer was followed by
`activated_provider=/root/Stormwood/EncounterDirector`, manager state ACTIVE and
`fighting=true`. The exact-enemy check passed. That fight ended `outcome=lost`;
three encounters in total entered, including incidental wilds. Alpha clearance
and paid Crown progression remain unproved. The one explicit helper `ERROR:`
was the terminal four-approach failure; no native/script errors occurred.

Logs: `%TEMP%/wave2-alpha-clock-scene-console.log` and matching engine log.
Isolated APPDATA: `wave2-alpha-clock-scene-appdata`. The owner manifests
`wave2-alpha-clock-scene-owner-before.json` / `-after.json` cover eight unchanged
files, zero path/hash differences. Godot exited and RAM was released. This is
synthetic admission proof only; it does not establish an earned Alpha victory.

### Prepared immediate continuation: paid Crown to Rootgate

`tests/helpers/stormwood_earned_rootgate_segment.gd` is a NEW reusable helper,
not yet wired or runtime-tested. It refuses entry without the actual paid,
non-removed Still Grove build record/UID linked to `e_crown`, the recipe and
construction flags, the live player beside that arch, and a five-member party.
It begins before Crown arrival. No prerequisite or position fixture is supplied.

The helper sends normal Build Cancel if construction remains armed, walks out
of and through the physical arch, requires `stormwood:crown_reached`, follows
the authored Crown-ring points, clears the exact named guardian through ordinary
combat, opens Archivist Wen's dialogue, then activates the heartstone. Completion
requires `rootgate_released`, `act_ii_complete`, the actual Rootgate barrier hidden
with collision disabled, and the same five creature identities/live world.
The inherited movement/combat bounds are retained; this new helper's ordinary
button delivery uses the established normal-clock discipline. No direct facing,
travel, progression or pose writes are introduced.

Parser clean. Entry-record, endpoint, no-bypass and inherited Crown contracts:
**9 tests / 98 assertions**, zero failures, exit 0, no native/script errors in
`%TEMP%/wave2-rootgate-helper-focus-console.log` and matching engine log.
Current paid Crown construction is still missing; the helper cannot run as an
earned continuation until that prerequisite is achieved.

### Source-only Dynamo tail audit retained for the next lane

After Rootgate, use the return arch and `deepwood_road` through
`(-650,3550)`, `(-450,3960)`, `(-890,4490)`, `(-150,4460)`, `(-310,5050)`,
`(-100,5350)`, then the actual Stormheart ascent rather than terrain-projecting
the high core. Required receipts: Lantern Hollow arrival; Sable's captive truth;
Nysa's three-member trainer roster and Deepwood switch; Sera and the approach
switch, with all four individual rod flags; Ember Bivouac preparation; Kestrel;
core arrival. Production `stormheart_tree.gd::ascent_point` describes the physical
ramps, while `stormwood_dynamo.gd::arena_ready` requires Kestrel and core flags.

Marrow's five-member hosted roster precedes `break_core`. The field-control
adapter then pilots the deployed creature through four conduit strikes using
normal movement and `combat_quick`/`combat_charged` events; the host checks
participant/realm, exact move, action serial/cooldown, facing and bank reach.
The trainer does not fight. Finally, `stormwood_ending.gd` exposes the release,
legendary offer, Lantern Hollow Spark shrine and high-platform Waterward view
events. Existing isolated/network tests are wiring evidence, not an earned tail.

Future placement risk found in authored data: story Sable and trainer
`rodfolk_guard_bram` share exactly `(-450,57.64,3960)`. This is a likely competing
dialogue prompt, not a reproduced runtime failure. No production relocation was
made. The Rootgate helper deliberately ends before this boundary.

The first actual-scene synthetic diagnostic terminated exit 1. It reproduced
an exact actionable Alpha offer with a healthy, non-resting deployed ally,
enabled arbiter, unpaused tree and no input owner, but **no arbiter activation
signal after physical Interact**. This rules out a manager refusal for that
observed press: it never reached provider activation. Two later incidental
route fights entered and were lost; Alpha remained uncleared. One explicit
helper `ERROR:`, no native/script error; no Godot processes remained afterward.
Logs: `%TEMP%/wave1-alpha-scene-runtime-console.log` and matching engine log.
APPDATA was isolated under `wave1-alpha-scene-appdata-20260908`; the additional
`wave1-alpha-scene-owner-before.json` / `-after.json` manifests show eight
unchanged owner files. This remains synthetic diagnosis, not milestone proof.

The Alpha-only press now follows the existing Cloudreach driver's clock
discipline: synchronize with process frames, temporarily use 1x/60 Hz, recheck
the exact candidate/actionable provider and input owner, deliver the same
physical press (two held frames, four settle frames), restore 8x/480 Hz. No
press, approach, retry or fight bound was added. Other Crown inputs are unchanged.

The low-RAM real admission probe now exercises this helper at 8x/480 Hz.
Both healthy and resting controls pass their respective one-activation /
one-entry-or-refusal expectations, and both restore the original clock.
`wave1-alpha-clock-control-console.log` and matching engine log: two synthetic
cases, zero failures. Focused Crown contracts remain **6 tests / 74 assertions**,
zero failures (`wave1-alpha-clock-focus-console.log` and matching engine log).
Both commands exited 0 without native/script errors. The changed actual-scene
diagnostic still awaits RAM; no third full-prefix run is proposed.

Next validate the changed clock-synchronized press in the focused synthetic
actual scene before considering the earned continuation again. The eventual
continuous command remains:

```text
godot --headless --path . --log-file <unique-engine-log> --script tests/smoke_stormwood_continuous.gd -- --through-crown
```

Fingerprint the default campaign files again before/after. Preserve the earned
Ondra recipe before Crown, then prove the named Capacitor encounter, real materials,
two paid frame crafts and one paid green-ghost arch placement. Stop and diagnose
the first physical failure. The helper currently ends at construction: Crown
travel, guardian/Wen/Rootgate and the Dynamo remain outside this evidence.

This remains a chapter-boundary fixture: synthetic completed-Cloudreach facts,
a five-member level-44 party and three tools, with 8x simulation acceleration.
It is not an earned fresh-opening-to-Stormwood handoff. No Stormwood progress
or post-entry materials are seeded. The root's future continuous campaign must
provide the actual carried state rather than cite this seam as fresh-save proof.

### Focused actual-scene admission diagnostic prepared

`tools/probe_stormwood_alpha_scene.gd` reuses the actual Stormwood scene,
named Alpha and Crown admission helper with activation/input-owner/ally-guard
telemetry. It explicitly seeds a synthetic chapter party/entitlement and one
trainer starting position, so any outcome is diagnostic only. The scratch save
is bound before the first yield. The readiness guard requires completed shell,
empty pending realm entry and populated encounters under the unchanged scene
wait bound. Ordinary recall and Interact then exercise the existing helper;
there is no production admission change or third full-prefix replay.

Parser passed after the readiness guard correction; logs
`%TEMP%/wave1-alpha-scene-readiness-parse-{console,engine}.log`.
Full-world execution remains queued behind the live Tidewake run.

### Wave2 Rootgate review and fight-clock correction

Rootgate remains a prepared, unwired earned helper, not runtime proof. Its guardian
approach now derives an outside stance from the actual guardian body radius and
player `Collision` capsule using the production body-clearance function. Walking
retains its existing 1.2m tolerance, four approaches and 180-frame Engage window.
A null SceneTree fails before scene access. Focused Crown/Rootgate checks pass in
`%TEMP%/wave2-rootgate-crown-final-focus-{console,engine}.log`.

The changed actual Alpha admission scene proved the normal-clock physical Engage
edge, but its fight lost. That diagnostic is synthetic and does not establish
an earned Alpha clear. Its old telemetry cannot establish exact strike counts or
entry ally species. The fight helper's wall-clock quick cadence (900ms) previously
ran against 8x simulation, giving the enemy eight times as much simulation time
between the same human actions. The helper now runs the existing fight at 1x/60Hz,
retains the 180000ms wall cap and two-tick physical press, and restores prior clocks
on success or failure. Entry/end species, level, HP, faint/rest state and actual
hit/miss/damage signals are recorded; no production combat values changed.

`tools/probe_stormwood_fight_clock.gd` is an explicitly synthetic harness control,
not a victory test. Both successful-outcome and missing-outcome controls verify
normal in-fight clocks, restoration to 8x/480, signal observer cleanup and exact
emitted strike counters. Two cases pass, zero failures or engine/script errors:
`%TEMP%/wave2-fight-clock-control-r2-{console,engine}.log`. The initial control
had a parse error from assigning a method; the corrected control overrides it.
Changed actual-scene combat validation awaits the allocated RAM slot.

### Changed normal-clock Alpha scene: diagnostic pass

The single authorized changed actual-scene run exited 0, with the durable named
Alpha clear flag true and failures empty. Logs:
`%TEMP%/wave2-alpha-normal-fight-{console,engine}.log`; isolated APPDATA
`%TEMP%/wave2-alpha-normal-fight-appdata`. All eight owner files match the saved
before/after SHA256 manifests; no Godot processes remain. No ERROR or SCRIPT ERROR
lines occurred. This is explicitly synthetic chapter-party/position diagnostic
proof, not earned campaign, paid Crown, or Rootgate completion.

Observed encounters under unchanged physical action/approach limits:

- Mudsnout level44 beat incidental Tanglevolt level35 in30.131s:32 player hits,
  0 misses; Mudsnout HP358 to200.409.
- The exact named Alpha physical Engage activated EncounterDirector. Mudsnout
  faced Voltarach level40 HP511.755 and landed56 hits,0 misses,445.263 damage;
  it fainted after53.279s with Alpha at66.491HP.
- The existing next ordinary approach deployed Bramblebun level44 and resolved
  that Alpha in9.161s:9 hits,0 misses, Alpha HP0; Bramblebun HP340.1 to305.053.
  The helper observed the durable named clear receipt and returned success.

RAM released to root for the fresh default campaign; no further Alpha run or
helper expansion. Crown/Rootgate source remains frozen pending integration.

### Prepared earned Deepwood-to-Dynamo continuation

New `tests/helpers/stormwood_earned_dynamo_segment.gd` continues from the retained
live Rootgate endpoint. Entry refuses missing Rootgate/ActII/truth/guardian or
lower-rod receipts. It walks the actual paid Crown return passage, follows the
Deepwood road, interacts with exact Sable, challenges actual Nysa/Sera/Kestrel
hosted rosters and requires their finished victories plus durable flags. Rod
switch identities and guards come from live authored rows; Ember arrival and
all-rods receipts precede Kestrel. Final ascent samples the actual Stormheart
ramp function and requires 3D proximity, then the production core-arrival flag
with the same five creature instances and world. It stops before Marrow.

Hosted combat uses one five-minute wall-clock loop across actual rounds, normal
1x/60Hz physical quick input, production body reach, and restores clocks/input
on exit. It does not nest a full-fight wait under the sequence deadline. No
progression grants, inventory edits, pose writes, router calls, direct dialogue
callbacks, hosted start calls or production changes were added. Frozen Crown
and Rootgate files were not edited.

Focused tests:4 tests/42 assertions/0 failed, no errors, in
`%TEMP%/wave2-earned-dynamo-focus-{console,engine}.log`; parser clean in
`%TEMP%/wave2-earned-dynamo-parse-{console,engine}.log`. These verify missing-entry
refusal and authored roster/switch contracts, not runtime completion. The helper
is unwired and has not run in a world. Known authored Sable/Bram exact NPC overlap
remains unresolved and may block the exact story prompt; no placement or prompt
acceptance change was made. Actual paid return navigation, earned party endurance,
hosted roster completion and the physical ascent still need runtime proof.

### Dynamo ascent bound review correction

The earlier per-sample1800-frame draft has been replaced. The entire actual
ascent, including approach to its lower ring, now shares the original
`smoke_stormheart_ascent.gd`6000 actual physics-frame budget at4x/60Hz. It follows
the smoke's continuous height-derived lookahead and original grounded endpoint
(furthest>=0.998, core_anchor distance<=3.5m). Unexpected combat fails immediately;
there is no nested fight wait under this budget. One wrapper restores clocks and
input on all normal success/failure exits. Focused5 tests/49 assertions pass with
no errors: `%TEMP%/wave2-earned-dynamo-bounded-focus-{console,engine}.log`.
No actual earned ascent has run.

### Prepared earned Marrow attempt; conduit feasibility limitation

New `stormwood_earned_marrow_segment.gd` accepts the actual earned core/Kestrel
state and unchanged five. It observes five actual hosted roster snapshots and a
finished victory separately from durable Marrow completion. One300000ms loop at
1x/60Hz then drives the actual FieldControl through ordinary movement/quick input,
using authored bank positions/reach and production facing/cooldown rules. It fails
on a refused strike, loss/reset or first conduit-cycle rollover; no extra cycle,
retry, direct move/strike API or progress grant is added. Final acceptance requires
all four physical strike inputs, phase released, marrow_defeated, legendary_freed,
realm_heart_stormwood_earned and long_storm_ended with the same five/world. The
helper stops before the offer. Parser clean; focused4 tests/31 assertions pass,
no errors: `%TEMP%/wave2-earned-marrow-{parse,focus}-{console,engine}.log`.
This is unwired source/control proof, not earned Marrow runtime proof.

Source feasibility is concerning and unresolved: FieldControl uses the common
5.6m/s body movement speed for every species, and Dynamo static affects trainer
stamina regeneration rather than companion speed. With four banks at35m radius,
3.2m reach and a28s cycle, even the generous triangle-inequality lower bound is
129.292m after reaching the first bank. Add max(0,nearest-bank-distance-3.2) for
the initial approach. Any actual starting point more than30.708m from its nearest
bank is already too far at5.6m/s, ignoring acceleration/turning/input costs. From
the core centre this lower bound is28.766s; even4m toward a bank gives28.052s.
The surviving companion's actual final combat pose is not fixed by source, so
this does not prove every possible earned attempt impossible. Actual endpose,
movement and remaining first-cycle time must be observed before claiming feasibility.
No gameplay modification or further world run was made from this calculation.

The Marrow helper now records actual first-conduit-phase world/local body position,
base_speed, remaining cycle seconds, conservative travel lower bound and exact
ally species/level/HP. The bound is read-only telemetry, not a synthetic rejection;
actual first-cycle completion/failure remains decisive. Focused tests now pass
5 tests/36 assertions, no errors:
`%TEMP%/wave2-earned-marrow-telemetry-focus-{console,engine}.log`.

Read-only remaining ending audit: release dialogue -> actual StormheartOffer
prompt -> ordinary offer dialogue and pending-creature ceremony (decline pending
fulgocobra to preserve exactfive) -> personal ceremony-settled/world offer-made
receipts -> physical descent/return to Lantern Hollow Spark shrine -> actual Spark
placement -> physical return to high-platform WaterwardView -> revealed/key/chapter
receipts -> two ordinary WaterwardRealmGate inputs. First consumes realm_key_water
and persists realm_gate_water_unlocked; second enters water_arrival_from_stormwood
at First Shore [0,1.929,162]. Wait for the replacement water scene and completed
entry lifecycle before rebinding any controllers. No such ending helper was added.
The earlier Meadows pending-decline GUI flow is a reusable pattern, but its whole
helper is realm-specific. Keeping the exactfive does not block Water's later earned
Stone/recipe/compatible-wild capture and explicit outgoing-slot choice.

### Prepared earned Stormwood-to-First-Shore handoff

New `tests/helpers/stormwood_earned_waterward_handoff.gd` accepts actual Marrow
release flags and the retained live five/world, before the offer. It drains only
the actual release/offer conversation IDs, interacts with StormheartOffer, declines
the distinct pending level44 Fulgocobra through focused production farewell GUI,
and requires unchanged five plus personal/world saved settlement receipts. It
physically descends, returns to the actual Lantern Hollow Spark shrine, places the
earned Spark, returns/climbs to WaterwardView, observes the reveal/key receipts,
then uses exactly two observed physical Waterward gate activations. The first must
consume the Water key and persist the unlock. The second must naturally replace
the scene with Water at its authored First Shore anchor; old-world subscriptions
are disconnected before travel.

Water population readiness is observed from its actual inherited SIGNAL, not
read as Stormwood's boolean field. Acceptance also requires the corresponding
arrived director, completed shell, empty pending entry, available input, unchanged
five identities, consumed key/unlocked gate and actual First Shore position. No
Water opening, synthetic chapter start, save restore, pose, grant, router call,
production interaction callback or direct party release is used.

The descent reverses the newly proven native ascent mouth: ascent_point(0) ->
local[-4,6,-26] -> [0,6,-40] -> authored approach foot. It uses the same0.8m mouth
tolerance and a single6000 actual physics-frame budget at4x/60Hz, including upper
ring/helix/mouth/approach. Unexpected combat fails immediately; clocks/input restore
through one wrapper. Return ascent inherits the now-fixed Dynamo staging owned by
the mouth lane. The native ASCENT was proved separately by that lane (2826/6000,
grounded, core distance1.395m); this handoff's DESCENT and full ending are NOT
runtime-proved. Upper-core movement follows its east/south ring shoulders.

Final focused6 tests/45 assertions pass without errors:
`%TEMP%/wave3-earned-waterward-descent-focus-{console,engine}.log`.
The helper is unwired and no full world was launched for it. Spark/Sable prompt
occupancy, physical descent/return endurance, ceremony save settlement and actual
natural Water arrival remain runtime obligations; no successful campaign claim.

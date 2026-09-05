# Cloudreach continuous acceptance — in progress, not passed

Harness: `tests/smoke_cloudreach_continuous.gd`.

Latest continuous boundary: **Retry 9 earns Fly, lands at High Roost, aligns
all three vanes, completes Sora's dialogue, and unlocks the windlass road**.
The return departure needs a climb before descent. Its isolated correction
exposed a production 100m-below-anchor safety rule that rejected healthy flight;
the world owner's fix now passes the real full return in a separate fixture.
The next clean replay is held for the confirmed camp creature-recovery wiring
gap. Return flight, grounded upper progression, finale and final disk persistence
are not yet continuously proven. This remains **not passed**.

It uses the production Cloudreach scene, actual controller/InputEventAction
movement and interactions, normal collision, grounded authored-route graph,
Fly input/rings/landing, real trainer combat starts, production round callbacks,
deployed-creature relay prompts, aftermath dialogue and canonical disk saves.
No inter-site player-position writes or Cloudreach objective flag seeding exist.
Enemy damage alone has an explicit test-only lethal resolution seam; this cannot
establish difficulty or combat balance.

Initial precondition is an explicitly declared fresh completed-Meadows fixture:
five installed level-25 non-Fly creatures (Sparkit, Mudsnout, Bramblebun,
Terrapup, Brooktail), earned key and placed/equipped Meadows Heart.
It reuses the separate `smoke_meadows_realm_handoff` and
`smoke_cloudreach_transition` production proofs rather than claiming to replay
the Meadows ending in this script. Thus this file alone is not a continuous
two-realm playthrough.

Run accelerated route diagnosis:

```powershell
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/smoke_cloudreach_continuous.gd -- --accelerated
```

Normal-speed real-render evidence: omit `--headless` / `--accelerated`, add
`--rendering-method gl_compatibility --resolution 1280x800`, then `-- --capture`.
Acceleration preserves a 1/60 simulation step (8× time, 480 physics ticks).
Button presses, dialogue, rest fades, double-jump deployment and the final 8m
of grounded approaches temporarily use normal time / 60 physics ticks; each
clock transition is logged. Frame-rate readings from this mixed diagnostic
mode explicitly do not qualify as performance acceptance.

Telemetry is written incrementally to
`ralph/reports/CLOUDREACH-CONTINUOUS-0905/live/events.json`. It records positions,
elapsed simulation/wall time, distance, first actionable nearby offers (including
unchosen optional content), actual interactions, callbacks, and blocked segments.
An early exit cannot pass: final persistence and non-entry assertions must run.

## Findings so far

1. First harness attempt reached Aila and took the opening Candy, then found a
   harness-only stale reference after the one-time pickup freed its prompt.
   Fixed by recording the path before input; final-pass guard also hardened.
2. Second attempt found a real cottage obstruction leaving Galefoot:
   `(-269.52,180.81,531.87)` toward `(-120,205,700)`. The world owner reproduced
   historical wall contact and moved that single cottage off the authored road.
   The next continuous attempt passed that segment without a bypass.
3. The original arrival segment was approximately 191 simulated seconds before
   its first chosen activity. The world owner restaged existing resources and
   added an inspectable marker. Retry 3 measured **actual actionable offers** at
   32.5 seconds (route marker), 89.5 (Cloudberries), 147 (Gale Fiber), and 187.5
   (Candy), then camp/rest/craft/Aila. Maximum arrival gap is **57.5 seconds**.
   Offers are not fabricated by waypoint proximity; the real offer method must
   return a usable interaction.
4. Retry 3 reaches 2.1 km / approximately 418 simulated seconds, then falls on
   the first Broken Causeway main span from `(-320,300,1040)` toward
   `(-540,330,1320)`, observed at `(-524.076,198.874,1299.773)`. Sent to the world
   owner; no teleport over the failure. A 97-second lower-road gap between the
   potion and revive offers remains a density finding.
   World investigation confirmed the old waypoint/anchor were 40m north of the
   actual west bridge landing. The route is being corrected to the real deck
   profile; the harness now resolves actual anchor transforms rather than
   repeating stale coordinates. A retry awaits the owner's crossing regression.

## Retry 4c — verified continuous prefix, new production blocker

The clean corrected replay reaches **1,558.8 simulated player seconds
(25m 58.8s), 238.14 wall seconds, 7,460.59m**, then stops at the first confirmed
production obstruction. It is accelerated diagnosis, not a performance or
full-chapter acceptance run. The live report remains `passed: false`.

Verified in one continuous, no-warp run:

| Player time | Actual event |
|---|---|
| 33.03s | Inspected the weathered arrival marker |
| 92.02s | Gathered **+4 Cloudberries**, inventory delta checked |
| 149.65–151.72s | Equipped the knife through real hotbar input; gathered **+3 Gale Fiber**, inventory delta checked |
| 198.83s | Completed Aila's production dialogue / crisis flag |
| 201.72s | Collected the one-time opening Candy |
| 424.08s | Physically inspected the west anchor at its corrected bridge landing |
| 615.07s | Crossed both real bridge spans and inspected the east anchor / completed both-anchor flag |
| 713.20–718.87s | Real Senn challenge input, production battle start, **exactly two** test-only lethal resolutions, opposition 2→1→0, production victory callback |
| 971.32s | Physically rang the Three Bells signal / survivor-route flag |
| 1,078.60s | Pressed the bridge Gale Fiber harvest prompt; stock check remained ≥3 |
| 1,558.80s | Mandatory Maela approach blocked at Windscar junction |

The bridge crop's per-node inventory delta was not captured in this replay;
the stock threshold alone cannot prove additional yield beyond the three
arrival fibers. The next harness version records resource deltas and avoids
this redundant crop trip when the actual arrival gathering already meets the
repair cost. Its removal is a fixture correction, not a world shortcut.

Corrected bridge points genuinely traversed include
`(-540,330,1280) → (-511.2,338.25,1305.6) → (-468,338.25,1344) →
(-450,342,1360) → (-260,390,1560) → (-230,390,1575) →
(110,420,1815) → (120,420,1830)`. Return travel after Senn also crossed both
spans on foot. No Cloudreach objective was seeded after the start.

### Exact blocker

Player `(-99.53427,470.0009,2439.114)`, target authored junction
`(-100,470,2440)`, stage `battle_keeper_maela_trial`.

- Blocking collider:
  `/root/CloudreachCliffs/TraversalGates/UpperCounterweightGate/LockedTraversalBarrier`
- Wall normal: `(0.492052,0,-0.870566)`.
- Supporting floor:
  `/root/CloudreachCliffs/AuthoredRoutes/WindscarFloorLoop_LedgeCap0/Collision`,
  normal `(0,1,0)`.
- Locomotion enabled, dialogue closed, ordinary movement input active;
  velocity `(1.385816,0,0.783276)` reflects sliding against the barrier.

The locked upper-route barrier intersects the mandatory lower/aerie approach.
Sent to root/world owner; **no bypass, unlock flag, jump or teleport applied**.
The process exited on this first confirmed production blocker. Await its route
fix before replaying.

### Actionable cadence and backtracking

Offers come from actual successful `interaction_offer` calls, not waypoint
proximity. Optional offers are logged even when not chosen.

- Arrival: marker 32.5s, berries 90s, fiber 149.5s, Candy 192.5s, then
  rest/craft/Aila. First-offer gaps are 57.5s, 59.5s and 43s.
- Lower road: potion 256.5s → bridge fiber 317s → revive 353.5s:
  **60.5s / 36.5s**, replacing the previous 97s gap.
- Revive → west anchor offer: **69s**.
- Orrin at 439s → east anchor at 613.5s: **174.5s** without a new actionable
  offer, despite the traversable bridge route.
- East anchor completion 615.07s → Senn offer 711.5s: **96.43s**.
- Senn victory 718.52s → next new offer (Orrin challenge) 967s:
  **248.48s**, because the required signal bell is back at z1310 while Senn's
  yard is at z2220.
- Largest telemetry interval after the stock check is **478.33s**, ending at
  the blocked Maela approach. This includes the fixture's redundant harvest
  return journey; it must not be represented as the shortest natural route.

These are measured content-cadence findings, not proof that every second of
bridge traversal is visually empty. No camps were used yet; no rest, Fly,
shrine, upper-region or finale timing is certified by this prefix.

### Rejected fixture attempts and improvements

`retry4-invalid-combat-seam.json` preserves the first attempt: the harness
incorrectly treated `is_fighting()` as ACTIVE-only, but that API also includes
RESOLVING. This repeated the direct test reward call. All post-battle progression
from that attempt is invalid. Fixed to ACTIVE-only plus once-per-enemy identity;
retry4c records exactly two Senn resolutions. Its earlier bell-input failure
did not reproduce in the clean corrected replay and is not called a shipping bug.

`retry4b-resource-approach.json` preserves a second fixture-only issue: stopping
2.42m from a 2.4m resource offer. The approach now has a conservative 1.5m target
and 0.35m stop radius. Early fall diagnostics retain wall contacts and stop 20m
below the local segment. Subsequent runs also record team level/EXP/HP and coin
before/after battles, plus camp day/team deltas; these additions do not imply
those later actions have already passed.

## Latest five-non-Fly replay — reaches Maela; interaction correction awaiting merged-main replay

The next clean run reaches **1,160.0 simulated seconds / 196.41 wall seconds /
5,557.09m**. It uses Sparkit, Mudsnout, Bramblebun, Terrapup and Brooktail,
never inserts a sixth creature, and stops at Maela's failed challenge input.
No trial or loaner launch has passed continuously yet.

Newly verified in the uninterrupted prefix:

- Actual new causeway crop at `(-245,390.06,1582)` yields **+2 Gale Fiber**
  at527.33s, checked against inventory. Repair stock is now five.
- Senn's real trigger, two opponent resolutions and victory at728.28s give
  **+65 Coin**, Sparkit **+796 XP**, and each other owned member **+398 XP**.
  These are observed production reward deltas under the explicit test-only
  lethal seam, not combat difficulty evidence.
- Captured-picket signal physically completes at740.73s beside Senn:
  approximately12.5s after the recorded battle resolution instead of the
  previous four-minute return. Real shelter travelers appear downstream and
  their actionable greeting offers are recorded at970.5/971s.
- Previously blocked `(-100,470,2440)` junction passes at781.75s. The full
  ground approach to the level aerie passes, reaching `(400,610.10,3250)`
  at1155.92s without a bypass.

Remaining measured activity intervals above60s are60.5,69,85,95.67,96.5,
163.1,66.5 and186.5s (full endpoints/stages in `activity_intervals`). The new
causeway crop splits the former174.5s gap, but does not itself establish a
30–60s cadence. Root subsequently added the picket-route fiber node at
`(30,435,2025)`; it was not present in this run and needs replay evidence.

### Maela interaction finding and bounded correction

Both Greet and Challenge offers were available at1157.5s. The fixture then
moved toward a cached challenge offset. During approach, the attached prompt
moved from the original target near `(395.117,610.25,3242.005)` to
`(393.574,611.05,3244.535)` while the actor drifted to
`(393.888,610.101,3240.725)`. Its interact press did not start Maela's battle.

Source inspection explains an actual interaction-zone defect: the side
challenge was attached at NPC-local `(1.5,1.05,0)`, while `npc_body` rotates
the entire root to face the player. The side target therefore orbits during
approach and competes with the central greeting. The authorized bounded fix
in `cloudreach_scene_encounters.gd` makes the challenge a world-oriented
top-level child, updates translation when the NPC actually relocates, and
preserves the separate greeting. The harness also stops moving when the
desired real offer already wins and checks it again immediately before input.

Verification: `test_cloudreach_challenge_anchor` **1 test / 6 assertions** and
`smoke_cloudreach_challenge_anchor` **PASS**, proving the real child transform
remains stable across NPC rotations and tracks relocation. Harness check-only
also passes. This does **not** yet certify the production Maela press or later
chapter: root paused further runs to merge newly advanced main `2cd711eb1`.

## Merged-main replay — Maela, repair and readiness now proven

The replay against the merged `2cd711eb1` source reaches **1,181.72 simulated
seconds / 202.14 wall seconds / 5,609.6m**, then stops on the wrong camp offer.
The preserved payload is
`ralph/reports/CLOUDREACH-CONTINUOUS-0905/merged-resume2-rest-target.json`.
This is still accelerated diagnosis with the declared enemy-lethal seam.

New continuous evidence:

- The real arbiter activates Maela's separate Challenge offer; her two actual
  trainer opponents resolve through production callbacks at 1,161.58s.
- Maela gives **+60 Coin**. Sparkit advances from level 25 / 796 XP to
  **level 26 / 4 XP**; each other member advances from 398 to **812 XP**.
  Senn previously supplied +65 Coin, +796 XP to Sparkit and +398 XP to each
  other owned member. These deltas certify rewards, not combat difficulty.
- The perch repair physically completes at 1,165.85s and consumes exactly
  **3 Gale Fiber**, with inventory **5 → 2** recorded and asserted.
- Maela's actual readiness dialogue finishes at 1,175.33s; its guarded
  `cloudreach_act_i_complete` result is verified at 1,176.22s.

An earlier merged replay stopped at Aila when synthetic press/release edges
were issued inside a batch of accelerated physics ticks. The bounded harness
correction synchronizes event edges with idle frames and logs the real arbiter's
`activated` signal. The corrected replay passes Aila without a production edit.
It also counts every physics tick, including ticks during idle-frame waits;
the former coroutine-only clock omitted those waiting ticks.

The new stop is specifically **Craft activating when Rest was intended**, not
a claimed failure of the rest service. Between the pre-press check and the
synchronized event, the body moved from `(400.539,610.101,3248.247)` to
`(402.100,610.101,3248.049)`, where Craft legitimately won. A third replay
checks actual input state when releasing movement, verifies settled arrival,
and checks the current offer at the exact input boundary. It also records
input vector and velocity for further diagnosis. No camp day/team delta has
passed yet.

Source audit additionally finds the launch and rest prompts share
`(400,610,3250)`. Rest wins the inner 3.2m; Launch has only a thin outer region
inside its 3.8m radius. This is a presentation/accessibility finding awaiting
continuous post-rest observation and world-owner disposition, not authorization
to force activation or set the trial flag.

### Retry 3 — actual rest passes; launch overlap reproduced

The stricter clean replay reaches **1,202.82 simulated seconds / 208.01 wall
seconds / 5,636.0m**. Actual Rest input succeeds at the aerie and advances
**day 2 → 3**, recorded at 1,193.47s. Team HP and XP are unchanged across this
rest because all five were already healthy under the declared combat seam.
This certifies the rest service and day advance, not combat recovery necessity.

The next physical Launch approach reproduces the overlap described above:
player `(399.912,610.101,3248.214)` has the camp's closer Rest prompt instead
of the marked flight trial. The harness refuses to force activation. The
production placement finding has been sent to the world owner. Its wider
radius leaves a thin outer annulus where Launch may win; that does not make
the two markers sharing one location a clear player interaction.

Preserved evidence:
`ralph/reports/CLOUDREACH-CONTINUOUS-0905/merged-resume3-launch-overlap.json`.
The subsequent harness source also observes actionable offers from the
non-spatial encounter director, keyed by each real nearby wild body. Earlier
offer logs omitted that provider; their gaps cannot establish the absence of
all wild encounter opportunities. Non-actionable status lines are excluded.

### Bounded aerie service placement correction

The world owner authorized moving only `windscar_flight_aerie_camp` to
`(388,610,3258)` in `cloudreach_chapter.json`. Camp identity, services, safety
radius and unlock condition remain the same; launch, repair, trial gates and
landing coordinates stay authored as before. The camp is at least 7m from
the launch, repair and Maela.

`smoke_cloudreach_aerie_services.gd` now passes its isolated production-scene
regression: real floor rays under both services hit
`Landmarks/WindscarFlightAerie/LandmarkLedge/Collision` at y610.1; Rest wins at
the new camp center, its actual input advances one day, the controller walks
to the launch center, and Launch input starts the trial without granting Fly.
Only this separate local fixture seeds readiness and its initial position; it
does not write continuous acceptance telemetry. Its first run checked the day
before the rest fade callback, which was a test timing error; the corrected
test waits through the production fade. Log: `aerie-services2.log` in the
continuous report folder.

Retry 4 continuously verified the separated camp and actual launch activation.
It then exposed a synthetic double-jump lasting 0.82 simulated seconds, longer
than the ordinary jump's airborne window. No deployment or flight was proven.
Precision actions now use the normal clock as described above.

Retry 5 passed those earlier input operations, then oscillated around the
repair waypoint under accelerated movement. It timed out at
`(406.1361,610.1008,3256.105)` after 2,334.15 simulated seconds; the added
1,165.7-second interval is **harness oscillation, not authored dead travel**.
The preserved payload is `merged-resume5-precision-walk.json`. The subsequent
harness uses normal time for the final 8m of a grounded approach and a
distance-based deadline with position/input/velocity/contact diagnostics. It
retains the actual final approach tolerance and performs no position writes.
Retry 6 below continuously verifies this precision correction.

Normal rendered continuous evidence now also captures the actual camp after rest;
this headless local regression does not certify the relocated camp's visuals.

### Retry 6 — real loaner and three rings; landing approach still incomplete

The normal-time precision bursts pass continuously, including Maela, repair
and the relocated camp. Repair again consumes **5 → 2 Fiber**. Actual rest
records **day 2 → 3** with the healthy team unchanged. The real double-jump
launch at **1,189.72s** uses **Galecrest as Maela's transient loaner**, with
the same original five owned instance IDs and **183.76 stamina**.

All three ordered production airborne ring events fire at **1,191.27s,
1,193.45s and 1,196.22s**. After ring 3, stamina is **175.63** and elapsed
flight time **7.08s**. No trial completion or permanent Fly unlock has yet
been claimed.

The harness then commands a full descent while still approximately 44m from
the perch and only 14m above it. It reaches `(411.869,602.811,3267.876)` before
reaching the landing surface; the real trial boundary correctly denies it
and recovers to the recorded safe launch. This ends the run at **1,199.52
simulated seconds / 284.07 wall seconds / 5,772.7m**. It is a landing-pilot
failure, not evidence to loosen the production bounds or add terrain.

Preserved payload: `merged-resume6-landing-approach.json`. The bounded harness
correction first flies over the landing point at safe height through ordinary
stick/climb input, then descends. Its source parses; a new clean replay is
required. Clock-mode and assertion telemetry no longer resets the
`longest_dead_travel_seconds` counter; earlier top-level readings could be
shortened by such diagnostics. Use the actual `activity_intervals` endpoints
when comparing prior runs.

### Retry 7 — trial landing/Fly unlock proven; shrine touchdown needs classification

The safe landing alignment passes: actual collision landing at
`(400.204,610.100,3250.482)` completes the ordered trial and grants permanent
Fly at **1,201.75s**. The second real double-jump at **1,204.60s** again uses
Maela's transient Galecrest with the same original five owned IDs. Standing
on the verified perch naturally recovers stamina **168.87 → 196.17** before
launch; no refill is written.

The mandatory flight then traverses all three authored lift approaches,
reaching `(1015.432,1073.536,2961.181)` with **117.19 stamina** at **46.15s**
airborne. It touches the shrine area at `(1098.719,1051.301,2941.205)`, about
11m short of the final airborne waypoint. The harness treats any flight end
before that exact point as failure and stops at **1,256.40 simulated seconds /
290.52 wall seconds / 6,762.1m**. No recovery event fired. This is not yet a
verified High Roost landing claim: the old trace lacks an explicit floor or
earned-shrine assertion at that point.

Preserved payload: `merged-resume7-high-roost-touchdown.json`. The next replay
permits touchdown only on the final shrine approach and only after a real
floor ray, controller `is_on_floor`, and distance below 14m to that explicit
landing. The production objective's 22m/3m landing test is unchanged, and the
existing earned `sky_shrine_reached` assertion still must pass. Actual landed
signals and floor collider paths are now recorded. No objective flag, position,
stamina or terrain is modified by this classification correction.

### Retry 8 — High Roost earned; first vane offer blocked

The continuous replay proves a genuine High Roost landing at **1,258.13s**:
`(1099.689,1051.301,2940.164)`, grounded, **113.36 stamina**, and
`sky_shrine_reached` earned by the production landing callback. The real
floor is `Landmarks/SkyShrineHeartstone/Dais/Collision`, top **y1051.3**.

The next west-vane approach stops at `(1098.980,1051.301,2938.479)` because
the real arbiter does not offer the target vane. Its winner is the encounter
director; that can be a non-actionable creature-control fallback and **does
not establish a nearby wild encounter**. No vane interaction is forced. The
vane prompt is at `(1099,1050.8,2940)`, below the dais surface, so enabled state
and actual trimmed sight-ray collision require inspection before deciding
whether this is merely the approach or a real placement obstruction.

Preserved payload: `merged-resume8-shrine-offer.json` (**1,259.23 simulated
seconds / 292.62 wall seconds / 6,769.3m**). A separately declared
`smoke_cloudreach_shrine_services.gd` diagnostic seeds only its isolated shrine
readiness/start and reports to its own console log, never the continuous ledger.
It inspects the real offer, sight blocker and floor, then walks to the prompt
center and uses actual input. Its results cannot substitute for a clean full
replay.

The first isolated probe (`shrine-services1.log`) identifies the exact blocker:
the vane is enabled, but its trimmed sight ray hits **the observing Player's
own capsule**, at `(1098.985,1052.201,2938.879)`. The director winner is only
the non-actionable `Call out Sparkit` fallback. A genuine short walk to
`(1099.001,1051.301,2940.092)` clears that self-hit, exposes the west vane's
real offer (distance 0.509m), and actual input earns its alignment flag. The
east vane exhibits the same failure from the original offset approach.
This is a production sight-query self-occlusion finding, not a wild encounter
or missing prerequisite. The world owner has the exact collider and positions.

The world owner's shared `interactable.gd` correction excludes only the real
arbiter viewer's RID when it matches the query origin; real walls, loft floors
and unrelated actors still block. Separate negative/positive capsule tests
pass. `shrine-services3.log` verifies the fix on the production shrine's
**original offsets**, with all three actual vane inputs and Sora's actual
greeting input now passing. Sora's effect does not pass in that local fixture
because its declared readiness omitted `cloudreach_act_i_complete`; this
precondition is already genuinely earned by the continuous route. The isolated
fixture now declares that prerequisite explicitly, alongside Fly and shrine
readiness. Neither this local correction nor the previous center-walk probe
changes the continuous route's original approach positions.

`shrine-services4.log` **passes** the corrected isolated fixture end to end:
all three original vane approaches and actual inputs, completed Sora storm
engine dialogue with its real effect, then the original windlass approach and
input earning `cloudreach_upper_route_unlocked`. This is production-positive
coverage for the shared viewer exclusion, not continuous chapter completion.
The next clean full replay is `merged-resume9.log`.

### Retry 9 — full shrine sequence continuous; return launch needs clearance

The clean replay verifies the production sight fix without changing the original
approaches. Actual west/east/crown vane events occur at **1,260.20s / 1,265.30s /
1,269.13s**. Sora's storm-engine dialogue finishes at **1,276.02s**, and the
real windlass input earns the grounded-route unlock at **1,278.80s**.

The return deployment starts at `(1110.202,1052.042,2950.527)`, only about
2m above the shrine platform. The first old waypoint `(850,975,3020)` immediately
commands descent. The real controller lands again **0.85s** later at
`(1105.932,1050.101,2951.667)`, with **182.91 stamina** and no recovery event.
This is departure piloting, not a production flight barrier. The run stops
honestly at **1,280.45 simulated seconds / 315.30 wall seconds / 6,844.2m**;
preserved payload: `merged-resume9-return-departure.json`.

The bounded next correction first climbs and clears the island through the
existing shrine updraft, using ordinary input toward `(1020,1075,3000)`, then
follows the return descent. An optional `--return-flight` extension of the
separate shrine fixture adds the same declared Meadows Heart precondition and
tests this departure/return with the same original five non-Fly members. It
cannot replace the subsequent new clean continuous run.

`shrine-services5-return.log` verifies the normal-speed clearance input:
the departure waypoint is reached at **7.08s** airborne and `(850,975,3020)`
at **19.60s**, still with **163.33 stamina**. It then exposes a real recovery
bug: `fly_controller.gd` applies `recovery_drop_m` (100m) below the last safe
anchor even to healthy, intentionally controlled flight. A shrine anchor at
about y1050 therefore recovers the return before it can reach the aerie at
y610. The real recovery signal stops the fixture; no added floor, intermediate
teleport, stamina write or recovery suppression is used. The world owner has
the production condition and is responsible for the bounded safety correction.
The departure pilot change remains separate from that production issue.

`shrine-services6-return.log` **passes** after the production safety correction.
The shared drop fallback now applies to exhausted flight, retaining carrier,
stamina and duration exhaustion, verified-anchor recovery, restricted-volume
recovery and ordinary grounded cliff-fall recovery. Its focused production
physics fixture passes 30 assertions, including healthy-descent and exhausted
controls. The actual normal-speed return crosses the old 100m threshold at
`(805.541,949.974,3045.467)` with **159.40 stamina**, then continues beyond
**425m** below the shrine anchor. It lands at
`(401.584,610.101,3249.878)` on
`WindscarFlightAerie/LandmarkLedge/Collision`, still with **115.75 stamina**.
The final approach is reached at **63.88s airborne** and the fixture exits 0
at **140.77 wall seconds** including world creation and all shrine services.
No recovery signal fires and the same five non-Fly members remain owned.
This verifies the return pilot/safety corrections independently; the full
continuous replay still must repeat them without the shrine-start fixture.

## Remaining

Before live-combat acceptance, named-camp creature recovery must be made real.
Every Cloudreach camp declares `creature_recovery`, but the current physical
adapter passes no `creature_bed` spec to `rest_point.gd` and adds only a
decorative human bed. The shared night-rest contract intentionally heals only
physically bedded creatures. The healthy lethal-prefix team masked no damage
with rest, and the future live-combat harness must not copy the flat balance
probe's direct all-party `home_recovery.rest` seam. The world owner confirmed
this service wiring gap; a genuine camp-bed interaction and injury/rest/reload
proof are required before treating camp preparation as functional recovery.

The current source has moved the upper gate clear of the mandatory junction,
relocated the captured-picket signal beside Senn, added an accessible causeway
fiber crop, and added Maela's non-owned Fly loaner for valid full non-Fly teams.
The replay explicitly gathers that crop and has verified the unchanged five
owned instance IDs during loaner flight. It records actionable-event intervals,
flight denial/waypoint/stamina, battle team/coin deltas, and camp deltas.
Standing to recover stamina before launch uses normal physics regeneration,
never a direct refill. Inward radial relay approaches are prepared but remain
unproven continuously. The next run also records full initial/reward/final
inventory and party snapshots and compares every occupied slot and all five
species/levels/XP/HP across disk reload.

Continue from a new clean completed-Meadows replay. Maela's battle, material
repair, readiness dialogue, actual rest, non-owned loaner launch, all three
airborne rings, trial landing/Fly unlock and High Roost landing are now proven
above, including the three vanes, Sora and windlass. Return flight and grounded
upper route, Voss/anchors/bivouac, captain/relays, aftermath/reward and reload/Waterward
non-entry remain **unproven continuously**. Do not turn their scripted existence
or separate checkpoint fixtures into a chapter completion claim.

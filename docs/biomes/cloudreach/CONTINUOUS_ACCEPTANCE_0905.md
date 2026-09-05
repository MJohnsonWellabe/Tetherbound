# Cloudreach continuous acceptance — in progress, not passed

Harness: `tests/smoke_cloudreach_continuous.gd`.

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
Acceleration preserves a 1/60 simulation step (8× time, 480 physics ticks); its
frame-rate readings explicitly do not qualify as performance acceptance.

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

## Remaining

The current source has moved the upper gate clear of the mandatory junction,
relocated the captured-picket signal beside Senn, added an accessible causeway
fiber crop, and added Maela's non-owned Fly loaner for valid full non-Fly teams.
The next clean replay explicitly gathers that new crop, asserts unchanged five
owned instance IDs during loaner flight, uses inward radial relay approaches,
and records every actionable-event interval, flight denial/waypoint/stamina,
battle team/coin delta, and camp delta. Standing to recover stamina before a
launch uses normal physics regeneration, never a direct refill. These changes
are prepared, not yet continuous acceptance evidence.

Finish root's current-main merge, rerun affected tests, then replay
from the clean completed-Meadows fixture. Maela, actual repair/rest, the real Fly
trial, High Roost, three vanes/Sora, windlass and grounded upper route,
Voss/anchors/bivouac, captain/relays, aftermath/reward and reload/Waterward
non-entry remain **unproven continuously**. Do not turn their scripted existence
or separate checkpoint fixtures into a chapter completion claim.

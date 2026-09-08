# Stormheart earned approach footing — 2026-09-08

Read-only review of the new earned Dynamo helper found that its route entered
the helix from outside the physical outer rail. The existing
`smoke_stormheart_ascent.gd` starts a synthetic walker inside the ramp, so its
success did not validate the newly composed approach from the road.

A bounded native diagnostic then found an earlier blocker: the actual approach
ramp met the Outer Works ring below its vertical outer fascia. Production placed
the tree at `(-100,112.0591,5470)` and the approach foot at
`(-100,107.7666,5350)`. Its former endpoint was local `(0,6,-40)`, but the ring's
outer radius is 44m. Thus at the first ring edge the approach was approximately
0.515m below the deck, exceeding the actual Player's 0.35m step height.

## Original geometry: two bounded observations

`tools/_probe_stormheart_earned_mouth.gd` builds only the production
StormheartTree shell geometry (identical collision, art omitted), its actual
authored approach, the production Player scene and ordinary stick navigator.
Both cases place a **diagnostic fixture** half a metre inside the approach foot,
then settle onto the real ramp. The actual 0.4m-radius, 1.8m-height Player capsule
and 45-degree floor limit remain untouched. This is not a campaign save or
earned arrival. No terrain, enemies, dialogue, progression or rewards are loaded
to stand in for a campaign.

Each original case used one shared 6000-physics-frame budget at time scale 4,
60Hz. Both the old direct entrance and proposed open-mouth entrance stopped
before their routes diverged, grounded against `OuterWorks`, with progress 0,
no unsticks and only `OuterWorksApproach`/`OuterWorks` contacts. They ended at
`(-97.67815,117.422,5425.016)`, still targeting `(-100,118.0591,5430)`.
The two elapsed times were 99.991s and 100.008s. These are failed route results,
not passes: the original diagnostic's exit 0 only meant fixture execution ended.

Logs: `.artifacts/stormheart-earned-mouth.log` and
`stormheart-earned-mouth-engine.log`. They also contain **four SCRIPT ERRORs**
from scratch autosave attempting to read absent camera yaw/pitch properties in
the tiny fixture rig. This is disclosed, not described as a clean run. Geometry
and input continued; both observed collision failures occurred independently
of that autosave callback. The fixture rig now provides those standard fields.
APPDATA was isolated at `.artifacts/stormheart-earned-mouth-profile`; no owner
save was loaded or used to advance the route.

## Minimal repair and positive physical control

Root authorized a single production footing change in
`scripts/world/stormheart_tree.gd::add_approach`: meet the ring at local
`(0,6,-44)` rather than four metres inside it. `OUTER_WORKS_OUTER_RADIUS` holds
the existing 44m radius and supplies both ring construction and ramp endpoint;
the ring's size is unchanged. Player stepping, ramp width, rails, helix, core,
timers and acceptance bounds are unchanged.

One changed native run followed the actual approach, then local
`(0,6,-40)` → `(-4,6,-26)` → `ascent_point(0)` through the open rail ends, then
the existing continuous helix lookahead. It reached the core in **2826/6000
physics frames, 47.094s**, grounded, furthest fraction **0.998052**, core distance
**1.395m**, zero unsticks. Final support was `HollowTrunkAscent`; observed bodies
were the approach, ring and helix. Terminal exit 0; no ERROR/SCRIPT ERROR or
warnings in `.artifacts/stormheart-earned-mouth-fixed.log` or its unique
`stormheart-earned-mouth-fixed-engine.log`. A new isolated APPDATA directory was
used: `.artifacts/stormheart-earned-mouth-fixed-profile`.

After that evidence, root authorized applying only the corresponding entrance
staging to `_walk_actual_ascent` in the earned Dynamo helper. The same whole
6000-frame bound includes approach and all entrance stages. It retains the
original 0.998 progress, grounded core proximity, combat refusal and earned
chapter flag checks. The new local staging arrival tolerance is 0.8m; it does
not enlarge the original core acceptance tolerance.

The original direct entrance **after** the footing repair was not tested, so
the report does not claim it cannot work through navigator recovery. Likewise,
reverse descent is source-supported but not validated by this ascent run.

## Integration checks and limits

- Final helper focused checks: **5 tests, 49 assertions, 0 failed**, exit 0,
  `.artifacts/stormheart-mouth-focused.log` and `-focused-engine.log`.
- Final diagnostic `--check-only`: exit 0 with unique
  `.artifacts/stormheart-mouth-final-parse-engine.log`; `git diff --check` passed.
- `--fixed-only` promotes the diagnostic to a strict single-attempt native CI
  smoke: it runs only the repaired mouth route and exits nonzero if core is not
  physically reached. This strict terminal check was added after the successful
  geometry run and parsed; root owns its CI registration and exact-head result.
  The older diagnostic modes remain available without implying route acceptance.

CI invocation: `godot --headless --path . --log-file <unique-engine-log>
--script tools/_probe_stormheart_earned_mouth.gd -- --fixed-only`.

This proves isolated shipped footing and physical ascent with the actual Player.
It does not prove terrain approach from a previous campaign milestone, creature
interference, retained-team trainer wins, Dynamo progression, descent or the
continuous four-biome journey. No full-world run, imports, commits or pushes
were performed by this diagnostic lane.

## Follow-up: actual Waterward helper descent

After the staged earned helper was frozen, root authorized one independent
native descent check. New `tools/_probe_stormheart_waterward_descent.gd` invokes
the actual `stormwood_earned_waterward_handoff.gd::_descend_core()` coroutine;
it does **not** copy its movement driver. The world supplies the production
Stormwood heightfield for the actual approach-foot query. Manager/director test
doubles report no combat; Player, navigator and shipped tree collision are real.

The initial pose is explicitly a geometry fixture matching the handoff's
post-offer preferred stance: local `(0,150.2,12.5)`, settled on `DynamoCore` at
world `(-100,262.0596,5482.5)`. It is not an earned core arrival or a reused
campaign save. The actual helper owns its existing 6000-frame, 4x/60Hz bound,
the complete upper-ring/helix/lower-mouth/approach sequence and clock restoration.

One attempt completed: **terminal exit 0**, `passed=true`, `grounded_foot=true`,
**49.670s**, **2981 observed physics frames** (including wrapper clock changes),
ending at `(-99.86176,108.176,5352.99)`, **3.021m** from its actual authored foot
within the unchanged 3.5m criterion. The helper reported no failures; the Player
had **zero unsticks**, no observed wall contacts and actual
`OuterWorksApproach` floor support at the endpoint. The original physics clock
was restored. No ERROR/SCRIPT ERROR or WARNING in
`.artifacts/stormheart-waterward-descent.log` or the unique
`stormheart-waterward-descent-engine.log`. APPDATA was isolated in
`.artifacts/stormheart-waterward-descent-profile`. `git diff --check` passed.

This replaces the earlier untested-descent limitation for this isolated
geometry and actual helper sequence. It still does not validate full-world
terrain, creatures, ceremony, Spark shrine, Waterward gate or natural Water
arrival. No production or helper code changed during this follow-up.

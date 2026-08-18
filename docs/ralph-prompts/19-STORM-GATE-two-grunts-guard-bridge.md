# STORM-GATE — Two Team Tether grunts guard the storm-road bridge

## Goal
Turn the current storm-road gorge/collapsed-bridge area into a meaningful progression gate:

- the gorge is genuinely impassable except by the bridge;
- two Team Tether grunts visibly guard that bridge;
- the player must defeat **both** grunts;
- once both are defeated, the bridge crossing becomes available;
- defeating only one is not enough;
- the state persists through save/load;
- the player cannot simply walk around the gorge in ~15 seconds and bypass the encounter.

This is a content/progression use of systems that already exist. Do not invent a second bridge framework or a second trainer framework.

## Owner decisions — locked

The owner explicitly rejected the old shape where the trench/gorge could simply be walked around:

> "the hole seems like it should be impassable other than by bridge. if I can walk around it in 15 seconds, what's the point. maybe a bridge that is protected by two team tether grunts. you beat them then go across."

Therefore:

- the gorge must function as a real barrier;
- the bridge is the intended crossing;
- two Team Tether **grunts** guard it;
- both grunts must be beaten;
- after both victories the player can cross;
- do not replace this with a key item, arbitrary level check, invisible wall, or UI-only lock.

## Current implementation seams to reuse

### Physical crossing
`scripts/world/gated_crossing.gd` is already the established bridge/gap mechanism used by the South Bridge and Old Mill Crossing.

It already owns:

- authored bridge placement from `terrain_playground.json` crossing geometry;
- deck collision;
- a physical gate leaf/lock;
- persistent open state;
- near/far-side geometry helpers for smoke traversal tests;
- physical locked feedback instead of explanatory UI text.

Reuse/subclass/generalize this system. Do not make a storm-road-only copy of bridge logic.

### Trainer battles
`scripts/world/trainer_npc.gd` is already the authoritative trainer placer/reader.

Each trainer can already have:

- data-driven position/facing;
- a real team from existing creature species;
- challenge/defeated dialogue;
- rewards;
- a `defeat_flag` persisted in the shared progression store;
- one-time defeat behavior unless explicitly rechallengeable.

Use two normal trainer entries. Do not hand-script combat into the bridge.

### Team Tether visual rank
`data/config/npc_ranks.json` already defines the `grunt` rank and existing NPC-rank machinery.

Use the existing grunt treatment. Do not generate a new human mesh for these two guards.

### Progression persistence
Use the existing `ProgressionState` flat flag store. Trainer defeat flags and bridge-open state must survive reload through the same existing save pipeline.

## Important implementation distinction: defeat flags are not inventory keys

`item_gate.gd` currently means exactly what its name says: required **item IDs** are present, then it consumes one of each and sets the open flag.

Do **not** fake trainer defeats as item IDs or make invisible pseudo-items such as `grunt_1_defeated_key`.

Implement the smallest clean extension appropriate to current main, for example:

- allow the storm crossing/subclass to ask the progression store directly whether both trainer defeat flags exist; or
- introduce a tiny generic progression-flag gate helper if current code now has multiple flag-gated physical-world cases that clearly justify it.

Do not turn this into a broad requirement-expression framework.

The condition is simply:

`grunt A defeated AND grunt B defeated`

Then the physical crossing may unlock/open.

## Geography / storm-road barrier

Before editing terrain, inspect current `main` and reproduce the area.

The earlier owner playtest and later rendered confirmation established that the problem was not merely presentation: the trench ended in open meadow and could be walked around quickly.

Required world result:

- the gorge/trench must extend or connect naturally to terrain/topology so there is no trivial walk-around near the bridge;
- the bridge remains the readable intentional crossing;
- the player should not encounter an invisible collision wall in apparently open meadow;
- if terrain cliffs/steep banks form the barrier, they must visually read as impassable;
- do not create absurd sheer cliffs unrelated to the Meadows' terrain language merely to close the gap;
- preserve valid exploration elsewhere — this is a local progression barrier, not a corridor of invisible walls.

Use the current macro-layout/terrain system and existing storm-road carve as the source of truth. Measure the bypass route on current `main` before changing it.

### Traversal acceptance
From the intended approach side, a player trying to bypass the guarded bridge on foot should not find a nearby alternate crossing or easy end-run around the gorge.

Do not interpret this as "the player can never reach the far side by any future route." It means this progression gate cannot be defeated by walking a short distance around its edge.

## Guard placement

Place two Team Tether grunts so the encounter reads clearly before the player steps onto the bridge.

Design intent:

- both visibly belong to Team Tether using the existing `grunt` rank visual language;
- they guard the crossing rather than randomly standing nearby;
- position them far enough apart that they read as two individuals, not overlapping NPCs;
- do not place either where terrain, bridge rails, foliage, or one another block the challenge interaction;
- both must stand on stable authored ground;
- both remain reachable from the near/approach side while the bridge is still closed;
- neither may spawn on the far side where the player cannot challenge them.

Use existing trainer model/rank systems. No new Meshy generation.

## Trainer content

Author two ordinary Team Tether grunt trainer entries using the existing data structure.

Requirements:

- unique trainer IDs;
- unique persistent `defeat_flag`s;
- rank = grunt through the current rank plumbing;
- short faction-appropriate challenge/defeated dialogue;
- existing Meadows species only;
- teams appropriate to the player's progression at this gate;
- no trainer-owned creature can be caught;
- normal trainer reward plumbing may be used if current progression patterns expect it, but do not make rewards the reason the gate opens — defeat flags are.

Team composition/levels are tunable content values. Derive them from nearby current Band/route trainer difficulty and the Meadows progression spec instead of inventing a new difficulty curve.

Do not make one grunt a captain/officer. Owner said two grunts.

## Gate behavior

### Before either grunt is defeated
- bridge/crossing is closed;
- both grunts are challengeable;
- no trivial bypass exists.

### After exactly one grunt is defeated
- defeated grunt remains in the normal beaten state;
- other grunt remains challengeable;
- bridge is still closed;
- save/reload preserves that half-complete state.

### After both grunts are defeated
- the crossing unlocks/opens;
- player can traverse normally;
- bridge-open state persists;
- reload does not respawn an unopened lock merely because the world rebuilt;
- both trainers remain recorded as beaten according to existing trainer behavior.

Prefer the crossing responding immediately after the second defeat if existing event/state plumbing allows it cleanly. Otherwise it may update on the next ordinary bridge interaction/state refresh, but the player should not need to quit/reload.

## Relationship to RG16 / RG17

This gate belongs on the post-tournament Team Tether route.

RG16 establishes:

- build tournament-ready team;
- win local tournament;
- then head toward the bridge / Team Tether route.

RG17 establishes pylons as an in-world navigation spine toward the stronghold.

STORM-GATE must reinforce that same route rather than creating a contradictory side destination.

If pylons are visible near this crossing, their siting should naturally lead the eye toward/through the guarded bridge once it opens.

Do not duplicate RG16 objective logic or RG17 pylon generation here.

## Preserve

- existing trainer combat system;
- trainer-owned creatures cannot be caught;
- five-creature player ownership cap;
- existing physical crossing grammar;
- bridge collision and save persistence;
- current Meadows terrain/art family;
- existing Team Tether rank system;
- controller-first challenge interactions;
- current map/progression structure.

## Do not

- Do not use fake key items to represent trainer defeats.
- Do not consume trainer-defeat state as if it were inventory.
- Do not gate on player level.
- Do not add an invisible wall over open-looking terrain.
- Do not make the gorge trivially walk-around-able.
- Do not create a second combat encounter manager.
- Do not create unique human art for these guards.
- Do not silently turn either grunt into a captain/officer.
- Do not make one victory sufficient.
- Do not reset the gate or trainers on reload.
- Do not allow trainer creatures to be caught.

## Edge cases

Verify:

1. player beats grunt A, saves, reloads, then beats B;
2. player beats B first, then A;
3. player beats one and walks away for a long time;
4. player reaches the bridge before fighting either;
5. player tries to walk around both ends of the gorge before opening the crossing;
6. player loses to a grunt and returns;
7. one trainer's defeat dialogue/state cannot accidentally set the other trainer's flag;
8. bridge unlock condition cannot pass from only one flag;
9. bridge already open on a save rebuild stays open;
10. old saves without these flags remain safely on the locked/pre-defeat state unless existing progression clearly implies otherwise.

## Acceptance criteria

1. Two visible Team Tether grunts guard the storm-road bridge on current main.
2. Both use the established grunt visual rank language.
3. Both are reachable/challengeable before the crossing opens.
4. Each runs through the normal trainer battle system.
5. Each writes a distinct persistent defeat flag.
6. Defeating zero or one grunt leaves the bridge closed.
7. Defeating both allows the bridge to open/be crossed.
8. Save/reload preserves 0/2, 1/2, and 2/2 progression correctly.
9. The gorge cannot be bypassed by a short walk around its end near the crossing.
10. The barrier is visually explained by terrain/bridge geometry; there are no invisible blockers in open-looking space.
11. Once open, the bridge is physically traversable and continues the intended Team Tether/pylon route.
12. Existing South Bridge and Old Mill Crossing behavior remains unchanged.

## Testing / verification

At minimum:

- `smoke_traversal`
- `smoke_trainer_battle`
- relevant trainer data tests
- relevant progression/save tests
- existing crossing/gate tests

Add focused automated coverage for:

- two independent trainer defeat flags;
- AND-condition remains false at 0/2 and 1/2;
- AND-condition true at 2/2;
- crossing open persistence;
- traversal fails across/around gate before completion and succeeds over bridge afterward.

Use the existing crossing helpers (`near_point`, `far_point`, `depth_past_crossing`) where appropriate rather than re-deriving geometry in tests.

For the bypass check, actually attempt traversal around both ends of the local gorge on current terrain. A unit assertion on gate state does not prove the world cannot be walked around.

Because terrain placement + NPC appearance is visual-affecting, capture representative frames and run the normal blind visual-judge pass required by `ralph/conventions.md`.

Representative frames should show:

- approach view where bridge and two guards read clearly;
- side/world view proving gorge continuity/barrier readability;
- post-defeat/open crossing.

## Definition of done

STORM-GATE is complete when the old meaningless trench becomes a real player-understandable progression beat:

**approach an actually impassable gorge -> see two Team Tether grunts guarding the only local crossing -> defeat both through normal trainer battles -> bridge opens -> cross and continue toward Team Tether.**

The implementation must use existing trainer, progression, crossing, terrain, and rank systems rather than parallel replacements.
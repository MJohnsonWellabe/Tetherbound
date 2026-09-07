# CONTENT-ACTIVITIES — Build a small set of memorable Meadows side activities

## Goal
Populate the Meadows with **6–10 meaningful optional activities across the whole chapter**, not dozens of shallow errands. Each should deepen a place, creature, NPC, or Team Tether thread while giving the player a worthwhile reason to leave the critical path.

## Approved activity pool
The progression spec/backlog already names candidates including:
- Lost Pal
- Broken Cart
- Night Watch
- The Old Champion
- Deep Warren
- River Nest
- Team Tether patrols
- Meadowhart Herd

Treat these as the preferred content pool. Inspect current main first because some may already partially exist as encounters, dialogue or geography. Promote/complete existing seams before inventing replacements.

## Quantity philosophy
Target **6–10 total across Meadows**, distributed naturally by band. Fewer substantial activities are better than 40 icon-driven chores.

Each selected activity needs:
1. an in-world discovery or NPC/world trigger;
2. a concrete action using existing core systems;
3. a distinct payoff (resource, coins, TM/item, relationship/story knowledge, useful shortcut, rare encounter, etc.);
4. persistent completion state where completion matters;
5. local environmental storytelling so it belongs to its region.

Avoid fetch-quest templates whose only gameplay is walking from marker A to marker B and back.

## Use core game verbs
Activities should primarily remix systems the player already learned:
- catch/find a creature;
- trainer/wild combat;
- exploration/tracking via landmarks, roads and habitat;
- gathering/crafting/building where appropriate;
- day/night timing;
- creature care/condition;
- dungeon/shortcut traversal;
- dialogue and progression flags.

Do not build one bespoke minigame framework per activity.

## Suggested interpretation of named beats
Use existing canon/docs for exact details if present. Where only the name exists, keep invention conservative and mechanically grounded:
- **Lost Pal:** find/reunite an existing species/individual; not permanent creature storage or a sixth owned creature.
- **Broken Cart:** environmental resource/crafting/help beat tied to a road/travel location.
- **Night Watch:** an optional reason to experience the short night and nocturnal world behavior, without making night mandatory for main progression.
- **Old Champion:** character/trainer history and a memorable battle or lesson using an existing NPC rig/team.
- **Deep Warren:** optional deeper payoff connected to the already-authored Burrow Warrens rather than a second dungeon.
- **River Nest:** regional wild/nest encounter that makes the river ecosystem matter.
- **Team Tether patrols:** optional trainer encounters reinforcing faction occupation.
- **Meadowhart Herd:** a non-destructive wildlife spectacle/encounter around the existing legendary/deer fiction; preserve roster/catching canon.

If authoritative docs define a named beat differently, docs win.

## Distribution
Coordinate with MQ3: place activities where a band needs optional texture, not all around the village. At least some should be discoverable through curiosity rather than a quest giver. Map markers may appear after discovery; do not pre-label every secret from game start.

## Progression / rewards
Use existing inventory, trainer rewards, TM/item pickups, quest flags and map state. Rewards should be useful at the point found but not mandatory for completing the chapter. One-time rewards persist through save/load and cannot be farmed by scene reload.

## Preserve
- five-creature ownership cap;
- no creature storage;
- no hunting/butchering;
- Meadows roster only;
- no new human meshes;
- main quest remains understandable and not drowned by side-objective UI.

## Acceptance criteria
1. 6–10 optional activities exist across Meadows, with intentional regional distribution.
2. Each uses/recombines existing core mechanics rather than adding a disposable minigame.
3. Each has a distinct discovery context and meaningful payoff.
4. Activities do not all use the same quest template.
5. Completion/rewards persist and are idempotent.
6. Optional content never requires breaking five-creature/storage rules.
7. The main objective remains visually dominant in HUD/quest hierarchy.
8. Named activities already defined in canon are implemented according to that canon, not reimagined casually.

## Testing / verification
Per activity: happy-path completion, save/reload before/after, reward idempotence and relevant combat/catch/gather tests. Do one full quest-log/UI pass to ensure 6–10 activities remain readable rather than cluttering the tracked main story. Capture representative activity locations and run visual review for any authored world changes.

## Definition of done
The Meadows rewards curiosity with a **small, memorable portfolio of optional stories and encounters** that make its regions feel inhabited and worth exploring without turning the game into a checklist.
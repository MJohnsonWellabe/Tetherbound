# Owner playtest — 2026-08-18 evening

This is a **current owner-play priority overlay** on `ralph/BACKLOG.md` and the Meadows prompt library. Newer owner observations here supersede older assumptions in prompts when they conflict.

## Core design conclusion
Tetherbound's Meadows motivation is now clearer:

- **Pokemon is the strongest motivational spine:** catch, train and improve a five-creature team because stronger trainers, special creatures, the tournament, Team Tether and bosses are ahead.
- **Valheim supplies the expedition rhythm:** venture out, gather/mine, build/camp, rest, recover, then push farther.
- **Palworld supplies overworld creature presence and special encounters**, but world creature density should remain lower than Palworld because Tetherbound keeps only five creatures.

The Meadows should not be mostly empty traversal. Along the route, the player should repeatedly have reasons to stop: wild creatures worth fighting/catching, NPC trainers for XP, useful harvest/mining resources, special stronger creatures, side activities, and places where building a camp and resting creatures is valuable.

## World composition — locked
The pond-side band with dense trees and plants is owner-approved and should be treated as a positive composition reference.

Do **not** extrapolate that density across the whole biome. Meadows needs deliberate contrast:

- lush, densely populated pockets like the pond band;
- broad open meadow/field areas with long sight lines in the spirit of Valheim Meadows / Palworld open fields;
- trails, landmarks, creatures and resource clusters readable across those open spaces;
- regional density variation, not one global vegetation-density target.

Future performance/vegetation passes must not thin the approved pond pocket into generic emptiness or fill every open field with dense vegetation.

## P0 — correctness / play blockers

### OP1 — Modal lifecycle freeze — REOPEN RG1
Fresh owner reproductions:
- freezes talking to/leaving the innkeeper menu;
- freezes after resting a creature;
- freezes after opening Build from the main/pause menu and returning to placement;
- in the severe Build repro, world controls died **and the main menu could no longer be opened**.

RG1's older assumption that the pause menu always remains usable is no longer universally true. Treat this as a systemic modal/input-ownership lifecycle defect. Regression coverage must include trader, innkeeper, creature bed, standalone Build flow, and Build opened from the main menu.

### OP2 — Build snapping/grid correctness
Owner can place structures now, but construction geometry is not coherent:
- roof cannot reliably snap/build on top of an existing wall;
- floor pieces do not occupy/align to full modular squares;
- walls end up about half a square off instead of landing directly on floor edges.

A basic test house must be possible: 2x2 floors, aligned walls, doorway, roof. Fix shared dimensions/snap anchors, not individual-piece hacks.

### OP3 — Tool use / harvesting feedback
- Chopping must require the axe actually equipped and visibly in the trainer's hand.
- Pressing chop/use must visibly swing the axe and produce the hit through that action.
- Current prompt-only behavior where the game says to chop but no meaningful swing/result occurs is unacceptable.
- Picking up harvested resources must show concise gain feedback such as `+3 Wood`.

### OP4 — Torch hand + repeat-equip reliability — REOPEN RG22 hand path
Two fresh defects:
- torch orientation in hand is anatomically wrong; flame/top must be upright like a real handheld torch;
- torch may illuminate correctly the first time it is drawn, then fail to light the world after being put away and drawn again.

This is not a brightness-tuning request. Fix equip/orientation/state lifecycle first.

### OP5 — Front door/title screen — RG25/EV9 remains open
Current shipped play still launches without the expected front screen. Required front door remains:
- New Game / Start New Game;
- Load Game / save selection;
- Quit Game;
- controller-first operation.

Do not close RG25/EV9 until this is visible and usable in the actual launched build.

## P1 — core loop and build/care experience

### OP6 — Valheim-style persistent build selection
Placement itself works now. The remaining Build-menu UX is wrong.

After selecting a buildable, successful placement must **keep that same piece selected** and immediately present the next ghost. The player may place repeatedly until cancel/back or deliberate selection of another piece. This applies to ordinary structural pieces and other player-placeable buildables unless a specific item has a proven reason not to support repeat placement.

### OP7 — Dismantle/delete player-built structures
Add a controller-friendly dismantle action while building. Highlight/target the intended placed structure before destruction. Default design: return the full material cost so experimentation with snapping/building is not punished. Never delete authored world structures through this tool.

### OP8 — Creature bed becomes real overnight recovery
Current immediate-heal button behavior is superseded.

When a creature is assigned to a creature bed:
- its body is visibly lying/resting in the bed;
- it is unavailable for active combat/party deployment while resting;
- health restores **gradually while it remains in bed**;
- the intended full-rest cycle is overnight;
- taking it out early stops the rest and retains only recovery actually earned so far;
- full overnight rest should leave it appropriately recovered/rested for the next day.

This should create an actual reason to build creature beds and camp rather than treating the bed as a menu potion.

### OP9 — Palworld-like aim/throw interaction
Current throw aiming feels bad. Desired interaction:
- hold aim to enter a clear over-the-shoulder throw-aim mode;
- camera tightens/shifts appropriately;
- right stick freely aims;
- clear reticle;
- visible trajectory/landing assistance appropriate to Tetherbound;
- mild target assistance is okay, not hard lock-on;
- throw while aiming;
- clean cancel back to normal camera/control.

Do not copy Palworld assets/UI; match the usability/readability of that interaction using Tetherbound's own presentation.

### OP10 — Creature release ceremony
Functional removal alone is incomplete. Releasing a creature must run the intended ceremony/presentation so breaking the five-creature bond feels consequential. Do not call release complete because the array slot was cleared.

### OP11 — Creature level-up feedback
Whenever a creature levels up, immediately communicate:
- creature identity/name;
- new level;
- meaningful new unlock/change, if any.

The player must feel team progression because it is a central motivation.

### OP12 — Cycle creatures in exploration
Player must be able to cycle/select party creatures during ordinary exploration without opening the Creatures menu. Use controller-first previous/next controls and update the visible control legend. If a creature is active, changing selection should perform the appropriate swap/recall/summon flow without menu friction.

## P2 — world completeness / navigation

### OP13 — Pond needs actual water
The pond is currently terrain with no convincing water. Add the real water surface/presentation and appropriate existing traversal/collision behavior. Preserve the owner-approved dense pond vegetation composition.

### OP14 — Readable doors should work
Buildings around the pond have doors that visually read as usable but cannot be opened. General rule: if an accessible Meadows building has an ordinary door that looks usable, it must open/interact unless deliberately locked; deliberate locks need visible/gameplay explanation.

### OP15 — Map/minimap trails
Owner reports the minimap's movement-up behavior now seems to be working. Treat movement-up as **verify-first**, not rewrite-first.

Fresh remaining defect: the minimap/map does not show all meaningful authored trails. The map bake/data path should consistently represent the routes a player can visibly follow in the world.

## P1/P2 — Meadows purpose and encounter density

### OP16 — Meadows core-loop density
This is distinct from merely 'add 6-10 side quests.' During ordinary route progression, the player should frequently encounter useful reasons to engage with the world:
- wild creatures to fight for XP and/or catch;
- NPC trainers along the path;
- occasional stronger/rare/alpha/elder encounters;
- useful harvest/mining/resource deposits;
- natural points where the player may build a camp, rest creatures, sleep and prepare;
- side activities and world discoveries layered on top.

The primary progression question should repeatedly be: **is my five-creature team strong/prepared enough for the next meaningful trainer, tournament, Team Tether gate or boss?**

Coordinate RG20, MQ3, PW2, CONTENT-ACTIVITIES, CONTENT-HOME, RG18 and RG19 around this spine instead of shipping each as isolated content islands.

## Positive verification from this playtest
- Structure placement itself is materially improved/working compared with the previous report. Do not reopen the old 'confirm does nothing' bug without current reproduction.
- Minimap movement-up behavior appears materially improved. Verify before changing orientation math.
- Dense vegetation/plant composition around the pond is explicitly approved.

## Execution order
Do P0 correctness first. Then P1 build/care/catch/progression experience. Only then increase encounter/activity density, because additional content cannot compensate for broken build, gather, rest, menu and throw loops.
# WORLD-DOORS — Doors that visually read as usable must open

## Owner reproduction
Doors on the existing buildings around the pond are visible but cannot be opened.

## Design rule — broader than the observed location
A Meadows building door that visually reads as a normal usable door should behave as a door. If a door is intentionally locked, blocked or decorative, the game must communicate that distinction in-world instead of presenting a normal-looking dead interaction.

Do not patch only two pond buildings if the same prefab/system places dead doors elsewhere.

## Goal
Audit the authored Meadows building-door family and give all intended usable doors one consistent interaction/collision/state contract.

## Inspect first
- village/building prefab scripts and scenes
- pond-area building placement/config
- existing openable door script if any
- `interactable.gd` / interaction arbiter
- collision shapes on door leaf and doorway
- hinge/pivot transforms
- save/progression needs for persistent locked/unlocked state
- building meshes from the one-village-family asset set
- any interior transitions or door prompt tests

First determine whether the pond doors are:
1. meshes with no door logic;
2. door scripts with broken interactable registration;
3. animation/pivot failures;
4. collision that never changes when visual moves;
5. intentionally decorative doors that currently look usable.

Fix the systemic source.

## Standard door contract
For an ordinary usable door:
- approaching within interaction range shows `Open`/`Close` with the current dynamic glyph;
- pressing Interact rotates/animates the leaf around a believable hinge/pivot;
- collision moves with the leaf or otherwise clears the doorway when open;
- open direction should not trap the player against nearby geometry;
- pressing again closes it when unobstructed;
- state remains coherent if the player walks away and returns.

Do not require a special menu.

## Locked doors
If current progression has intentionally locked buildings:
- keep lock rule authoritative;
- prompt should read `Locked` or explain the known requirement in the project's existing style;
- do not play a normal open animation then block with invisible collision;
- unlock state must use existing progression flags and persist if it is permanent.

Do not invent locks merely to avoid implementing an interior.

## Decorative/non-enterable buildings
If a building is genuinely not intended to be entered in Meadows, its entrance should not masquerade as a normal interactive door. Use one of the project's established visual blockers—boarded doorway, ruined/blocked entrance, obviously sealed Team Tether treatment, etc.—rather than a perfectly ordinary handle/door that ignores the player.

Prefer making already-authored accessible structures usable where practical.

## Collision / geometry
- open door creates a traversable opening wide enough for the player capsule;
- closed door blocks as its visible leaf suggests;
- no invisible wall remains in the doorway after opening;
- door leaf does not rotate through adjacent wall in an obviously broken way;
- interaction target remains reachable from both reasonable sides.

## Input ownership
Door interaction is an ordinary world verb and must not open/close while another modal owns input. Reuse the interaction arbiter rather than polling a raw button independently.

## Save/load
Ordinary doors may reset closed on reload if current project convention treats door posture as transient. Permanent unlocked state must persist. Do not expand save format for simple open angle unless the rest of the project already persists it.

## Audit scope
At minimum walk/check:
- pond-area buildings named by the owner;
- Grandpa/home/village buildings using the same door family;
- Team Tether/stronghold doors if they share the same prefab and are Meadows-reachable;
- player-built door separately only to ensure this change does not break the buildable; BUILD-SNAP owns its placement.

## Tests
- interact closed -> open;
- doorway collision becomes traversable;
- interact open -> close;
- blocked closing does not trap/teleport player;
- modal input prevents accidental door activation;
- locked door stays locked until correct flag if applicable;
- same reusable door prefab works in multiple building placements.

## Acceptance criteria
1. Pond-area normal doors open and close.
2. Visual leaf and collision agree.
3. Player can walk through when open.
4. All Meadows buildings using the same usable-door grammar behave consistently.
5. Intentionally locked/blocked entrances communicate that state visibly/through prompt.
6. No one-off coordinate hacks for only the reported pond doors.
7. Controller interaction remains discoverable and modal-safe.

## Definition of done
The player can trust the environment: if something looks like a normal usable door, interaction does what the visual language promises.
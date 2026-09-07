# RG25 — Measure boot performance; finish title/save-select/quit flow

## Goal
Address the owner's ROG Ally report that boot/load feels too long and the game lacks a proper front door and exit path.

This item has two linked halves:
1. **remeasure and improve current boot/load performance from evidence**;
2. verify/finish the title/save-select/quit behavior coordinated with EV9.

Do not optimize against an obsolete 48s/68s/117s historical number. Current main has changed repeatedly.

## Coordination with EV9
`20-EV9-title-screen-and-orb-count-mounts.md` owns the visual title/wordmark + orb-count remainder and establishes the title screen as the new boot destination. RG25 must reuse that title/save-select flow rather than creating another one.

If EV9 has landed, inspect and extend it. If it has not, implement shared front-door infrastructure in a way EV9 can skin/mount without replacement.

## Performance workflow — measure first
Use `user://boot_log.txt` and the existing `scripts/boot/boot_log.gd` instrumentation. Capture current Ally-equivalent and/or shipped Windows timings for:
- process launch -> first responsive title screen;
- title -> new-game world ready;
- title -> selected save loaded and player controllable;
- major boot phases already logged (Terrain3D, vegetation, assets, world systems, etc.).

Record cold vs warm behavior if materially different. Do not report editor/headless numbers as ROG numbers without labeling them.

Identify the largest current contributors before optimizing. Prefer removing eager work from the title path and deferring safe world work over micro-optimizing trivial phases.

## Title/load responsiveness
The title screen should become interactive as early as safely possible; it should not need to construct the entire Meadows world merely to show New Game/Load/Quit.

When the player selects a save/new game:
- show clear loading feedback if world construction is not immediate;
- prevent double activation;
- load exactly the selected slot;
- arrive with controls responsive and save position/progression restored per RG7.

Do not fake speed by removing needed content after world entry.

## Quit behavior
Provide clear controller-accessible exit paths:
- **Quit Game** from the title screen;
- while playing, a pause/menu action that can return to title and/or quit game with wording that makes the difference clear.

Protect progress appropriately using existing save semantics; do not silently autosave in new places unless that is already established policy. If unsaved progress could be lost, use a simple confirmation rather than guessing.

On Windows, Quit Game must actually terminate cleanly. Return-to-title must unload/reset world/session state sufficiently that loading another save does not inherit stale transient state.

## Preserve
- existing five-slot save format/API;
- slot 1 autosave semantics and slots 2-5 manual behavior;
- current boot logging;
- no second GameState/save singleton;
- opening flow for New Game;
- controller-first UI.

## Do not
- do not raise arbitrary timeouts and call boot fixed;
- do not remove world features to make one measurement look faster;
- do not perform Meadows construction behind an apparently responsive title in a way that freezes input immediately afterward without feedback;
- do not invent cloud saves/profile accounts.

## Acceptance criteria
1. A current baseline boot/load timing report exists with phase breakdown.
2. Any optimization targets measured dominant costs.
3. Title screen becomes responsive without eagerly instantiating unnecessary Meadows world state.
4. New Game and all valid save slots load correctly.
5. Loading feedback remains responsive during legitimate waits.
6. Pause/menu offers an understandable way to leave play; title offers Quit Game.
7. Return-to-title does not leak previous world's transient state into a subsequent load.
8. Quit exits cleanly on Windows/ROG Ally.
9. Before/after boot/load numbers are recorded on comparable conditions.

## Testing / verification
Run save/load and boot smokes, plus repeated session cycle: launch -> load A -> title -> load B -> title -> new game. Check memory/node duplication. Drive title/menu with real joypad events. Verify exported Windows build, not only editor. If performance changes world initialization, run the relevant terrain/vegetation/spawn smoke tests.

## Definition of done
The game has a proper responsive title/save-select/exit flow, and boot/load performance is improved based on measured current bottlenecks with reproducible before/after evidence.
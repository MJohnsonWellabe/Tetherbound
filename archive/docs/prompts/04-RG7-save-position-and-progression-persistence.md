# RG7 — Save/load must restore exact player transform and one-time progression state

## Goal
Fix the save/load contract so loading a manual save returns the player to the exact place and facing they saved from, and so completed one-time story/world events remain completed after reload.

This is a player-facing blocker. The owner has reproduced all of the following on current builds:

- loading does not return the trainer to the position where the save was made;
- after reloading with a starter creature already owned, Grandpa's opening dialogue/story sequence can run again;
- villagers can offer one-time gifts again;
- starter/creature-grant opportunities can be repeated;
- TM world pickups can visibly reappear and be picked up again after loading, even when duplicate inventory logic prevents a second TM from actually being granted.

Owner design decision: **manual saves restore the exact saved world position AND exact facing direction. Do not redirect the player to a camp, checkpoint, spawn point, safe node, road, village, or approximate location.**

## Read before changing code
Read and follow the current repository rules before implementation:

- `CLAUDE.md`
- `docs/AGENT_WORKFLOW.md`
- `docs/CURRENT_STATE.md`
- `archive/docs/HANDOFF.md`
- relevant save/progression decisions referenced by the code you touch

Inspect current main rather than trusting this prompt's file list if the repo has moved.

## Current repo facts to verify
The current save system is already versioned and persists substantial state. `scripts/save/save_game.gd` currently serializes party, inventory, hotbar, placed buildings, farm plots, death satchels, satiety, map state, progression state, harvested vegetation, and felled vegetation.

However, at the time this prompt was written, the save payload does **not** contain the live player's transform. `autoload/game_state.gd` also explicitly treats transforms as scene-owned rather than autoload-owned, so do not simply dump a permanent `player_position` field into the autoload without understanding the existing save seam.

`autoload/progression_state.gd` already provides a flat persistent flag store and `save_data()` / `load_data()`. It is deliberately a small flag store, not a quest engine. Preserve that design.

Therefore this task has two distinct responsibilities:

1. persist/restore the live player transform through the existing save/load boundary;
2. audit one-time story/pickup producers and consumers so they actually use persistent progression/world state correctly before and after reload.

Do not assume the second problem means progression-state serialization itself is broken. It may instead be missing flag writes, missing flag checks, wrong flag ids, wrong load timing, or world nodes rebuilding before restored state is applied.

## Player-facing behavior
### Exact transform restore
When a player manually saves:

- capture the trainer's exact global position;
- capture the trainer's exact facing/orientation needed to reproduce where the trainer was looking;
- save it in the versioned save format;
- on load, restore that transform after the player node exists and at the correct point in world initialization;
- restore velocity/motion safely so the player does not continue an old fall/run impulse after load;
- do not alter the intended saved facing just to make the location 'safe.'

A save made in open wilderness must reopen in that same wilderness location and orientation.

### One-time progression/world state
Once a one-time event has happened, loading the save must not resurrect the opportunity.

At minimum, audit and verify:

- Grandpa's opening conversation / opening story gate;
- starter selection / starter creature grant;
- one-time villager gifts in the opening Meadows progression;
- one-time TM pickups;
- other Meadows one-shot pickups or reward interactions that are structurally the same and reachable in current content.

The implementation should use the project's existing progression/state conventions rather than hardcoding a special save boolean for every symptom unless the current architecture genuinely requires a different persistent registry.

For a world pickup such as a TM, persistence means more than 'inventory refuses the duplicate.' After reload, a previously consumed one-time pickup should be **gone / inactive / non-interactable**. The player should not see a fake collectible, walk over to it, trigger pickup feedback, and then silently receive nothing.

## Investigation requirements
Before fixing, trace a real save/load cycle end to end:

1. How does the Save tab invoke the save system?
2. What live-node sync hooks run immediately before serialization?
3. How does loading a slot invoke `save_game.gd`?
4. When in scene/world startup does the player node exist?
5. Which current systems already restore world-backed state after `load_slot()` (for example placed buildings/vegetation), and what pattern should transform restoration follow?
6. Where are Grandpa completion, starter grant, villager gifts and TM pickups currently recorded?
7. Are the relevant flags written before a save can occur?
8. Are those flags included in `progression.save_data()` and restored by `progression.load_data()`?
9. Do spawned story/pickup nodes consult restored state when becoming active?
10. Is anything resetting progression after load or replaying opening bootstrap code unconditionally?

Instrument or add targeted diagnostics if needed. Do not guess at the failure point.

## Likely files/systems
Inspect at least these and follow references outward:

- `scripts/save/save_game.gd`
- `autoload/game_state.gd`
- `autoload/progression_state.gd`
- `scripts/ui/tab_save.gd`
- current player/controller script(s) that own the trainer transform
- world/bootstrap code that stands up the Meadows player and restores saved state
- Grandpa/opening sequence scripts/data
- starter picker / starter grant path
- villager gift interaction paths
- TM pickup/world pickup implementation
- existing save/progression tests

The exact fix may touch fewer or more files. Do not change unrelated systems merely because they are nearby.

## Save-format requirements
This is persistent-data schema work, so follow the existing migration discipline in `scripts/save/save_game.gd`.

- Bump the save format version if new persisted fields are introduced.
- Add a migration from the previous current version.
- Old saves that predate player-transform persistence must remain loadable.
- For an old save with no saved transform, use the project's existing normal spawn behavior rather than inventing a fake historical location.
- Do not invalidate existing saves just because RG7 added transform fields.
- Validate malformed transform data defensively, consistent with the file's existing 'bad save must not brick the player' philosophy.

Prefer a compact data representation consistent with current save payload conventions. Do not serialize Node/Transform objects directly into JSON.

## Transform ownership constraint
`autoload/game_state.gd` currently states that transforms belong to scene systems rather than global state. Preserve the architectural intent if possible.

A good solution will likely let the save layer ask the live game/world for the current player transform and let the world/player consume a restored transform at the appropriate lifecycle point, analogous to the existing satiety seam or other live-node sync/restore seams.

Do not create a second competing source of truth for the player's live transform.

## Progression-state constraint
`autoload/progression_state.gd` is intentionally a flat flag store. Preserve that.

Do not turn RG7 into a new quest engine, event scripting language, branching state machine, or giant save-specific story object.

If one-shot events lack persistent ids, add stable ids/flags using current project conventions. The same one-shot rule should be reusable by equivalent Meadows content instead of one bespoke branch per NPC.

## Preserve
Do not regress:

- current party/inventory persistence;
- current placed-building persistence;
- farm persistence;
- map persistence;
- hotbar persistence;
- creature progression persistence;
- harvested/felled vegetation persistence;
- death satchel persistence;
- save migration behavior;
- fresh-game opening sequence for a genuinely new slot;
- ability to obtain each legitimate one-time reward exactly once;
- normal story/dialogue behavior before its completion flag is set.

## Testing — required
Do not close RG7 with only unit tests against a fake game object. Add/strengthen a world-level regression that exercises the actual save/load lifecycle.

### Transform round-trip test
At minimum:

1. start a playable Meadows world;
2. move/position the player somewhere clearly different from the default spawn;
3. rotate the player/camera-facing state to a clearly different heading;
4. save to a test slot through the production save path;
5. move/rotate the player somewhere else (or reconstruct the world if that mirrors real load behavior better);
6. load that slot through the production load path;
7. verify position is restored within only a tiny floating-point tolerance;
8. verify facing is restored within only a tiny angular tolerance;
9. verify the player is controllable after load.

Do not make the test pass by directly assigning the expected transform after calling `load_slot()`.

### Story/one-shot regression
Build a targeted end-to-end persistence test that proves representative one-time state survives a reload. It must cover at least:

- an opening-story completion state (Grandpa or equivalent exact production flag);
- starter acquisition/grant state;
- one one-time NPC gift;
- one TM pickup.

For the TM case, prove both:

- inventory does not gain a duplicate; and
- the consumed world pickup does not reappear as an actionable collectible after reload.

Where practical, use actual interaction/pickup flows rather than setting flags directly. Direct flag tests may supplement but cannot replace the real lifecycle test.

### Migration tests
Add coverage proving a pre-RG7 save version still loads successfully and receives the intended fallback behavior for missing transform data.

## Acceptance criteria
RG7 is done only when all of the following are true:

- Saving at an arbitrary Meadows location and loading returns the trainer to that same location.
- The trainer faces the same direction they faced when saved.
- Normal world controls work immediately after load.
- Grandpa/opening progression that was already completed does not replay after load.
- A starter already acquired cannot be acquired/granted again by replaying opening content.
- One-time villager rewards already received are not offered/granted again.
- A TM already collected remains gone/non-interactable after load.
- Equivalent audited one-shot Meadows content follows the same persistence rule.
- Existing current saves migrate forward rather than being rejected.
- Fresh/new games still play the opening sequence normally.
- Existing save-system regressions remain green.
- New world-level regression tests demonstrate the actual failures the owner reported, not only internal serialization helpers.

## Definition of done
1. Root cause(s) documented in the implementation/commit notes.
2. Exact transform persistence implemented through the existing save/world lifecycle.
3. Save version/migration updated safely if schema changed.
4. One-time opening/NPC/TM state audited and corrected at the proper shared layer(s).
5. Regression coverage reproduces the owner's real reload behavior.
6. Relevant targeted tests and the project's required test suite pass.
7. No design changes beyond this brief are invented.

Do not mark this task complete merely because `progression.save_data()` round-trips in isolation. The player's reported failure is in the live game: after loading, location and consumed story/world opportunities must remain exactly as the saved game says they were.
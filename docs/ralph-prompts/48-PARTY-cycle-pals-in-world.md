# PARTY-CYCLE — Cycle the selected/active pal during exploration without opening a menu

## Owner decision
The player should be able to cycle through their pals directly during normal exploration. Opening the Creatures menu just to select another team member is too much friction.

## Goal
Add controller-first previous/next creature selection during exploration so the player can quickly choose which pal is active/selected while moving through the Meadows.

This is a party-selection convenience, not a sixth-creature/storage system and not a combat switch redesign.

## Inspect first
- `autoload/party.gd`
- current active/summoned creature state
- player/HUD code that summons/recalls or displays party
- current `creature_recall` and any party-cycle InputMap actions
- combat switch-left/right actions and whether they are valid outside combat
- `scripts/ui/playground_hud.gd` party strip
- permanent exploration control legend from RG3
- creature availability logic for fainted/resting creatures
- camera retarget logic when active creature changes

Prefer reusing existing party strip and selection model. Do not make the menu state and world state disagree about which creature is selected.

## Interaction contract
During normal exploration:
- Previous Pal cycles backward through eligible owned creatures.
- Next Pal cycles forward through eligible owned creatures.
- Wrap from last -> first and first -> last.
- The HUD immediately shows which creature is now selected.
- If a creature is already summoned/active and current game design allows swapping it in-world, cycle should cleanly recall/replace it through existing summon logic rather than spawning duplicates.

If the project distinguishes `selected` from `summoned`, preserve that distinction and make the player-visible result clear.

## Eligibility
Skip creatures that cannot currently participate:
- empty slots;
- creatures physically resting in a bed under the Phase -1.7 bed contract;
- any other explicitly unavailable state.

For fainted creatures, inspect current exploration summon rules. If they are normally unsummonable, skip them. Do not invent a new exception.

If only one eligible creature exists, cycling should be a harmless no-op with optional subtle feedback, not an error.

If zero are eligible, communicate that cleanly when the player tries.

## Input mapping
Use InputMap actions and dynamic glyphs. Choose bindings that do not conflict with:
- hotbar/tool cycling;
- combat switch inputs;
- map/inventory/build/menu;
- camera controls.

If combat already uses shoulder buttons for previous/next creature and those actions can safely be context-sensitive, reuse the physical grammar while keeping distinct action names if that makes ownership clearer.

Do not read raw joypad button indices in gameplay code.

## HUD feedback
The exploration HUD's party strip should make cycling obvious:
- selected creature gets a clear highlight/outline;
- unavailable/resting/fainted members should visually communicate status where existing HUD space allows;
- a short name/level cue may appear on change but should not spam the screen.

Update the always-visible exploration control legend from RG3 to include Change/Cycle Pal using actual current glyphs.

## Active-world swap
If a pal is visibly active beside the player:
- cycling to another eligible pal should use existing recall/despawn/summon transitions;
- only one active companion body may remain;
- camera target remains the trainer in ordinary exploration unless existing design says otherwise;
- no combat is started merely by cycling.

Do not teleport a resting pal out of its bed.

## Persistence
Selected active slot may remain transient if current game semantics already treat it that way. Do not expand save format unless needed. The important persistent facts are creature ownership/condition; selected convenience can reasonably reset on load if current project conventions do that.

## Tests
- 5 eligible creatures cycles 1->2->3->4->5->1 and reverse;
- empty slots skipped;
- resting creature skipped;
- fainted behavior matches existing eligibility;
- one eligible creature no-op;
- zero eligible produces correct feedback;
- active companion swap does not duplicate nodes;
- no input response while a menu/dialogue/build/catch mode owns input;
- real controller events through live InputMap.

## Acceptance criteria
1. Player can cycle pals in normal exploration without opening a menu.
2. Selected creature change is obvious on HUD.
3. Cycling wraps predictably.
4. Resting/unavailable creatures cannot be selected for use.
5. Active-world creature swaps do not duplicate or strand bodies.
6. Controls are shown in the exploration legend with dynamic glyphs.
7. Menus/combat/build modes keep their own input ownership and do not accidentally cycle the party.
8. Controller and keyboard equivalents both work.

## Definition of done
Changing the pal you want to use while traveling is a one-second controller action, not a trip through the pause menu.
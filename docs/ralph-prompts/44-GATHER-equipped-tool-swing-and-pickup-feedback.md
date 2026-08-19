# GATHER — Require equipped tool, show the swing, and report resource pickup

## Owner reproductions — 2026-08-18 evening
- Chopping should require the axe actually being out/equipped.
- The player should visibly see the trainer swing the axe.
- Current world prompt tells the player to chop, but pressing the action appears to do nothing.
- Picking up felled wood should visibly report `+X Wood`.

The earlier RG-GATHER landing is therefore not enough acceptance. Reproduce current main before assuming which layer regressed.

## Goal
Make the harvest loop visually and mechanically causal:

**equip axe -> aim at/chop tree -> visible swing -> hit registers during swing -> tree transitions to felled resource -> gather pickup -> concise `+X Wood` feedback.**

The same grammar should apply to stone/pickaxe and other tool-gated harvestables where already designed.

## Inspect first
- player equipment / `equipped_tool`
- `scripts/player/tool_hold.gd`
- player/trainer animation controller and available swing animations
- use-tool InputMap and controller polling
- harvest target query / hit cone / `harvest_logic.gd`
- vegetation harvest-point / felled-resource systems
- interaction prompt arbitration
- world toast/pending-message infrastructure
- inventory add/overflow behavior
- tests from RG2/RG9/RG10/RG22 and current gather smokes

## Tool requirement
A standing tree may only take chop damage from the correct equipped tool.

- Axe not equipped -> no chop action against tree; show a clear short refusal if the player tries through an interaction path.
- Pickaxe not equipped -> same for mineable rock.
- Having the tool in the satchel is not enough. It must be the currently equipped/held tool.
- Do not silently auto-equip on interaction unless existing design explicitly does that.

## Visible swing and hit timing
Pressing Use Tool must trigger the trainer's visible swing animation with the held tool attached correctly.

The harvest hit should occur at a defined animation hit window/event, not immediately on button-down while the visual swing happens later.

Requirements:
- one input -> one swing;
- no harvesting every frame while button held;
- no hit if target leaves the valid hit arc/range before the hit window unless current combat/tool animation architecture intentionally snapshots target at start;
- impact feedback occurs only when the swing actually connects;
- world prompt should not imply `Chop` if the action path cannot currently execute.

If the project lacks a proper axe swing clip but has a generic tool swing, use the existing animation pipeline rather than adding a fake teleport/pop animation.

## Tree -> felled resource transition
Preserve the current two-stage harvesting design:
- standing tree cannot be gathered directly;
- enough axe hits mark/remove the standing source;
- a real felled wood/resource pickup appears;
- the harvested standing source remains permanently harvested according to current save rules;
- collecting the felled resource removes the pending drop and persists that state.

Do not revert to golden glow/orb harvest markers.

## Pickup feedback
When a resource is actually added to inventory, show a brief HUD/world toast such as:
- `+3 Wood`
- `+2 Stone`

Use the existing one-shot world-message/toast infrastructure if appropriate rather than building another notification stack.

The amount shown must equal the amount actually credited after inventory/overflow rules. If some amount cannot enter the satchel and is left/dropped, do not claim it was acquired.

For multiple pickups in quick succession, either stack/aggregate cleanly or queue briefly; do not spam overlapping unreadable labels.

## Prompt correctness
Interaction text should match current state:
- correct tool equipped and valid target -> Chop/Mine or corresponding verb;
- wrong/no tool -> tool-needed guidance or no actionable Chop prompt;
- felled resource -> Gather/Pick Up;
- already harvested -> no stale prompt.

## Controller-first verification
On the ROG path:
1. approach tree with empty hands -> cannot chop;
2. equip axe from hotbar -> axe visible in hand;
3. press use-tool -> visible swing;
4. confirm hit/damage only when swing connects;
5. fell tree;
6. approach wood drop -> gather;
7. see accurate `+X Wood`;
8. switch away from axe -> cannot keep chopping.

Repeat with pickaxe/stone.

## Regression tests
Add production-faithful input coverage where practical:
- no equipped tool rejects harvest;
- wrong tool rejects;
- correct tool use triggers one hit per action edge;
- target outside range is not harvested;
- felled resource state survives save/load;
- pickup credits exact amount and notification uses same amount;
- repeated held input does not multi-hit every frame.

Keep existing lower-level harvest tests but do not use direct `gather()` calls as sole proof of player-facing behavior.

## Acceptance criteria
- Axe must be equipped/visible to chop tree.
- Trainer visibly swings it.
- Swing action actually reaches the harvest target when in valid range/arc.
- Standing tree transitions to felled resource only through chop path.
- Felled wood pickup credits inventory and visibly reports exact amount.
- Wrong/no tool cannot harvest.
- Same contract works for pickaxe/stone.
- Save/load and permanent harvest state remain correct.
- No golden harvest glow returns.

## Definition of done
The resource loop feels causal and understandable without developer knowledge: the player can see the correct tool, see the action, see the world respond, and see exactly what they received.